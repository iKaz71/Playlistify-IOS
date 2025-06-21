//
//  ConfirmarSalirSalaSheet.swift
//  Playlistyfy
//
//  Created by Lex Santos on 19/06/25.
//

import SwiftUI

struct ConfirmarSalirSalaSheet: View {
    let onConfirmar: () -> Void
    let onCancelar: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("¿Seguro que quieres salir de la sala actual?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            HStack(spacing: 24) {
                Button("Cancelar", action: onCancelar)
                    .foregroundColor(.secondary)
                Button("Salir", action: onConfirmar)
                    .foregroundColor(.red)
                    .bold()
            }
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(24)
    }
}
