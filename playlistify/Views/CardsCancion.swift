//
//  CardsCancion.swift
//  Playlistyfy
//
//  Created by Lex Santos on 31/05/25.
//

import SwiftUI
import Kingfisher

struct CardCancion: View {
    let cancion: Cancion
    var incluirBoton: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                KFImage(URL(string: cancion.thumbnailUrl))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 50)
                    .clipped()
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(cancion.titulo)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .font(.title3)
                        .lineLimit(1)

                    Text("Agregado por: \(cancion.usuario)")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                }

                Spacer()

                Text(formatDuration(cancion.duration))
                    .foregroundColor(.white.opacity(0.6))
                    .font(.caption)
                    .fontWeight(.bold)
            }

            /*if incluirBoton {
                Button(action: {
                    // Aquí irá la lógica de reproducción en el futuro
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Reproducir Playlist")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 1, green: 0.2, blue: 0.3))
                    .cornerRadius(10)
                }
            }*/
        }
        .padding()
        .background(Color.white.opacity(0.10))
        .cornerRadius(16)
    }
}

struct CardCancionEnCola: View {
    let cancion: Cancion
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            KFImage(URL(string: cancion.thumbnailUrl))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 58, height: 38)
                .cornerRadius(11)

            VStack(alignment: .leading, spacing: 5) {
                Text(cancion.titulo)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    Text(cancion.usuario)
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.14))
                        .cornerRadius(7)
                }
            }
            Spacer()
            Text(formatDuration(cancion.duration))
                .foregroundColor(.white.opacity(0.92))
                .font(.system(size: 15, weight: .bold))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            // Fondo más sutil, sin stroke fuerte
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.14), value: isPressed)
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
                isPressed = false
            }
        }
    }
}

