//
//  LoginViewModel.swift
//  Test Mobile iOS
//
//  Mirrors Android's LoginViewModel — uses AuthUiState equivalent.
//

import Foundation

// Mirrors Android's AuthUiState sealed class
enum AuthUiState: Equatable {
    case idle
    case loading
    case success(UserProfile)
    case error(String)

    static func == (lhs: AuthUiState, rhs: AuthUiState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading): return true
        case (.error(let a), .error(let b)):        return a == b
        default:                                    return false
        }
    }
}

@Observable
final class LoginViewModel {
    var email: String    = ""
    var password: String = ""
    var uiState: AuthUiState = .idle

    var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }

    func login() async {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            uiState = .error("Email dan password wajib diisi")
            return
        }
        uiState = .loading
        do {
            let profile = try await AuthRepository.shared.login(
                email: email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            uiState = .success(profile)
        } catch {
            uiState = .error(error.localizedDescription)
        }
    }
}
