import SwiftUI

struct SettingsView: View {
    @AppStorage("defaultTempo") private var defaultTempo: Double = 120
    @AppStorage("defaultDuration") private var defaultDuration: Double = 5
    @AppStorage("metronomeSound") private var metronomeSound: String = "electronic"
    @AppStorage("useOnlyFlats") private var useOnlyFlats: Bool = false
    @AppStorage("useShortIntervals") private var useShortIntervals: Bool = false
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        Form {
            Section("Default Exercise Settings") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Default Tempo")
                        Spacer()
                        Text("\(Int(defaultTempo)) BPM")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $defaultTempo, in: 60...200, step: 1)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Default Duration")
                        Spacer()
                        Text("\(Int(defaultDuration)) min")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $defaultDuration, in: 1...AppConstants.maxDurationMinutes, step: 1)
                }
            }
            
            Section("Note Settings") {
                Toggle("Use Only Flats", isOn: $useOnlyFlats)
                    .font(.headline)
                
                Text("When enabled, only natural notes (C, D, E, F, G, A, B) and flat notes (Db, Eb, Gb, Ab, Bb) will be used. No sharp notes.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Interval Settings") {
                Toggle("Use Short Interval Names", isOn: $useShortIntervals)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("**Full names:** Minor 2nd, Major 2nd, Perfect 4th, etc. (smaller text)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("**Short names:** m2, M2, P4, etc. (normal text size)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Metronome Settings") {
                VStack(alignment: .leading, spacing: 15) {
                    // Volume Control
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Volume")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(audioManager.metronomeVolume * 100))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $audioManager.metronomeVolume, in: 0.1...1.0, step: 0.1)
                            .accentColor(.blue)
                    }
                    
                    // Sound Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Metronome Sound")
                            .font(.headline)
                        
                        Picker("Metronome Sound", selection: $metronomeSound) {
                            Text("Electronic Beep").tag("electronic")
                            Text("Digital Click").tag("digital")
                            Text("Soft Tick").tag("soft")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: metronomeSound) {
                            // Update audio manager's sound and play 3 preview ticks
                            audioManager.updateMetronomeSound(metronomeSound)
                        }
                    }
                }
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("linimfin")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
