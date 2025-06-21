import SwiftUI
import FirebaseAuth

struct MenuBottomSheet: View {
    let nombreUsuario: String
    let rolUsuario: String
    let emailUsuario: String
    let onCambiarNombre: () -> Void
    let onGoogleLogin: () -> Void
    let onEscanearQR: () -> Void
    let onSolicitarCerrarSesionGoogle: () -> Void
    let onSolicitarSalirSala: () -> Void
    

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text(nombreUsuario)
                    .font(.headline)
                    .bold()
                Text("Rol: \(rolUsuario)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if !emailUsuario.isEmpty {
                    Text(emailUsuario)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
            .padding(.top, 12)
            .padding(.horizontal, 20)

            Divider()

            VStack(spacing: 0) {
                Button(action: onCambiarNombre) {
                    Text("Cambiar nombre")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)

                // SOLO muestra el login si NO hay sesión activa
                if emailUsuario.isEmpty && Auth.auth().currentUser == nil {
                    Button(action: onGoogleLogin) {
                        Text("Iniciar sesión con Google")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                } else {
                    if rolUsuario != "Admin" {
                        Button(action: onEscanearQR) {
                            Text("Escanear QR para ser Admin")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                    }
                    Button(action: onSolicitarCerrarSesionGoogle) {
                        Text("Cerrar sesión Google")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                }
            }

            Spacer()
            Divider()

            Button(action: onSolicitarSalirSala) {
                Text("Salir de sala")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
}

