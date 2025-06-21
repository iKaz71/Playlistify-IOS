//
//  QRScanSheet.swift
//  Playlistyfy
//
//  Created by Lex Santos on 16/06/25.
//

import SwiftUI
import CodeScanner 

struct QRScanSheet: View {
    var onFound: (String) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        CodeScannerView(
            codeTypes: [.qr],
            completion: { result in
                switch result {
                case .success(let res):
                    onFound(res.string)
                    dismiss()
                case .failure(let error):
                    print("Fallo escaneo: \(error)")
                    dismiss()
                }
            }
        )
        .edgesIgnoringSafeArea(.all)
    }
}
