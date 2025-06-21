//
//  playlistifyApp.swift
//  playlistify
//
//  Created by Lex Santos on 20/06/25.
//
import SwiftUI
import FirebaseCore

@main
struct playlistyfyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
