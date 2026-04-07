//
//  MemberListViewModel.swift
//  Test Mobile iOS
//
//  Mirrors Android's MainViewModel — uses SyncState for progress tracking.
//

import Foundation

@Observable
final class MemberListViewModel {
    var draftMembers: [Member]    = []
    var uploadedMembers: [Member] = []
    var syncState: SyncState      = .idle
    var showUploadConfirm: Bool   = false
    var toast: String?
    var errorMessage: String?

    // MARK: - Load (mirrors MainViewModel observers)

    func loadData() {
        do {
            draftMembers    = try MemberRepository.shared.getDrafts()
            uploadedMembers = try MemberRepository.shared.getSynced()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadServerMembers() async {
        do {
            let serverList  = try await MemberRepository.shared.getServerMembers()
            uploadedMembers = serverList
        } catch {
            // Silently fall back to locally synced records
            uploadedMembers = (try? MemberRepository.shared.getSynced()) ?? []
        }
    }

    // MARK: - Upload single (mirrors MainViewModel.uploadSingle)

    func uploadSingle(_ member: Member) async {
        syncState    = .inProgress(done: 0, total: 1)
        errorMessage = nil
        do {
            try await MemberRepository.shared.uploadMember(member)
            loadData()
            showToast("Data berhasil di-upload")
        } catch {
            errorMessage = error.localizedDescription
        }
        syncState = .idle
    }

    // MARK: - Upload all drafts (mirrors MainViewModel.syncAll)

    func uploadAll() async {
        let total    = draftMembers.count
        syncState    = .inProgress(done: 0, total: total)
        errorMessage = nil
        do {
            try await MemberRepository.shared.uploadAllDrafts { done, total in
                Task { @MainActor in
                    self.syncState = .inProgress(done: done, total: total)
                }
            }
            loadData()
            showToast("Data berhasil di-upload")
        } catch {
            errorMessage = error.localizedDescription
        }
        syncState = .idle
    }

    // MARK: - Delete

    func deleteDraft(_ member: Member) {
        guard let id = member.dbID else { return }
        try? MemberDAO.shared.deleteMember(id: id)
        loadData()
    }

    // MARK: - Helpers

    var isSyncing: Bool {
        if case .inProgress = syncState { return true }
        return false
    }

    var syncProgressLabel: String {
        if case .inProgress(let done, let total) = syncState {
            return "Mengupload \(done)/\(total)..."
        }
        return ""
    }

    private func showToast(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            toast = nil
        }
    }
}
