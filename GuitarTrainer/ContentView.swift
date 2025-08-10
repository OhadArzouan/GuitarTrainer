//
//  ContentView.swift
//  GuitarTrainer
//
//  Created by Ohad on 09/08/2025.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("sessionTempo") private var sessionTempo: Double = 120
    @AppStorage("defaultTempo") private var defaultTempo: Double = 120
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Title
                Text("Guitar Trainer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // App Description
                Text("Practice guitar exercises to become a real musician")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Main Menu Buttons
                VStack(spacing: 20) {
                    NavigationLink(destination: ExerciseSelectionView()) {
                        MenuButton(title: "Practice Exercises", icon: "music.note")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        // Initialize session tempo from default when entering exercise selection
                        sessionTempo = defaultTempo
                    })
                    
                    NavigationLink(destination: MetronomeView()) {
                        MenuButton(title: "Metronome", icon: "metronome")
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        // Initialize session tempo from default when entering metronome
                        sessionTempo = defaultTempo
                    })
                    
                    NavigationLink(destination: SettingsView()) {
                        MenuButton(title: "Settings", icon: "gear")
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}

struct MenuButton: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
    }
}

#Preview {
    ContentView()
}
