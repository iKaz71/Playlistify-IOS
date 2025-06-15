import SwiftUI

struct MenuBottomSheet: View {
    let nombreUsuario: String
    let rolUsuario: String
    let emailUsuario: String
    let onCambiarNombre: () -> Void
    let onEscanearQR: () -> Void
    let onCerrarSesion: () -> Void
    let onSalirSala: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Fondo transparente: ya no .ultraThinMaterial
            Color.clear.ignoresSafeArea()
            
            VStack {
                Spacer()
                // SOLO el menú tiene fondo y bordes redondeados
                VStack(spacing: 0) {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(nombreUsuario)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Text(rolUsuario)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                            if !emailUsuario.isEmpty {
                                Text(emailUsuario)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: 200, alignment: .leading)
                            }
                        }
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundColor(Color(.systemGray3))
                                .padding(10)
                        }
                    }
                    .padding(.top, 18)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    
                    Divider()
                        .background(Color.white.opacity(0.15))
                    
                    // Acciones
                    VStack(spacing: 0) {
                        ActionRow(
                            icon: "person",
                            title: "Cambiar nombre",
                            color: Color.white,
                            action: onCambiarNombre
                        )
                        ActionRow(
                            icon: "qrcode.viewfinder",
                            title: "Escanear QR para ser Admin",
                            color: Color.white,
                            action: onEscanearQR
                        )
                        ActionRow(
                            icon: "arrow.right.square",
                            title: "Cerrar sesión Google",
                            color: Color.white,
                            action: onCerrarSesion
                        )
                        Divider()
                            .background(Color.white.opacity(0.12))
                            .padding(.horizontal, 6)
                        ActionRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Salir de sala",
                            color: Color.red,
                            action: onSalirSala
                        )
                    }
                    .background(Color.clear)
                    .padding(.vertical, 4)
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 0)
                .padding(.bottom, 18)
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct ActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundColor(color == .red ? .red : .white)
                    .frame(width: 32, alignment: .center)
                Text(title)
                    .font(.system(size: 19, weight: color == .red ? .semibold : .regular))
                    .foregroundColor(color)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 13)
            .background(Color(.clear))
        }
    }
}

