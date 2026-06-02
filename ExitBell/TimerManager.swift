import Foundation
import Combine

class TimerManager: ObservableObject {
    enum State: Equatable {
        case idle
        case armed(remaining: TimeInterval)
        case fired
    }

    @Published var state: State = .idle

    var onFire: (() -> Void)?

    private var timer: AnyCancellable?
    private var remaining: TimeInterval = 0

    init() {
        print("[TimerManager] init")
    }

    var isArmed: Bool {
        if case .armed = state { return true }
        return false
    }

    func arm(duration: TimeInterval) {
        print("[TimerManager] arming for \(duration)s")
        remaining = duration
        state = .armed(remaining: remaining)

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func cancel() {
        print("[TimerManager] cancelled")
        timer?.cancel()
        timer = nil
        state = .idle
    }

    func reset() {
        print("[TimerManager] reset")
        timer?.cancel()
        timer = nil
        state = .idle
    }

    private func tick() {
        remaining -= 1
        if remaining <= 0 {
            print("[TimerManager] fired!")
            timer?.cancel()
            timer = nil
            state = .fired
            onFire?()
        } else {
            state = .armed(remaining: remaining)
        }
    }
}
