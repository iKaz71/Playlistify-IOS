//
//  SplashView.swift
//  playlistify
//
//  Created by Lex Santos on 20/06/25.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var glow: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 32) {
                Image("LogoGrande")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(
                        color: Color.purple.opacity(glow ? 0.7 : 0.3),
                        radius: glow ? 28 : 12, x: 0, y: 0
                    )
                    .onAppear {
                        // Bounce in
                        withAnimation(.easeOut(duration: 0.6)) {
                            logoScale = 1.15
                            logoOpacity = 1.0
                        }
                        withAnimation(.easeOut(duration: 0.3).delay(0.6)) {
                            logoScale = 1.0
                        }
                        // Glow animado
                        withAnimation(
                            Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)
                                .delay(0.7)
                        ) {
                            glow = true
                        }
                        // Aparece el texto
                        withAnimation(.easeIn(duration: 0.6).delay(0.5)) {
                            textOpacity = 1.0
                        }
                    }

                Text("Playlistify")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [Color.white, Color.purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .opacity(textOpacity)
                    .shadow(color: .purple.opacity(0.25), radius: 12, x: 0, y: 3)
            }
        }
    }
}


