import SwiftUI

struct CambiarNombreSheet: View {
    @Binding var nombreUsuario: String
    @Environment(\.dismiss) var dismiss
    @State private var nuevoNombre: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Cambiar nombre")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            .padding([.horizontal, .top], 18)
            .padding(.bottom, 12)

            Divider().background(Color.white.opacity(0.13))

            // Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre de usuario")
                    .font(.caption)
                    .foregroundColor(.gray)
                TextField("Nuevo nombre", text: $nuevoNombre)
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemFill))
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            // Botón Guardar
            Button(action: {
                if !nuevoNombre.trimmingCharacters(in: .whitespaces).isEmpty {
                    nombreUsuario = nuevoNombre.trimmingCharacters(in: .whitespaces)
                    UserDefaults.standard.set(nombreUsuario, forKey: "nombreUsuario")
                    dismiss()
                }
            }) {
                Text("Guardar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.top, 20)
                    .padding(.horizontal, 18)
            }

            // Botón Cancelar
            Button("Cancelar", role: .cancel) {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .background(Color(.secondarySystemBackground).opacity(0.99))
        .presentationDetents([.medium])
    }
}

