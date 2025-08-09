import Foundation
import SwiftUI

// Centralized app constants
struct AppConstants {
    static let maxDurationMinutes: Double = 5.0
}

enum Exercise: String, CaseIterable {
    case singleStrings
    case scalePattern
    case randomNotes
    case noteIntervals
    
    var title: String {
        switch self {
        case .singleStrings:
            return "Single String Notes"
        case .scalePattern:
            return "Scale Pattern"
        case .randomNotes:
            return "Random Notes"
        case .noteIntervals:
            return "Note Intervals"
        }
    }
    
    var description: String {
        switch self {
        case .singleStrings:
            return "Practice random notes on guitar strings"
        case .scalePattern:
            return "Practice random notes from major scale patterns"
        case .randomNotes:
            return "Notes change automatically on each beat"
        case .noteIntervals:
            return "Intervals change automatically on each beat"
        }
    }
}

struct GuitarNote {
    let name: String
    let frequency: Double
    let stringNumber: Int
    let fret: Int
    
    static let allNotes = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]
    
    // All notes including enharmonic equivalents
    static let allNotesWithEnharmonics = [
        "C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"
    ]
    
    // Natural and flat notes only (no sharps)
    static let flatsOnlyNotes = [
        "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"
    ]
    
    // Enharmonic groups for avoiding repetition
    static let enharmonicGroups = [
        ["C#", "Db"],
        ["D#", "Eb"],
        ["F#", "Gb"],
        ["G#", "Ab"],
        ["A#", "Bb"]
    ]
    
    static let openStrings = [
        GuitarNote(name: "E", frequency: 82.41, stringNumber: 6, fret: 0),  // Low E
        GuitarNote(name: "A", frequency: 110.00, stringNumber: 5, fret: 0), // A
        GuitarNote(name: "D", frequency: 146.83, stringNumber: 4, fret: 0), // D
        GuitarNote(name: "G", frequency: 196.00, stringNumber: 3, fret: 0), // G
        GuitarNote(name: "B", frequency: 246.94, stringNumber: 2, fret: 0), // B
        GuitarNote(name: "E", frequency: 329.63, stringNumber: 1, fret: 0)  // High E
    ]
    
    static let majorScale = [
        "C", "D", "E", "F", "G", "A", "B"
    ]
    
    // Musical intervals
    static let intervals = [
    "Minor 2nd",
    "Major 2nd", 
    "Minor 3rd",
    "Major 3rd",
    "Perfect 4th",
    "Tritone",
    "Perfect 5th",
    "Minor 6th",
    "Major 6th",
    "Minor 7th",
    "Major 7th"
    ]
    
    static let shortIntervals = [
    "m2",
    "M2",
    "m3", 
    "M3",
    "P4",
    "TT",
    "P5",
    "m6",
    "M6",
    "m7",
    "M7"
    ]
}

enum NotePattern: CaseIterable {
    case quarter
    case half
    case whole
    
    @ViewBuilder
    var icon: some View {
        switch self {
        case .quarter:
            QuarterNoteIcon()
        case .half:
            HalfNoteIcon()
        case .whole:
            WholeNoteIcon()
        }
    }
    
    var beatsPerChange: Int {
        switch self {
        case .quarter:
            return 1  // Change every beat
        case .half:
            return 2  // Change every 2 beats
        case .whole:
            return 4  // Change every 4 beats
        }
    }
}

class NoteRandomizer: ObservableObject {
    @Published var currentNote: String = "C"
    @Published var notePattern: NotePattern = .quarter
    @AppStorage("useOnlyFlats") var useOnlyFlats: Bool = false
    @AppStorage("useShortIntervals") var useShortIntervals: Bool = false
    private var recentNotes: [String] = []
    private var beatCount = 0
    private let maxRecentNotes = 5
    
    func randomizeNote(for exercise: Exercise) {
        let availableNotes: [String]
        
        switch exercise {
        case .singleStrings:
            availableNotes = useOnlyFlats ? GuitarNote.flatsOnlyNotes : GuitarNote.allNotesWithEnharmonics
        case .scalePattern:
            availableNotes = useOnlyFlats ? GuitarNote.flatsOnlyNotes : GuitarNote.allNotesWithEnharmonics
        case .randomNotes:
            availableNotes = useOnlyFlats ? GuitarNote.flatsOnlyNotes : GuitarNote.allNotesWithEnharmonics
        case .noteIntervals:
            availableNotes = useShortIntervals ? GuitarNote.shortIntervals : GuitarNote.intervals
        }
        
        // Enhanced randomization algorithm
        let newNote = selectRandomNote(from: availableNotes)
        currentNote = newNote
        addToRecentNotes(newNote)
    }
    
    private func selectRandomNote(from availableNotes: [String]) -> String {
        // Create weighted selection to improve variety
        var candidateNotes: [String] = []
        
        // Filter out recently used notes and their enharmonic equivalents
        let filteredNotes = availableNotes.filter { note in
            !isNoteRecentlyUsed(note)
        }
        
        // If we have enough filtered notes, use them
        if filteredNotes.count >= max(3, availableNotes.count / 3) {
            candidateNotes = filteredNotes
        } else {
            // If too many notes are filtered out, use all but the most recent
            candidateNotes = availableNotes.filter { note in
                !recentNotes.suffix(2).contains(note) && !isEnharmonicOfRecent(note, in: Array(recentNotes.suffix(2)))
            }
            
            // Fallback to all notes if still empty
            if candidateNotes.isEmpty {
                candidateNotes = availableNotes
            }
        }
        
        // Weighted selection: prefer notes that haven't been used recently
        var weightedNotes: [String] = []
        
        for note in candidateNotes {
            let timesInRecent = recentNotes.filter { $0 == note || isEnharmonicEquivalent(note, $0) }.count
            let weight = max(1, 4 - timesInRecent) // Higher weight for less recently used notes
            
            for _ in 0..<weight {
                weightedNotes.append(note)
            }
        }
        
        // Select from weighted array
        return weightedNotes.randomElement() ?? availableNotes.randomElement() ?? "C"
    }
    
    private func isEnharmonicOfRecent(_ note: String, in recentList: [String]) -> Bool {
        for recentNote in recentList {
            if isEnharmonicEquivalent(note, recentNote) {
                return true
            }
        }
        return false
    }
    
    private func isEnharmonicEquivalent(_ note1: String, _ note2: String) -> Bool {
        for group in GuitarNote.enharmonicGroups {
            if group.contains(note1) && group.contains(note2) {
                return true
            }
        }
        return false
    }
    
    func onMetronomeBeat(for exercise: Exercise) {
        guard exercise == .randomNotes || exercise == .noteIntervals else { return }
        
        beatCount += 1
        if beatCount >= notePattern.beatsPerChange {
            beatCount = 0
            randomizeNote(for: exercise)
        }
    }
    
    func setNote(_ note: String) {
        currentNote = note
        addToRecentNotes(note)
    }
    
    private func isNoteRecentlyUsed(_ note: String) -> Bool {
        // Check if the note itself is recent
        if recentNotes.contains(note) {
            return true
        }
        
        // Check if any enharmonic equivalent is recent
        for group in GuitarNote.enharmonicGroups {
            if group.contains(note) {
                for enharmonic in group {
                    if recentNotes.contains(enharmonic) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    private func addToRecentNotes(_ note: String) {
        recentNotes.append(note)
        if recentNotes.count > maxRecentNotes {
            recentNotes.removeFirst()
        }
    }
}
