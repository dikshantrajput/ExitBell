import AppKit
import SwiftUI
import Combine

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private let timerManager = TimerManager()
    private let soundPlayer = SoundPlayer()

    override init() {
        print("[StatusBarController] init start")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        print("[StatusBarController] statusItem created")
        popover = NSPopover()
        print("[StatusBarController] popover created")
        super.init()
        setupStatusButton()
        setupPopover()
        observeTimer()
        print("[StatusBarController] init complete")
    }

    private func setupStatusButton() {
        print("[StatusBarController] setupStatusButton")
        if let button = statusItem.button {
            button.image = menubarIcon(named: "bell")
            button.action = #selector(togglePopover)
            button.target = self
            print("[StatusBarController] status button configured")
        } else {
            print("[StatusBarController] WARNING: statusItem.button is nil")
        }
    }

    private func menubarIcon(named symbolName: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular, scale: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        image?.isTemplate = true  // lets macOS tint it correctly in light/dark/highlight
        return image
    }

    private func setupPopover() {
        print("[StatusBarController] setupPopover")
        popover.contentSize = NSSize(width: 280, height: 10) // auto-sized by content
        popover.behavior = .transient
        let hc = NSHostingController(
            rootView: PopoverView(timerManager: timerManager, soundPlayer: soundPlayer)
        )
        hc.view.wantsLayer = true
        // Let vibrancy show through — remove the default white fill
        hc.view.layer?.backgroundColor = .clear
        popover.contentViewController = hc
        print("[StatusBarController] popover configured")
    }

    private func observeTimer() {
        print("[StatusBarController] observeTimer")
        timerManager.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                print("[StatusBarController] timer state changed: \(state)")
                self?.updateStatusButton(for: state)
            }
            .store(in: &cancellables)

        timerManager.onFire = { [weak self] in
            print("[StatusBarController] timer fired — playing sound")
            self?.handleFire()
        }
    }

    private func updateStatusButton(for state: TimerManager.State) {
        guard let button = statusItem.button else {
            print("[StatusBarController] updateStatusButton: button is nil")
            return
        }
        // Reset attributed title so layout is always driven by the same path
        button.attributedTitle = NSAttributedString()
        switch state {
        case .idle:
            button.image = menubarIcon(named: "bell")
            button.imagePosition = .imageOnly
        case .armed(let remaining):
            button.image = nil
            let mins = Int(remaining) / 60
            let secs = Int(remaining) % 60
            let str = String(format: "%d:%02d", mins, secs)
            // Vertically centered monospaced countdown
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                .baselineOffset: 0,
            ]
            button.attributedTitle = NSAttributedString(string: str, attributes: attrs)
            button.imagePosition = .noImage
        case .fired:
            button.image = menubarIcon(named: "bell.fill")
            button.imagePosition = .imageOnly
        }
    }

    private func handleFire() {
        soundPlayer.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.timerManager.reset()
        }
    }

    @objc private func togglePopover() {
        print("[StatusBarController] togglePopover — isShown: \(popover.isShown)")
        if popover.isShown {
            closePopover()
        } else {
            openPopover()
        }
    }

    private func openPopover() {
        guard let button = statusItem.button else {
            print("[StatusBarController] openPopover: button is nil")
            return
        }
        print("[StatusBarController] opening popover")
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func closePopover() {
        print("[StatusBarController] closing popover")
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
