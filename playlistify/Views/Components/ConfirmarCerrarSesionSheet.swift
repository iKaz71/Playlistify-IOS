//
//  ConfirmarCerrarSesionSheet.swift
//  Playlistyfy
//
//  Created by Lex Santos on 19/06/25.
//

import SwiftUI

struct ConfirmarCerrarSesionSheet: View {
    let onConfirmar: () -> Void
    let onCancelar: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("¿Seguro que quieres cerrar la sesión de Google?")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            HStack(spacing: 24) {
                Button("Cancelar", action: onCancelar)
                    .foregroundColor(.secondary)
                Button("Cerrar sesión", action: onConfirmar)
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
