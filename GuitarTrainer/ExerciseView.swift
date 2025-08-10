import SwiftUI

struct ExerciseView: View {
    let exercise: Exercise
    let initialTempo: Int
    let duration: Int
    
    @StateObject private var audioManager = AudioManager()
    @StateObject private var noteRandomizer = NoteRandomizer()
    @State private var timeRemaining: Int
    @AppStorage("sessionTempo") private var tempo: Double = 120
    @AppStorage("defaultTempo") private var defaultTempo: Double = 120
    @AppStorage("useOnlyFlats") private var useOnlyFlats: Bool = false
    @State private var isActive = false
    @State private var timer: Timer?
    @State private var showNoteDropdown = false
    @State private var showPatternSelection = false
    
    init(exercise: Exercise, duration: Int) {
        self.exercise = exercise
        self.initialTempo = 120 // Will be set from defaultTempo on appear
        self.duration = duration
        self._timeRemaining = State(initialValue: duration * 60) // Convert to seconds
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Text(exercise.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Show note type information for Single String, Scale Pattern, and Random Notes exercises
                if exercise == .singleStrings || exercise == .scalePattern || exercise == .randomNotes {
                    Text(useOnlyFlats ? "Using natural and flats only" : "Using natural, flats and sharps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 10) {
                    HStack {
                        Text("Tempo")
                            .font(.headline)
                        Spacer()
                        Button("Reset") {
                            tempo = defaultTempo
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        Spacer()
                        Text("\(Int(tempo)) BPM")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Tempo Slider
                    Slider(value: $tempo, in: 60...200, step: 1)
                        .accentColor(.blue)
                        .onChange(of: tempo) {
                            if isActive {
                                // Restart metronome with new tempo
                                audioManager.stopMetronome()
                                audioManager.startMetronome(tempo: Int(tempo), exercise: exercise, noteRandomizer: noteRandomizer)
                            }
                        }
                    
                    // Volume Control
                    HStack {
                        Text("Volume: \(Int(audioManager.metronomeVolume * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Slider(value: $audioManager.metronomeVolume, in: 0.1...1.0, step: 0.05)
                        .accentColor(.blue)
                }
            }
            
            // Timer Display
            Text(timeString(from: timeRemaining))
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(timeRemaining <= 60 ? .red : .primary)
            
            // Current Note Display
            VStack(spacing: 15) {
                if exercise == .noteIntervals || exercise == .randomNotes {
                    // Split display for Note Intervals and Random Notes exercises
                    HStack(spacing: 20) {
                        // Current section
                        VStack(spacing: 10) {
                            Text("Current")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showNoteDropdown.toggle()
                            }) {
                                Text(noteRandomizer.currentNote)
                                    .font(.system(size: getFontSize() * 0.8, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Next section
                        VStack(spacing: 10) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text(noteRandomizer.nextNote.isEmpty ? "—" : noteRandomizer.nextNote)
                                .font(.system(size: getFontSize() * 0.8, weight: .bold, design: .rounded))
                                .foregroundColor(noteRandomizer.nextNote.isEmpty ? .secondary : .primary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                } else {
                    // Original single display for other exercises
                    Text("Practice This Note:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Clickable note that opens dropdown
                    Button(action: {
                        showNoteDropdown.toggle()
                    }) {
                        Text(noteRandomizer.currentNote)
                            .font(.system(size: getFontSize(), weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(15)
                    }
                }
                
                // Note selection sheet (common for both layouts)
                if showNoteDropdown {
                    EmptyView()
                        .sheet(isPresented: $showNoteDropdown) {
                            NoteSelectionSheet(
                                exercise: exercise,
                                noteRandomizer: noteRandomizer,
                                isPresented: $showNoteDropdown
                            )
                        }
                }
                
                // Pattern selection for Random Notes and Note Intervals exercises
                if exercise == .randomNotes || exercise == .noteIntervals {
                    Button(action: {
                        showPatternSelection.toggle()
                    }) {
                        HStack(spacing: 10) {
                            Text("Pattern:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            noteRandomizer.notePattern.icon
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $showPatternSelection) {
                        PatternSelectionSheet(
                            noteRandomizer: noteRandomizer,
                            isPresented: $showPatternSelection,
                            exercise: exercise,
                            audioManager: audioManager,
                            isActive: isActive,
                            tempo: tempo
                        )
                    }
                }
                
                // Random button for Single String Notes and Scale Pattern exercises
                if exercise == .singleStrings || exercise == .scalePattern {
                    Button("Random Note") {
                        noteRandomizer.randomizeNote(for: exercise)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 10)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
            
            Spacer()
            
            // Control Button
            Button(action: toggleExercise) {
                Image(systemName: isActive ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(isActive ? .red : .green)
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Randomize initial note
            noteRandomizer.randomizeNote(for: exercise)
        }
        .onDisappear {
            stopExercise()
        }
    }
    
    private var noteDescription: String {
        switch exercise {
        case .singleStrings:
            return useOnlyFlats ? "Natural and Flats Only" : "All Notes (Sharps & Flats)"
        case .scalePattern:
            return useOnlyFlats ? "Natural and Flats Only" : "All Notes (Sharps & Flats)"
        case .randomNotes:
            return "Auto-changing Notes"
        case .noteIntervals:
            return "Auto-changing Intervals"
        }
    }
    
    private func toggleExercise() {
        if isActive {
            stopExercise()
        } else {
            startExercise()
        }
    }
    
    private func getFontSize() -> CGFloat {
        // For Note Intervals exercise, check if using short intervals
        if exercise == .noteIntervals {
            return noteRandomizer.useShortIntervals ? 72 : 36 // 50% smaller for full names
        }
        return 72 // Default size for other exercises
    }
    
    private func startExercise() {
        isActive = true
        audioManager.startMetronome(tempo: Int(tempo), exercise: exercise, noteRandomizer: noteRandomizer)
        
        // Start countdown timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopExercise()
            }
        }
    }
    
    private func pauseExercise() {
        isActive = false
        audioManager.stopMetronome()
        timer?.invalidate()
    }
    
    private func stopExercise() {
        isActive = false
        audioManager.stopMetronome()
        timer?.invalidate()
        timeRemaining = duration * 60
    }
    

    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Note Selection Sheet
struct NoteSelectionSheet: View {
    let exercise: Exercise
    let noteRandomizer: NoteRandomizer
    @Binding var isPresented: Bool
    @AppStorage("useOnlyFlats") private var useOnlyFlats: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Note")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                    ForEach(availableNotes, id: \.self) { note in
                        Button(action: {
                            noteRandomizer.setNote(note)
                            isPresented = false
                        }) {
                            Text(note)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(width: 60, height: 60)
                                .background(note == noteRandomizer.currentNote ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(note == noteRandomizer.currentNote ? .white : .primary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private var availableNotes: [String] {
        switch exercise {
        case .singleStrings:
            return useOnlyFlats ? GuitarNote.flatsOnlyNotes : GuitarNote.allNotesWithEnharmonics
        case .scalePattern:
            return useOnlyFlats ? GuitarNote.flatsOnlyNotes : GuitarNote.allNotesWithEnharmonics
        case .randomNotes:
            return useOnlyFlats ? GuitarNote.flatsOnlyNotes : GuitarNote.allNotesWithEnharmonics
        case .noteIntervals:
            return GuitarNote.intervals
        }
    }
}

// MARK: - Pattern Selection Sheet
struct PatternSelectionSheet: View {
    let noteRandomizer: NoteRandomizer
    @Binding var isPresented: Bool
    let exercise: Exercise
    let audioManager: AudioManager
    let isActive: Bool
    let tempo: Double
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Note Change Pattern")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Choose how often the note changes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    ForEach(availablePatterns, id: \.self) { pattern in
                        Button(action: {
                            noteRandomizer.notePattern = pattern
                            
                            // If exercise is running, restart metronome with new pattern
                            if isActive {
                                audioManager.stopMetronome()
                                audioManager.startMetronome(tempo: Int(tempo), exercise: exercise, noteRandomizer: noteRandomizer)
                            }
                            
                            isPresented = false
                        }) {
                            HStack {
                                pattern.icon
                                    .foregroundColor(.primary)
                                
                                VStack(alignment: .leading) {
                                    Text(patternDescription(pattern))
                                        .font(.headline)
                                    Text("Every \(pattern.beatsPerChange) beat\(pattern.beatsPerChange > 1 ? "s" : "")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if pattern == noteRandomizer.notePattern {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(pattern == noteRandomizer.notePattern ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                isPresented = false
            })
        }
    }
    
    private var availablePatterns: [NotePattern] {
        if exercise == .noteIntervals || exercise == .randomNotes {
            return [.half, .whole] // Only half and whole notes for Note Intervals and Random Notes
        }
        return NotePattern.allCases // All patterns for other exercises
    }
    
    private func patternDescription(_ pattern: NotePattern) -> String {
        switch pattern {
        case .quarter:
            return "Quarter Note"
        case .half:
            return "Half Note"
        case .whole:
            return "Whole Note"
        }
    }
}

#Preview {
    NavigationView {
        ExerciseView(exercise: .singleStrings, duration: 5)
    }
}
