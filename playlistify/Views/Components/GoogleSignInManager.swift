import Foundation
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import FirebaseCore
import UIKit

class GoogleSignInManager: ObservableObject {
    @Published var user: GIDGoogleUser?
    @Published var isSignedIn: Bool = false
    @Published var errorMessage: String?
    
    init() {
        if let googleUser = GIDSignIn.sharedInstance.currentUser {
            self.user = googleUser
            self.isSignedIn = true
        } else if let firebaseUser = Auth.auth().currentUser {
            
            self.isSignedIn = true
            
            print("FirebaseAuth session persists: \(firebaseUser.uid) \(firebaseUser.email ?? "")")
        }
    }

    
    func signIn() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("ERROR: No se encontró clientID. Revisa GoogleService-Info.plist y FirebaseApp.configure().")
            self.errorMessage = "No clientID encontrado."
            return
        }

        let config = GIDConfiguration(clientID: clientID)

        guard let presentingViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("ERROR: No se pudo obtener el ViewController activo.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("Google Sign-In error: \(error.localizedDescription)")
                return
            }

            guard let user = result?.user else {
                print("ERROR: No se obtuvo usuario.")
                return
            }

            self.user = user
            self.isSignedIn = true
            print("GoogleSignInManager: sesión iniciada para \(user.profile?.email ?? "sin email")")


            guard let idToken = user.idToken?.tokenString else { return }
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    print("Firebase Auth error: \(error.localizedDescription)")
                }
            }
        }
    }

    func procesarCodigoAdmin(qr: String, nombreUsuario: String)
 {
        guard let usuario = self.user else { return }
        let sessionId = qr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sessionId.isEmpty else { return }
        
        guard let url = URL(string: "https://playlistify-api-production.up.railway.app/session/\(sessionId)/user") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

     let body: [String: Any] = [
         "uid": usuario.userID ?? "",
         "nombre": nombreUsuario,
         "dispositivo": "ios",
         "rol": "admin"
     ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error haciendo admin:", error)
                return
            }
            if let data = data,
               let resp = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Respuesta admin:", resp)
            }
        }.resume()
    }

    // --- Cerrar sesión Google y Firebase ---
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
        DispatchQueue.main.async {
            self.user = nil
            self.isSignedIn = false
            self.errorMessage = nil
            self.objectWillChange.send()
            print("🚪 [GoogleSignInManager] Sesión cerrada correctamente.")
        }
    }


}

