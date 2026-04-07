//
//  ProfileView.swift
//  Test Mobile iOS
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var vm = ProfileViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if vm.isLoading && vm.profile == nil {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            profileHeader
                            menuList
                            versionLabel
                        }
                        .padding(.top, 24)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        coordinator.route = .main
                    } label: {
                        Image(systemName: "chevron.left")
                        Text("Kembali")
                    }
                }
            }
            .task { await vm.loadProfile() }
            .onChange(of: vm.profile) { _, profile in
                if let name = profile?.fullName {
                    coordinator.userName = name
                }
            }
            .confirmationDialog(
                "Keluar",
                isPresented: $vm.showLogoutConfirm,
                titleVisibility: .visible
            ) {
                Button("Ya, keluar", role: .destructive) {
                    vm.logout(coordinator: coordinator)
                }
                Button("Batal", role: .cancel) {}
            } message: {
                Text("Apakah kamu yakin ingin keluar?\nData yang ada di draft-mu mungkin akan hilang. Kami sarankan untuk upload terlebih dahulu.")
            }
            .alert("Gagal", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        VStack(spacing: 10) {
            // Avatar circle
            ZStack {
                Circle()
                    .fill(Color(hex: "#3D5A99").opacity(0.15))
                    .frame(width: 88, height: 88)
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "#3D5A99"))
            }

            Text(vm.profile?.fullName ?? "-")
                .font(.title3.bold())

            Text(vm.profile?.email ?? "-")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .padding(.bottom, 20)
    }

    // MARK: - Menu list

    private var menuList: some View {
        VStack(spacing: 0) {
            menuRow(
                icon: "questionmark.circle.fill",
                iconColor: Color(.systemGray),
                label: "Bantuan"
            ) {
                // placeholder — future feature
            }

            Divider().padding(.leading, 56)

            menuRow(
                icon: "rectangle.portrait.and.arrow.right.fill",
                iconColor: .red,
                label: "Keluar",
                labelColor: .red
            ) {
                vm.showLogoutConfirm = true
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
    }

    private func menuRow(
        icon: String,
        iconColor: Color,
        label: String,
        labelColor: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
                    .frame(width: 28)

                Text(label)
                    .font(.body)
                    .foregroundStyle(labelColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color(.systemGray3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Version label

    private var versionLabel: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return Text("v\(version).\(build)")
            .font(.footnote)
            .foregroundStyle(Color(.systemGray3))
            .padding(.top, 32)
            .padding(.bottom, 16)
    }
}

#Preview {
    ProfileView()
        .environment(AppCoordinator())
}
