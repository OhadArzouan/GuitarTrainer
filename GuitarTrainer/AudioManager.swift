import AVFoundation
import AudioToolbox
import SwiftUI

class AudioManager: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine!
    private var metronomePlayer: AVAudioPlayerNode!
    private var metronomeBuffers: [String: AVAudioPCMBuffer] = [:]
    private var downbeatBuffers: [String: AVAudioPCMBuffer] = [:]
    
    @Published var metronomeFlash = false
    @AppStorage("metronomeVolume") var metronomeVolume: Double = 0.7
    @Published var currentBeat = 1
    @Published var isDownbeat = false
    
    enum TimeSignature: String, CaseIterable {
        case justBeat = "1/1"
        case twoFour = "2/4"
        case threeFour = "3/4"
        case fourFour = "4/4"
        case sixEight = "6/8"
        
        var beatsPerMeasure: Int {
            switch self {
            case .justBeat: return 1
            case .twoFour: return 2
            case .threeFour: return 3
            case .fourFour: return 4
            case .sixEight: return 6
            }
        }
    }
    
    @Published var timeSignature: TimeSignature = .justBeat
    
    // Metronome properties
    private var metronomeTimer: Timer?
    @AppStorage("metronomeSound") private var metronomeSound: String = "electronic"
    
    override init() {
        super.init()
        setupAudio()
        setupMetronome()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // Use playback only since we removed note detection
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func setupMetronome() {
        metronomePlayer = AVAudioPlayerNode()
        audioEngine.attach(metronomePlayer)
        
        // Use stereo format to match the main mixer
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        audioEngine.connect(metronomePlayer, to: audioEngine.mainMixerNode, format: format)
        
        // Create different metronome sounds
        createMetronomeSounds()
        
        // Start the audio engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
        

    }
    
    private func createMetronomeSounds() {
        let sampleRate = Float(44100)
        let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 2)!
        
        // Electronic Beep (800Hz, 100ms)
        metronomeBuffers["electronic"] = createSoundBuffer(
            format: format,
            frequency: 800,
            duration: 0.1,
            waveform: .sine
        )
        

        
        // Digital Click (1200Hz, 50ms)
        metronomeBuffers["digital"] = createSoundBuffer(
            format: format,
            frequency: 1200,
            duration: 0.05,
            waveform: .sine
        )
        
        // Soft Tick (600Hz, 30ms)
        metronomeBuffers["soft"] = createSoundBuffer(
            format: format,
            frequency: 600,
            duration: 0.03,
            waveform: .sine
        )
        
        // Create downbeat versions (higher pitch for beat 1)
        downbeatBuffers["electronic"] = createSoundBuffer(
            format: format,
            frequency: 1000, // Higher than 800Hz
            duration: 0.1,
            waveform: .sine
        )
        
        downbeatBuffers["digital"] = createSoundBuffer(
            format: format,
            frequency: 1500, // Higher than 1200Hz
            duration: 0.05,
            waveform: .square
        )
        
        downbeatBuffers["soft"] = createSoundBuffer(
            format: format,
            frequency: 750, // Higher than 600Hz
            duration: 0.03,
            waveform: .sine
        )
    }
    
    private func createSoundBuffer(format: AVAudioFormat, frequency: Float, duration: Float, waveform: Waveform) -> AVAudioPCMBuffer? {
        let sampleRate = Float(format.sampleRate)
        let frameCount = Int(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)) else {
            return nil
        }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        let leftChannelData = buffer.floatChannelData![0]
        let rightChannelData = buffer.floatChannelData![1]
        
        for i in 0..<frameCount {
            let sample: Float
            let t = Float(i) / sampleRate
            
            switch waveform {
            case .sine:
                sample = sin(2.0 * Float.pi * frequency * t) * 0.4
            case .square:
                sample = sin(2.0 * Float.pi * frequency * t) > 0 ? 0.4 : -0.4
            }
            
            // Apply fade out to avoid clicks
            let fadeOut = max(0, 1.0 - Float(i) / Float(frameCount))
            let finalSample = sample * fadeOut
            
            leftChannelData[i] = finalSample
            rightChannelData[i] = finalSample
        }
        
        return buffer
    }
    

    
    enum Waveform {
        case sine
        case square
    }
    

    
    // MARK: - Metronome Control
    
    func startMetronome(tempo: Int, exercise: Exercise? = nil, noteRandomizer: NoteRandomizer? = nil) {
        stopMetronome()
        
        // Set time signature for Note Intervals and Random Notes exercises based on note pattern
        if (exercise == .noteIntervals || exercise == .randomNotes), let noteRandomizer = noteRandomizer {
            switch noteRandomizer.notePattern {
            case .quarter:
                timeSignature = .fourFour
            case .half:
                timeSignature = .twoFour
            case .whole:
                timeSignature = .fourFour
            }
        }
        
        // Start with beat 0, so first tick becomes beat 1
        currentBeat = 0
        let interval = 60.0 / Double(tempo)
        
        metronomeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.playTick()
            
            // Handle Random Notes and Note Intervals exercises
            if let exercise = exercise, let noteRandomizer = noteRandomizer {
                DispatchQueue.main.async {
                    noteRandomizer.onMetronomeBeat(for: exercise, currentBeat: self.currentBeat)
                }
            }
        }
    }
    
    func stopMetronome() {
        metronomeTimer?.invalidate()
        metronomeTimer = nil
    }
    
    private func playTick() {
        if metronomePlayer.isPlaying {
            metronomePlayer.stop()
        }
        
        // Increment beat counter FIRST, so we play the correct beat
        currentBeat += 1
        if currentBeat > timeSignature.beatsPerMeasure {
            currentBeat = 1
        }
        
        // Debug: Print current beat and timing info
        print("🎵 playTick: currentBeat=\(currentBeat), timeSignature=\(timeSignature.rawValue)")
        
        // Determine if this is a downbeat and select appropriate buffer
        let isCurrentlyDownbeat = (currentBeat == 1) && (timeSignature != .justBeat)
        let bufferToPlay: AVAudioPCMBuffer?
        
        print("🎵 isCurrentlyDownbeat=\(isCurrentlyDownbeat)")
        
        if isCurrentlyDownbeat {
            bufferToPlay = downbeatBuffers[metronomeSound] ?? metronomeBuffers[metronomeSound]
            print("🎵 Playing DOWNBEAT sound")
        } else {
            bufferToPlay = metronomeBuffers[metronomeSound]
            print("🎵 Playing normal sound")
        }
        
        if let buffer = bufferToPlay {
            metronomePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            metronomePlayer.volume = Float(metronomeVolume)
            metronomePlayer.play()
        }
        
        DispatchQueue.main.async {
            self.metronomeFlash = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.metronomeFlash = false
            }
        }
    }    

    func updateMetronomeSound(_ newSound: String) {
        // Stop any currently playing preview ticks first
        metronomePlayer.stop()
        
        metronomeSound = newSound
        setupMetronome()
        
        // Small delay to ensure previous sound stops before playing new preview
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.playPreviewTicks()
        }
    }
    
    private func playPreviewTicks() {
        // Play 3 preview ticks when metronome sound changes
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.6) {
                self.playTick()
            }
        }
    }
    
}
