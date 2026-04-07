//
//  APIEndpoints.swift
//  Test Mobile iOS
//

import Foundation

enum APIEndpoints {
    static let baseURL = "https://api-test.partaiperindo.com/api/v1"

    static var login:    URL { URL(string: "\(baseURL)/login")!    }
    static var register: URL { URL(string: "\(baseURL)/register")! }
    static var profile:  URL { URL(string: "\(baseURL)/profile")!  }
    static var members:  URL { URL(string: "\(baseURL)/member")!   }
}
