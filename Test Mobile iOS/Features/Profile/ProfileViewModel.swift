//
//  ProfileViewModel.swift
//  Test Mobile iOS
//
//  Mirrors Android's ProfileViewModel — loads from cache first, fetches remote as fallback.
//

import Foundation

@Observable
final class ProfileViewModel {
    var profile: UserProfile?
    var showLogoutConfirm: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    func loadProfile() async {
        // Load cached user immediately (mirrors Android's getCurrentUser())
        profile = AuthRepository.shared.getCachedUser()

        // Then try to refresh from network
        isLoading = true
        defer { isLoading = false }
        do {
            let remote = try await AuthRepository.shared.fetchProfile()
            profile = remote
        } catch {
            // Keep cached value — non-fatal if refresh fails
            if profile == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    // mirrors AuthRepositoryImpl.logout()
    func logout(coordinator: AppCoordinator) {
        AuthRepository.shared.logout()
        coordinator.userName = nil
        coordinator.route = .login
    }
}
