// ContentView.swift
// Copy this file into your Xcode iOS project

import SwiftUI

public struct ContentView: View {
    public init() {}
    
    public var body: some View {
        VStack {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundColor(.blue)
            
            Text("NotesApp")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Welcome to your app!")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Created on Ubuntu")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
