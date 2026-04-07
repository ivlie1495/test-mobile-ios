//
//  SyncState.swift
//  Test Mobile iOS
//
//  Mirrors Android's SyncState sealed class.
//

import Foundation

enum SyncState: Equatable {
    case idle
    case inProgress(done: Int, total: Int)
    case done(synced: Int, total: Int)
}
