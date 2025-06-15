import SwiftUI

struct CambiarNombreDialog: View {
    @Binding var isPresented: Bool
    @Binding var nombreUsuario: String
    @State private var nuevoNombre: String = ""

    var body: some View {
        if isPresented {
            ZStack {
                // Fondo oscurecido que cierra el overlay al tocar fuera
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }

                VStack(spacing: 20) {
                    Text("Personaliza tu nombre")
                        .font(.title2).bold()
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Nombre de usuario")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        TextField("Tu nombre...", text: $nuevoNombre)
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor(.white)
                            .background(Color(white: 0.18).cornerRadius(8))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button("Cancelar") {
                            isPresented = false
                        }
                        .foregroundColor(.blue)

                        Spacer()

                        Button("Guardar") {
                            let trimmed = nuevoNombre.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                nombreUsuario = trimmed
                                UserDefaults.standard.set(trimmed, forKey: "nombreUsuario")
                            }
                            isPresented = false
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
                .frame(width: 340)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .shadow(radius: 24)
            }
            .transition(.opacity)
            .animation(.easeInOut, value: isPresented)
        }
    }
}

