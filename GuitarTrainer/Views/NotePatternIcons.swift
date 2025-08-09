import SwiftUI

// MARK: - Quarter Note Icon
struct QuarterNoteIcon: View {
    var body: some View {
        ZStack {
            // Note head (filled circle)
            Circle()
                .fill(Color.primary)
                .frame(width: 12, height: 8)
                .scaleEffect(x: 1.2, y: 0.8) // Slightly oval shape
                .rotationEffect(.degrees(-20))
                .offset(x: -2, y: 8)
            
            // Stem
            Rectangle()
                .fill(Color.primary)
                .frame(width: 1.5, height: 20)
                .offset(x: 6, y: -2)
        }
        .frame(width: 20, height: 24)
    }
}

// MARK: - Half Note Icon
struct HalfNoteIcon: View {
    var body: some View {
        ZStack {
            // Note head (hollow circle with thick border)
            Circle()
                .stroke(Color.primary, lineWidth: 2)
                .frame(width: 12, height: 8)
                .scaleEffect(x: 1.2, y: 0.8) // Slightly oval shape
                .rotationEffect(.degrees(-20))
                .offset(x: -2, y: 8)
            
            // Stem
            Rectangle()
                .fill(Color.primary)
                .frame(width: 1.5, height: 20)
                .offset(x: 6, y: -2)
        }
        .frame(width: 20, height: 24)
    }
}

// MARK: - Whole Note Icon
struct WholeNoteIcon: View {
    var body: some View {
        ZStack {
            // Outer oval
            Ellipse()
                .stroke(Color.primary, lineWidth: 2)
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(-20))
            
            // Inner oval (creates the hollow effect)
            Ellipse()
                .fill(Color(UIColor.systemBackground))
                .frame(width: 8, height: 4)
                .rotationEffect(.degrees(-20))
        }
        .frame(width: 20, height: 24)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 30) {
            VStack {
                QuarterNoteIcon()
                Text("Quarter")
                    .font(.caption)
            }
            
            VStack {
                HalfNoteIcon()
                Text("Half")
                    .font(.caption)
            }
            
            VStack {
                WholeNoteIcon()
                Text("Whole")
                    .font(.caption)
            }
        }
        .padding()
        
        // Test different sizes
        HStack(spacing: 20) {
            QuarterNoteIcon()
                .scaleEffect(0.5)
            QuarterNoteIcon()
            QuarterNoteIcon()
                .scaleEffect(1.5)
        }
    }
    .padding()
}
