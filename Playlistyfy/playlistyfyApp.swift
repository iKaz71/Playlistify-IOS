//
//  playlistyfyApp.swift
//  playlistyfy
//
//  Created by Lex Santos on 04/05/25.
//

import SwiftUI
import FirebaseCore


@main
struct playlistyfyApp: App {
    
    init() {
            FirebaseApp.configure()
        }
    
    var body: some Scene {
        WindowGroup {
            WelcomeScreen()
        }
    }
}
