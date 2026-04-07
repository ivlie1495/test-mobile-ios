//
//  Test_Mobile_iOSApp.swift
//  Test Mobile iOS
//
//  Created by Ivan Lie on 07/04/26.
//

import SwiftUI

@main
struct Test_Mobile_iOSApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            Group {
                switch coordinator.route {
                case .splash:  SplashView()
                case .login:   LoginView()
                case .main:    MemberListView()
                case .profile: ProfileView()
                }
            }
            .environment(coordinator)
        }
    }
}
