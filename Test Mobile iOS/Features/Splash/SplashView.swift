//
//  SplashView.swift
//  Test Mobile iOS
//
//  Mirrors Android's SplashActivity — 1.5s delay then route based on isLoggedIn().
//

import SwiftUI

struct SplashView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            Color(hex: "#3D5A99").ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
                Text("Register Offline")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            if AuthRepository.shared.isLoggedIn() {
                // Restore cached user name for nav bar
                coordinator.userName = AuthRepository.shared.getCachedUser()?.fullName
                coordinator.route = .main
            } else {
                coordinator.route = .login
            }
        }
    }
}

#Preview {
    SplashView().environment(AppCoordinator())
}
