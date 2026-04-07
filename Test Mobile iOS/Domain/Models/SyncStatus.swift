//
//  SyncStatus.swift
//  Test Mobile iOS
//
//  Matches Android's statusForm values: "Draft" / "Synced"
//

import Foundation

enum SyncStatus: String, Codable {
    case draft  = "Draft"
    case synced = "Synced"
}
