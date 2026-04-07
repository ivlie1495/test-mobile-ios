//
//  UserProfile.swift
//  Test Mobile iOS
//

import Foundation

struct UserProfile: Codable, Equatable {
    let id: String
    let fullName: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
    }
}
