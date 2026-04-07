//
//  MemberListView.swift
//  Test Mobile iOS
//

import SwiftUI

struct MemberListView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @State private var vm = MemberListViewModel()
    @State private var selectedTab: Tab = .draft
    @State private var showForm = false
    @State private var memberToEdit: Member? = nil

    enum Tab { case draft, uploaded }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {

                    // MARK: Nav bar
                    navBar

                    // MARK: Tab selector
                    tabSelector

                    // MARK: Content
                    if selectedTab == .draft {
                        draftTab
                    } else {
                        uploadedTab
                    }
                }

                // MARK: Bottom buttons (Draft tab only)
                if selectedTab == .draft {
                    bottomButtons
                }

                // MARK: Toast
                if let toast = vm.toast {
                    toastBanner(toast)
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                vm.loadData()
                Task { await vm.loadServerMembers() }
            }
            .sheet(isPresented: $showForm, onDismiss: { vm.loadData() }) {
                MemberFormView(editingMember: nil)
            }
            .sheet(item: $memberToEdit, onDismiss: { vm.loadData() }) { member in
                MemberFormView(editingMember: member)
            }
            .confirmationDialog(
                "Upload Semua Data",
                isPresented: $vm.showUploadConfirm,
                titleVisibility: .visible
            ) {
                Button("Ya, Upload Semua (\(vm.draftMembers.count))") {
                    Task { await vm.uploadAll() }
                }
                Button("Batal", role: .cancel) {}
            } message: {
                Text("Apakah kamu yakin ingin upload semua data?\nPastikan kamu sudah mengisi semua data yang diperlukan dengan benar, ya!")
            }
            .alert("Gagal", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "person.text.rectangle.fill")
                    .foregroundStyle(Color(hex: "#3D5A99"))
                Text("Register Offline")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: "#3D5A99"))
            }
            Spacer()
            Button {
                coordinator.route = .profile
            } label: {
                HStack(spacing: 6) {
                    Text(coordinator.userName ?? "Pengguna")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                    Image(systemName: "person.circle")
                        .foregroundStyle(Color(hex: "#3D5A99"))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Tab selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton("Draft", tab: .draft)
            tabButton("Sudah Di-Upload", tab: .uploaded)
        }
        .background(Color(.systemBackground))
    }

    private func tabButton(_ title: String, tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 0) {
                Text(title)
                    .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                    .foregroundStyle(selectedTab == tab ? Color(hex: "#3D5A99") : .secondary)
                    .padding(.vertical, 12)
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(selectedTab == tab ? Color(hex: "#3D5A99") : .clear)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Draft tab

    private var draftTab: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    if vm.draftMembers.isEmpty {
                        emptyState(
                            title: "Belum ada data",
                            subtitle: "Klik \"Tambah Data\" untuk menambahkan data calon anggota"
                        )
                    } else {
                        // Info banner
                        infoBanner("Nomor Handphone, NIK, dan Foto KTP wajib diisi sebelum di-upload")
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                        ForEach(Array(vm.draftMembers.enumerated()), id: \.element.id) { index, member in
                            draftRow(index: index + 1, member: member)
                        }
                        .padding(.bottom, 140) // space for bottom buttons
                    }
                } header: {
                    if !vm.draftMembers.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("List Draft KTA")
                                .font(.headline)
                            Text("Upload untuk mengirimkan data ini ke admin untuk di-verifikasi.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
        }
    }

    // MARK: - Draft row

    private func draftRow(index: Int, member: Member) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Index + thumbnail
                Text("\(index)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                ktpThumbnail(path: member.ktpFilePath)

                // NIK + phone
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.nik.isEmpty ? "-" : member.maskedNIK)
                        .font(.subheadline.weight(.medium))
                    Text(member.phone.isEmpty ? "-" : member.phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Draft badge
                Text("Draft")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#E07B00"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#FFF3E0"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Action buttons
            HStack(spacing: 0) {
                Spacer()
                Button {
                    memberToEdit = member
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(Color(hex: "#3D5A99"))
                }

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 16)

                Button {
                    Task { await vm.uploadSingle(member) }
                } label: {
                    Label("Upload", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .foregroundStyle(vm.isSyncing ? .secondary : Color(hex: "#3D5A99"))
                }
                .disabled(vm.isSyncing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().padding(.horizontal, 16)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Uploaded tab

    private var uploadedTab: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    if vm.uploadedMembers.isEmpty {
                        emptyState(
                            title: "Belum ada data",
                            subtitle: "Data yang sudah di-upload akan muncul di sini"
                        )
                    } else {
                        ForEach(Array(vm.uploadedMembers.enumerated()), id: \.offset) { index, member in
                            uploadedRow(index: index + 1, member: member)
                        }
                    }
                } header: {
                    if !vm.uploadedMembers.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Data yang sudah di-upload")
                                .font(.headline)
                            Text("Data-data ini sudah dikirimkan ke admin verifikator.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
        }
    }

    // MARK: - Uploaded row

    private func uploadedRow(index: Int, member: Member) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("\(index)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                ktpThumbnail(path: member.ktpFilePath)

                VStack(alignment: .leading, spacing: 2) {
                    Text(member.nik.isEmpty ? "-" : member.maskedNIK)
                        .font(.subheadline.weight(.medium))
                    Text(member.phone.isEmpty ? "-" : member.phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Di-upload")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#1A7A3C"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(hex: "#E6F4EC"))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.systemBackground))

            Divider().padding(.horizontal, 16)
        }
    }

    // MARK: - Bottom buttons

    private var bottomButtons: some View {
        VStack(spacing: 8) {
            Button {
                showForm = true
            } label: {
                Label("Tambah Data", systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color(hex: "#3D5A99"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                if !vm.draftMembers.isEmpty {
                    vm.showUploadConfirm = true
                }
            } label: {
                HStack(spacing: 6) {
                    if vm.isSyncing {
                        ProgressView().tint(Color(hex: "#3D5A99"))
                        Text(vm.syncProgressLabel)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                        Text(vm.draftMembers.isEmpty
                             ? "Upload Semua"
                             : "Upload Semua (\(vm.draftMembers.count))")
                    }
                }
                .font(.body.weight(.medium))
                .foregroundStyle(vm.draftMembers.isEmpty ? .secondary : Color(hex: "#3D5A99"))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(vm.draftMembers.isEmpty ? Color(.systemGray4) : Color(hex: "#3D5A99"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(vm.draftMembers.isEmpty || vm.isSyncing)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .padding(.top, 8)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.08), radius: 8, y: -4)
        )
    }

    // MARK: - Shared components

    private func ktpThumbnail(path: String?) -> some View {
        Group {
            if let path, let data = ImageCompressor.loadData(from: path),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.text.rectangle")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 32)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func infoBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color(hex: "#3D5A99"))
                .padding(.top, 1)
            Text(text)
                .font(.caption)
                .foregroundStyle(Color(hex: "#3D5A99"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#EEF2FF"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Spacer(minLength: 60)
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(Color(.systemGray3))
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color(.systemGray3))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity)
    }

    private func toastBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#1A7A3C"))
        .clipShape(Capsule())
        .shadow(radius: 8)
        .padding(.bottom, 100)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: vm.toast)
    }
}

#Preview {
    MemberListView()
        .environment(AppCoordinator())
}
