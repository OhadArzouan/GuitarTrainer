import SwiftUI

struct MetronomeView: View {
    @StateObject private var audioManager = AudioManager()
    @AppStorage("sessionTempo") private var tempo: Double = 120
    @AppStorage("defaultTempo") private var defaultTempo: Double = 120
    @State private var isPlaying = false
    @State private var tapTimes: [Date] = []
    
    var body: some View {
        VStack(spacing: 40) {
            // Title
            Text("Metronome")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            // Visual metronome indicator
            Circle()
                .fill(audioManager.metronomeFlash ? (audioManager.currentBeat == 1 && audioManager.timeSignature != .justBeat ? Color.green : Color.red) : Color.gray.opacity(0.3))
                .onChange(of: audioManager.metronomeFlash) {
                    if audioManager.metronomeFlash {
                        print("🔴 Visual: currentBeat=\(audioManager.currentBeat), timeSignature=\(audioManager.timeSignature.rawValue), isGreen=\(audioManager.currentBeat == 1 && audioManager.timeSignature != .justBeat)")
                    }
                }
                .frame(width: 100, height: 100)
                .animation(.easeInOut(duration: 0.1), value: audioManager.metronomeFlash)
                .overlay(
                    VStack {
                        Text("\(Int(tempo))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(audioManager.metronomeFlash ? .white : .primary)
                        
                        if audioManager.timeSignature != .justBeat {
                            Text("\(audioManager.currentBeat)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(audioManager.metronomeFlash ? .white : .secondary)
                        }
                    }
                )
            

            
            // Time Signature Selection
            VStack(spacing: 10) {
                HStack {
                    Text("Time Signature")
                        .font(.headline)
                    Spacer()
                }
                
                Picker("Time Signature", selection: $audioManager.timeSignature) {
                    ForEach(AudioManager.TimeSignature.allCases, id: \.self) { signature in
                        Text(signature.rawValue).tag(signature)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Tempo Slider
            VStack(spacing: 10) {
                HStack {
                    Text("Tempo")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(tempo)) BPM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $tempo, in: 60...200, step: 1)
                    .accentColor(.blue)
                    .onChange(of: tempo) {
                        if isPlaying {
                            // Restart metronome with new tempo
                            audioManager.stopMetronome()
                            audioManager.startMetronome(tempo: Int(tempo))
                        }
                    }
            }
            
            // Volume Control
            VStack(spacing: 10) {
                HStack {
                    Text("Volume")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(audioManager.metronomeVolume * 100))%")
                        .foregroundColor(.secondary)
                }
                Slider(value: $audioManager.metronomeVolume, in: 0.1...1.0, step: 0.05)
                    .accentColor(.blue)
            }
            .padding(.horizontal)
            
            // Tap Tempo Button
            Button(action: tapTempo) {
                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.title)
                    Text("Tap Tempo")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(width: 150, height: 80)
                .background(Color.orange)
                .cornerRadius(16)
            }
            
            Spacer()
            
            // Play/Stop Button
            Button(action: toggleMetronome) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(isPlaying ? .red : .green)
            }
            
            Spacer()
        }
        .padding()
        // .navigationTitle("Metronome")
        .navigationBarTitleDisplayMode(.inline)

        .onDisappear {
            audioManager.stopMetronome()
        }
    }
    
    private func toggleMetronome() {
        if isPlaying {
            audioManager.stopMetronome()
            isPlaying = false
        } else {
            audioManager.startMetronome(tempo: Int(tempo))
            isPlaying = true
        }
    }
    
    private func tapTempo() {
        let now = Date()
        tapTimes.append(now)
        
        // Keep only the last 8 taps for rolling average
        if tapTimes.count > 8 {
            tapTimes.removeFirst()
        }
        
        // Need at least 4 taps to calculate tempo
        guard tapTimes.count >= 4 else { return }
        
        // Calculate intervals between consecutive taps (use last 4 taps)
        let recentTaps = Array(tapTimes.suffix(4))
        var intervals: [TimeInterval] = []
        for i in 1..<recentTaps.count {
            intervals.append(recentTaps[i].timeIntervalSince(recentTaps[i-1]))
        }
        
        // Calculate average interval from the last 4 taps
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        
        // Convert to BPM (60 seconds / interval)
        let calculatedTempo = 60.0 / averageInterval
        
        // Clamp to reasonable range and round to nearest integer
        let clampedTempo = max(60, min(200, calculatedTempo))
        let roundedTempo = round(clampedTempo)
        
        // Update tempo continuously
        tempo = roundedTempo
        
        // If metronome is playing, restart with new tempo
        if isPlaying {
            audioManager.stopMetronome()
            audioManager.startMetronome(tempo: Int(tempo))
        }
        
        // Continue calculating - don't reset tap times
        // This allows continuous tempo updates as user keeps tapping
    }
}

#Preview {
    NavigationView {
        MetronomeView()
    }
}
