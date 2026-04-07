//
//  AppCoordinator.swift
//  Test Mobile iOS
//

import SwiftUI

enum AppRoute {
    case splash
    case login
    case main
    case profile
}

@Observable
class AppCoordinator {
    var route: AppRoute = .splash
    var userName: String? = nil
}
