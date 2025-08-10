import SwiftUI

struct ExerciseSelectionView: View {
    @State private var selectedExercise: Exercise = .singleStrings
    @AppStorage("sessionTempo") private var tempo: Double = 120
    @AppStorage("defaultTempo") private var defaultTempo: Double = 120
    @AppStorage("defaultDuration") private var duration: Double = 5
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Select Exercise")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            // Exercise Selection
            VStack(alignment: .leading, spacing: 15) {
                // Text("Exercise Type")
                    // .font(.headline)
                
                ForEach(Exercise.allCases, id: \.self) { exercise in
                    ExerciseRow(
                        exercise: exercise,
                        isSelected: selectedExercise == exercise
                    ) {
                        selectedExercise = exercise
                    }
                }
            }
            .padding(.horizontal)
            
            // Tempo Control
            VStack(alignment: .leading, spacing: 10) {
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
                
                Slider(value: $tempo, in: 60...200, step: 1)
                    .accentColor(.blue)
            }
            .padding(.horizontal)
            
            // Duration Control
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Duration")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(duration)) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $duration, in: 1...AppConstants.maxDurationMinutes, step: 1)
                    .accentColor(.blue)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Start Button
            NavigationLink(destination: ExerciseView(
                exercise: selectedExercise,
                duration: Int(duration)
            )) {
                Text("Start Exercise")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        // .navigationTitle("Setup")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(exercise.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        ExerciseSelectionView()
    }
}
