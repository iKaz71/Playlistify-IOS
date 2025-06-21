//
//  playlistifyApp.swift
//  playlistify
//
//  Created by Lex Santos on 20/06/25.
//
import SwiftUI
import FirebaseCore

@main
struct playlistifyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var showSplash = true
    @State private var splashOpacity = 1.0

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()

                if showSplash {
                    SplashView()
                        .opacity(splashOpacity)
                        .zIndex(1)
                        .onAppear {
                            // Muestra el splash durante 2.5 segundos, luego fade out en 0.6 segundos
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation(.easeOut(duration: 0.6)) {
                                    splashOpacity = 0
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
    }
}

