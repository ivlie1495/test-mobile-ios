//
//  AuthRepository.swift
//  Test Mobile iOS
//
//  Mirrors Android's AuthRepositoryImpl.kt:
//  - Login → save token → fetch profile → cache user name+email
//  - Indonesian error messages matching Android's parseError()
//  - User cache stored in UserDefaults (equivalent to Android's SharedPreferences)
//

import Foundation

private struct LoginRequest: Encodable {
    let email: String
    let password: String
}

private struct LoginResponse: Decodable {
    let token: String
}

final class AuthRepository {
    static let shared = AuthRepository()
    private init() {}

    private let userDefaultsNameKey  = "cached_name"
    private let userDefaultsEmailKey = "cached_email"

    // MARK: - Login (mirrors AuthRepositoryImpl.login)

    /// Logs in, saves token, fetches profile, caches user. Returns cached User on success.
    func login(email: String, password: String) async throws -> UserProfile {
        do {
            let body = LoginRequest(email: email, password: password)
            let loginResp: LoginResponse = try await APIClient.shared.request(
                url: APIEndpoints.login,
                method: "POST",
                body: body,
                requiresAuth: false
            )
            KeychainService.shared.saveToken(loginResp.token)

            // Fetch and cache profile immediately after login — same as Android
            let profile = try await fetchProfile()
            cacheUser(name: profile.fullName, email: profile.email)
            return profile
        } catch {
            throw parseError(error)
        }
    }

    // MARK: - Profile

    func fetchProfile() async throws -> UserProfile {
        do {
            return try await APIClient.shared.request(url: APIEndpoints.profile)
        } catch {
            throw parseError(error)
        }
    }

    // MARK: - Cached user (mirrors getCurrentUser)

    func getCachedUser() -> UserProfile? {
        guard let name = UserDefaults.standard.string(forKey: userDefaultsNameKey),
              let email = UserDefaults.standard.string(forKey: userDefaultsEmailKey)
        else { return nil }
        return UserProfile(id: "", fullName: name, email: email)
    }

    // MARK: - Auth state

    func isLoggedIn() -> Bool {
        KeychainService.shared.getToken() != nil
    }

    // MARK: - Logout (mirrors AuthRepositoryImpl.logout)

    func logout() {
        KeychainService.shared.deleteToken()
        UserDefaults.standard.removeObject(forKey: userDefaultsNameKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsEmailKey)
    }

    // MARK: - Private helpers

    private func cacheUser(name: String, email: String) {
        UserDefaults.standard.set(name,  forKey: userDefaultsNameKey)
        UserDefaults.standard.set(email, forKey: userDefaultsEmailKey)
    }

    /// Mirrors Android's parseError() — returns Indonesian error messages.
    private func parseError(_ error: Error) -> Error {
        if let apiError = error as? APIError {
            switch apiError {
            case .httpError(let code, let body):
                // Try to parse JSON error body
                if let data = body.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let msg = (json["error"] as? String)?.isEmpty == false
                        ? json["error"] as! String
                        : (json["message"] as? String ?? "Error \(code)")
                    return NSError(domain: "", code: code, userInfo: [NSLocalizedDescriptionKey: msg])
                }
                return NSError(domain: "", code: code, userInfo: [NSLocalizedDescriptionKey: "Error \(code)"])
            case .noToken:
                return NSError(domain: "", code: 401, userInfo: [NSLocalizedDescriptionKey: "Sesi tidak ditemukan, silakan login kembali."])
            default:
                break
            }
        }
        let msg = error.localizedDescription
        if msg.contains("Could not connect") || msg.contains("hostname") || msg.contains("offline") {
            return NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Tidak ada koneksi internet"])
        }
        if msg.contains("timed out") || msg.contains("timeout") {
            return NSError(domain: "", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Koneksi timeout, coba lagi"])
        }
        return error
    }
}
