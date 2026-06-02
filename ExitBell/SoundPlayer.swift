import AppKit
import AVFoundation

class SoundPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    enum Sound: String, CaseIterable, Identifiable {
        case doorbell    = "doorbell"
        case dogBark     = "dog_bark"
        case phoneRing   = "phone_ring"
        case knock       = "knock"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .doorbell:  return "Doorbell"
            case .dogBark:   return "Dog Bark"
            case .phoneRing: return "Ring"
            case .knock:     return "Knock"
            }
        }
    }

    @Published var isPlaying: Bool = false

    private var player: AVAudioPlayer?
    var selectedSound: Sound = .doorbell

    func play(sound: Sound = .doorbell) {
        stop()
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "aiff") else {
            NSSound(named: "Ping")?.play()
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 1.0
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            NSSound(named: "Ping")?.play()
        }
    }

    func play() {
        play(sound: selectedSound)
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    // AVAudioPlayerDelegate — fired when playback finishes naturally
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { self.isPlaying = false }
    }
}
