//
//  ColaListView.swift
//  Playlistyfy
//
//  Created by Lex Santos on 16/06/25.
//

import SwiftUI

struct ColaListView: View {
    let enCola: [(String, Cancion)]
    let fondoOscuro: Color
    @Binding var pushKeyAEliminar: String?
    @Binding var cancionAEliminar: Cancion?
    @Binding var pushKeyAPlayNext: String?
    @Binding var cancionAPlayNext: Cancion?

    var onEliminar: (_ pushKey: String) -> Void
    var onPlayNext: (_ pushKey: String) -> Void

    var body: some View {
        List {
            ForEach(enCola.indices, id: \.self) { index in
                let (pushKey, c) = enCola[index]
                CardCancionEnCola(cancion: c)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pushKeyAEliminar = pushKey
                            cancionAEliminar = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                cancionAEliminar = c
                            }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if index > 0 {
                            Button {
                                pushKeyAPlayNext = pushKey
                                cancionAPlayNext = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    cancionAPlayNext = c
                                }
                            } label: {
                                Label("Siguiente", systemImage: "chevron.up.2")
                            }
                            .tint(Color.yellow.opacity(0.85))
                        }
                    }
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .frame(maxHeight: 420)
        .background(fondoOscuro)
        .cornerRadius(28)
    }
}
