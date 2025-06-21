import SwiftUI

struct QRScannerDialog: View {
    @ObservedObject var googleSignInManager: GoogleSignInManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Escanear QR para iniciar sesión")
                .font(.headline)
            
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 200, height: 200)
                .overlay(Text("QR Scanner Aquí"))
            
            Button("Cerrar") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding()
    }
}

