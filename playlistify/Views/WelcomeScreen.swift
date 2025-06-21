import SwiftUI

struct WelcomeScreen: View {
    @ObservedObject var googleSignInManager: GoogleSignInManager
    let onEntrarSala: (String) -> Void

    @FocusState private var focusedField: Int?
    @State private var codeDigits = ["", "", "", ""]
    @State private var showError = false
    @State private var isLoading = false

    var code: String { codeDigits.joined() }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 28/255, green: 28/255, blue: 30/255),
                         Color(red: 142/255, green: 45/255, blue: 226/255)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 40)
                        .foregroundColor(.white)
                    Text("Playlistify")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                Text("Bienvenido/a a Playlistify")
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Disfruta tu música en equipo.")
                    .foregroundColor(.white.opacity(0.9))
                Text("Ingresa el código de tu sala activa:")
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 20)

                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("", text: $codeDigits[index])
                            .frame(width: 50, height: 60)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: index)
                            .onChange(of: codeDigits[index]) { newValue in
                                if newValue.count > 1 { codeDigits[index] = String(newValue.prefix(1)) }
                                if newValue.count == 1 && index < 3 { focusedField = index + 1 }
                                if code.count == 4 { focusedField = nil }
                            }
                    }
                }
                if showError {
                    Text("Código inválido o sala no disponible.")
                        .foregroundColor(.red).font(.caption)
                }
                Button(action: {
                    isLoading = true
                    showError = false
                    PlaylistifyAPI.shared.verificarCodigo(codigo: code) { result in
                        DispatchQueue.main.async {
                            isLoading = false
                            if let id = result {
                                onEntrarSala(id)
                            } else {
                                showError = true
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("Unirse a la sala").fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 62/255, green: 166/255, blue: 255/255))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(code.count != 4)
                .padding(.horizontal)

                Spacer()
                Text("© 2025 Playlistify")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
    }
}

