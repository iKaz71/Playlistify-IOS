//
//  BusquedaYT.swift
//  Playlistyfy
//
//  Created by Lex Santos on 19/06/25.
//

import SwiftUI
import Kingfisher

struct BusquedaYT: View {
    @Binding var query: String
    @Binding var resultados: [YouTubeVideoItem]
    @Binding var isAdding: Bool
    @Binding var mostrarBuscador: Bool
    @FocusState var isFocused: Bool

    let rojoVivo: Color
    let fondoOscuro: Color
    let sessionId: String
    let agregarCancion: (YouTubeVideoItem, String, @escaping () -> Void) -> Void
    let buscarCanciones: (String, @escaping ([YouTubeVideoItem]) -> Void) -> Void

    var body: some View {
        ZStack {
            fondoOscuro.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Buscar en YouTube")
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                        .padding(.horizontal)
                    HStack {
                        TextField("", text: $query)
                            .padding(.leading, 12)
                            .padding(.vertical, 10)
                            .foregroundColor(.white)
                            .focused($isFocused)
                            .onSubmit {
                                ocultarTeclado()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    buscarCanciones(query) { lista in
                                        resultados = lista
                                    }
                                }
                            }
                        Button(action: {
                            ocultarTeclado()
                            buscarCanciones(query) { lista in
                                resultados = lista
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(rojoVivo)
                                .padding(.trailing, 12)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(rojoVivo, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    if resultados.isEmpty {
                        Text("Realiza la búsqueda para ver resultados")
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(resultados) { cancion in
                                HStack(spacing: 12) {
                                    KFImage(URL(string: cancion.thumbnailUrl))
                                        .resizable()
                                        .frame(width: 80, height: 50)
                                        .cornerRadius(8)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(cancion.titulo.htmlDecoded)
                                            .foregroundColor(.white)
                                            .fontWeight(.semibold)
                                            .lineLimit(2)
                                        Text("Duración: \(formatDuration(cancion.duration))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        isAdding = true
                                        agregarCancion(cancion, sessionId) {
                                            resultados.removeAll()
                                            isAdding = false
                                            mostrarBuscador = false
                                        }
                                    }) {
                                        Image(systemName: "plus")
                                            .foregroundColor(rojoVivo)
                                            .font(.title2)
                                    }
                                    .disabled(isAdding)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                    Spacer(minLength: 12)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .presentationDetents([.medium, .fraction(0.9)])
        .onDisappear {
            query = ""
            resultados.removeAll()
        }
    }
}
