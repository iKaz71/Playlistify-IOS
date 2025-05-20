//
//  FormatUtils.swift
//  Playlistyfy
//
//  Created by Lex Santos on 19/05/25.
//

import Foundation

func formatDuration(_ iso: String) -> String {
    let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: iso, range: NSRange(iso.startIndex..., in: iso)) else {
        return "--:--"
    }

    let h = match.range(at: 1).location != NSNotFound ? Int((iso as NSString).substring(with: match.range(at: 1))) ?? 0 : 0
    let m = match.range(at: 2).location != NSNotFound ? Int((iso as NSString).substring(with: match.range(at: 2))) ?? 0 : 0
    let s = match.range(at: 3).location != NSNotFound ? Int((iso as NSString).substring(with: match.range(at: 3))) ?? 0 : 0

    let totalMinutes = h * 60 + m
    return String(format: "%d:%02d", totalMinutes, s)
}

