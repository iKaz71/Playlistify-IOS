// SalaScreenHelpers.swift
// Playlistyfy

import Foundation
import FirebaseDatabase
import UIKit
import FirebaseAuth

// --- Firebase helpers ---

func obtenerCodigoDeSesion(sessionId: String, completion: @escaping (String?) -> Void) {
    let ref = Database.database().reference()
    ref.child("sessions").child(sessionId).child("code").observeSingleEvent(of: .value) { snapshot in
        let codigo = snapshot.value as? String
        completion(codigo)
    }
}

// --- Helpers para la cola ---

func obtenerEnCola(
    ordenCanciones: [String],
    cancionesDict: [String: Cancion],
    cancionActual: Cancion?
) -> [(String, Cancion)] {
    ordenCanciones.compactMap { pushKey in
        guard let c = cancionesDict[pushKey] else { return nil }
        if cancionActual == nil || c.videoId != cancionActual?.videoId {
            return (pushKey, c)
        } else {
            return nil
        }
    }
}

// --- Búsqueda YouTube ---
func buscarCanciones(query: String, completion: @escaping ([YouTubeVideoItem]) -> Void) {
    let consulta = query.trimmingCharacters(in: .whitespaces)
    guard !consulta.isEmpty else { completion([]); return }
    YouTubeApi.shared.buscarVideos(query: consulta) { lista in
        DispatchQueue.main.async { completion(lista) }
    }
}

// --- Agregar canción a sala ---
func agregarCancion(
    cancion: YouTubeVideoItem,
    sessionId: String,
    onComplete: (() -> Void)? = nil
) {
    let nombrePersonalizado = UserDefaults.standard.string(forKey: "nombreUsuario") ?? "iOS"
    
    let uid = Auth.auth().currentUser?.uid ?? "sin-uid"
    

    let nueva = Cancion(
        videoId: cancion.id,
        pushKey: nil,
        titulo: cancion.titulo.htmlDecoded,
        thumbnailUrl: cancion.thumbnailUrl,
        usuario: nombrePersonalizado, 
        duration: cancion.duration
    )
    PlaylistifyAPI.shared.agregarCancion(sessionId: sessionId, cancion: nueva, uid: uid)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
        onComplete?()
    }
}


// --- Duración ---

func formatDuration(_ iso: String) -> String {
    let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: iso, range: NSRange(iso.startIndex..., in: iso)) else {
        return "--:--"
    }
    let h = match.range(at: 1).location != NSNotFound ? Int((iso as NSString).substring(with: match.range(at: 1))) ?? 0 : 0
    let m = match.range(at: 2).location != NSNotFound ? Int((iso as NSString).substring(with: match.range(at: 2))) ?? 0 : 0
    let s = match.range(at: 3).location != NSNotFound ? Int((iso as NSString).substring(with: match.range(at: 3))) ?? 0 : 0

    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    } else {
        return String(format: "%d:%02d", m, s)
    }
}


// --- Teclado ---
func ocultarTeclado() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// --- Nombre hawaiano ---
let nombresHawaianos = [
    "Kaleo", "Noelani", "Makoa", "Leilani", "Keanu", "Nalani", "Ailani", "Kainoa",
    "Iolana", "Makani", "Moana", "Lani", "Koa", "Mahina", "Hoku", "Anela", "Malu", "Keola"
]

func generarNombreHawaianoUnico() -> String {
    let nombre = nombresHawaianos.randomElement() ?? "Makai"
    let numeros = Int.random(in: 1000...9999)
    return "\(nombre)\(numeros)"
}

