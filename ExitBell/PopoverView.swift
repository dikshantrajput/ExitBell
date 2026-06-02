import SwiftUI
import ServiceManagement

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = .menu
        v.blendingMode = .behindWindow
        v.state = .active
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct PopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var soundPlayer: SoundPlayer

    @AppStorage("selectedDuration") private var selectedDuration: Double = 5 * 60
    @AppStorage("customMinutes")    private var customMinutes: Int = 5
    @AppStorage("selectedSoundRaw") private var selectedSoundRaw: String = SoundPlayer.Sound.doorbell.rawValue
    @AppStorage("launchAtLogin")    private var launchAtLogin: Bool = false

    private let presets: [(label: String, seconds: Double)] = [
        ("2 min", 2 * 60),
        ("5 min", 5 * 60),
        ("10 min", 10 * 60),
    ]

    private var selectedSound: SoundPlayer.Sound {
        SoundPlayer.Sound(rawValue: selectedSoundRaw) ?? .doorbell
    }

    private var countdownString: String {
        guard case .armed(let r) = timerManager.state else { return "" }
        return String(format: "%d:%02d", Int(r) / 60, Int(r) % 60)
    }

    private let hPad: CGFloat = 16
    private let vPad: CGFloat = 10

    var body: some View {
        ZStack {
            VisualEffectBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider()
                durationSection
                Divider()
                soundSection
                Divider()
                armSection
                if soundPlayer.isPlaying {
                    Divider()
                    stopSection
                }
                Divider()
                footer
            }
        }
        .frame(width: 280)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { soundPlayer.selectedSound = selectedSound }
        .onChange(of: selectedSoundRaw) { _ in soundPlayer.selectedSound = selectedSound }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: timerManager.isArmed ? "bell.badge.fill" : "bell.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(timerManager.isArmed ? Color.accentColor : .primary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text("Exit Bell")
                    .font(.system(size: 13, weight: .semibold))
                Group {
                    if timerManager.isArmed {
                        Text("Firing in \(countdownString)")
                            .foregroundStyle(Color.accentColor)
                            .contentTransition(.numericText())
                            .animation(.default, value: countdownString)
                    } else {
                        Text("Ready")
                            .foregroundStyle(.tertiary)
                    }
                }
                .font(.system(size: 11).monospacedDigit())
            }
            Spacer()
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
    }

    // MARK: - Duration

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionHeader("Duration")

            HStack(spacing: 6) {
                ForEach(presets, id: \.seconds) { p in
                    let on = selectedDuration == p.seconds
                    Button {
                        selectedDuration = p.seconds
                        customMinutes = Int(p.seconds) / 60
                    } label: {
                        Text(p.label)
                            .font(.system(size: 12, weight: on ? .semibold : .regular))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(ChipButtonStyle(selected: on))
                }
            }

            HStack {
                Text("Custom")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Stepper(value: $customMinutes, in: 1...30) {
                    Text("\(customMinutes) min")
                        .font(.system(size: 12).monospacedDigit())
                }
                .controlSize(.small)
                .onChange(of: customMinutes) { newVal in
                    selectedDuration = Double(newVal) * 60
                }
            }
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
    }

    // MARK: - Sound (tab-style)

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            sectionHeader("Sound")

            HStack(spacing: 4) {
                ForEach(SoundPlayer.Sound.allCases) { sound in
                    let selected = selectedSoundRaw == sound.rawValue
                    Button {
                        selectedSoundRaw = sound.rawValue
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: soundIcon(for: sound))
                                .font(.system(size: 12, weight: .medium))
                            Text(sound.displayName)
                                .font(.system(size: 11, weight: selected ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(selected
                                      ? Color(nsColor: .controlAccentColor)
                                      : Color(nsColor: .controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
                        )
                        .foregroundStyle(selected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
    }

    private func soundIcon(for sound: SoundPlayer.Sound) -> String {
        switch sound {
        case .doorbell:  return "door.left.hand.open"
        case .dogBark:   return "pawprint"
        case .phoneRing: return "phone"
        case .knock:     return "hand.raised"
        }
    }

    // MARK: - Arm

    private var armSection: some View {
        Button {
            if timerManager.isArmed {
                timerManager.cancel()
            } else {
                soundPlayer.selectedSound = selectedSound
                timerManager.arm(duration: selectedDuration)
            }
        } label: {
            Label(
                timerManager.isArmed ? "Cancel" : "Arm Timer",
                systemImage: timerManager.isArmed ? "xmark.circle" : "bell.badge"
            )
            .frame(maxWidth: .infinity)
            .font(.system(size: 13, weight: .medium))
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .tint(timerManager.isArmed ? .orange : .accentColor)
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
    }

    // MARK: - Stop

    private var stopSection: some View {
        Button {
            soundPlayer.stop()
        } label: {
            Label("Stop Sound", systemImage: "stop.circle")
                .frame(maxWidth: .infinity)
                .font(.system(size: 13, weight: .medium))
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Toggle("Launch at login", isOn: $launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.system(size: 12))
                .onChange(of: launchAtLogin) { newVal in setLaunchAtLogin(newVal) }
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
    }

    private func setLaunchAtLogin(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            try? enable ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
        }
    }
}

// MARK: - Chip button (duration presets)

struct ChipButtonStyle: ButtonStyle {
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(selected
                          ? Color(nsColor: .controlAccentColor)
                          : Color(nsColor: .controlBackgroundColor))
            )
            .foregroundStyle(selected ? Color.white : Color.primary)
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
