//
//  ContentView.swift
//  GuitarTrainer
//
//  Created by Ohad on 09/08/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Title
                Text("Guitar Trainer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // App Description
                Text("Practice guitar exercises with real-time feedback")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Main Menu Buttons
                VStack(spacing: 20) {
                    NavigationLink(destination: ExerciseSelectionView()) {
                        MenuButton(title: "Start Exercise", icon: "play.circle.fill")
                    }
                    
                    NavigationLink(destination: MetronomeView()) {
                        MenuButton(title: "Metronome", icon: "metronome")
                    }
                    
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
