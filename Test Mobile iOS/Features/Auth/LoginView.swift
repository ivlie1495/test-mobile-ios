//
//  LoginView.swift
//  Test Mobile iOS
//

import SwiftUI

struct LoginView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var vm = LoginViewModel()
    @State private var showPassword = false

    private var isLoading: Bool { vm.uiState == .loading }
    private var errorMessage: String? {
        if case .error(let msg) = vm.uiState { return msg }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Header
                HStack(spacing: 8) {
                    Image(systemName: "person.text.rectangle.fill")
                        .foregroundStyle(Color(hex: "#3D5A99"))
                    Text("Register Offline")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#3D5A99"))
                }
                .padding(.top, 48)
                .padding(.bottom, 32)

                Text("Masuk ke Akun Verifikator")
                    .font(.title2.bold())
                    .padding(.bottom, 6)

                Text("Masukkan email dan password untuk masuk")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 32)

                // MARK: Email field
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 2) {
                        Text("Email").font(.subheadline.weight(.medium))
                        Text("*").foregroundStyle(.red)
                    }
                    TextField("Masukkan email di sini", text: $vm.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.bottom, 16)

                // MARK: Password field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password").font(.subheadline.weight(.medium))
                    HStack {
                        Group {
                            if showPassword {
                                TextField("Masukkan password", text: $vm.password)
                            } else {
                                SecureField("Masukkan password", text: $vm.password)
                            }
                        }
                        .textContentType(.password)
                        .autocapitalization(.none)

                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.bottom, 24)

                // MARK: Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.bottom, 12)
                }

                // MARK: Login button
                Button {
                    Task { await vm.login() }
                } label: {
                    ZStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Login")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(vm.canLogin ? Color(hex: "#3D5A99") : Color(.systemGray4))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!vm.canLogin || isLoading)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 4) {
                Text("Belum punya akun?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Klik Bantuan") {}
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(hex: "#3D5A99"))
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
        }
        .onChange(of: vm.uiState) { _, state in
            if case .success(let profile) = state {
                coordinator.userName = profile.fullName
                coordinator.route = .main
            }
        }
    }
}

#Preview {
    LoginView().environment(AppCoordinator())
}
