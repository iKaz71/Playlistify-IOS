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
            // Gradiente oscuro-morado
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 14/255, green: 14/255, blue: 18/255), location: 0.0),
                    .init(color: Color(red: 14/255, green: 14/255, blue: 18/255), location: 0.6),
                    .init(color: Color(red: 115/255, green: 50/255, blue: 200/255), location: 1.0)
                ]),
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 32) {
                // Logo y texto principal
                HStack(spacing: 14) {
                    Image("LogoGrande")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 2)
                    Text("Playlistify")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.purple.opacity(0.75)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 4)

                Text("Bienvenido/a a Playlistify")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Disfruta tu música en equipo.")
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Text("Ingresa el código de tu sala activa:")
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.top, 12)

                HStack(spacing: 14) {
                    ForEach(0..<4, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 54, height: 64)
                            TextField("", text: $codeDigits[index])
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 54, height: 64)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .focused($focusedField, equals: index)
                                .onChange(of: codeDigits[index]) { newValue in
                                    if newValue.count > 1 { codeDigits[index] = String(newValue.prefix(1)) }
                                    if newValue.count == 1 && index < 3 { focusedField = index + 1 }
                                    if code.count == 4 { focusedField = nil }
                                }
                        }
                    }
                }
                .padding(.bottom, showError ? 4 : 18)

                if showError {
                    Text("Código inválido o sala no disponible.")
                        .foregroundColor(.red).font(.caption)
                        .transition(.opacity)
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
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Image(systemName: "lock.fill")
                        }
                        Text("Unirse a la sala").fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 62/255, green: 166/255, blue: 255/255),
                                     Color.purple.opacity(0.95)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(code.count != 4 || isLoading)
                .padding(.horizontal, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 28)
            .padding(.top, 80) 
            VStack {
                Spacer()
                Text("© 2025 Playlistify")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

