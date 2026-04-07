//
//  MemberFormViewModel.swift
//  Test Mobile iOS
//
//  Mirrors Android's IdentityFormViewModel:
//  - saveAsDraft() only — no upload from form
//  - All fields optional
//

import UIKit

@Observable
final class MemberFormViewModel {
    var member = Member()
    var ktpImage: UIImage?
    var ktpImageSecondary: UIImage?
    var isSaving: Bool = false
    var errorMessage: String?

    // All fields optional — mirrors Android's IdentityFormActivity

    // MARK: - Load existing member for editing

    func load(_ existing: Member) {
        member = existing
        if let path = existing.ktpFilePath,
           let data = ImageCompressor.loadData(from: path) {
            ktpImage = UIImage(data: data)
        }
        if let path = existing.ktpFileSecondaryPath,
           let data = ImageCompressor.loadData(from: path) {
            ktpImageSecondary = UIImage(data: data)
        }
    }

    // MARK: - Save as Draft
    // Mirrors Android's vm.saveAsDraft(entity) → saveResult.observe → Toast → finish()

    func saveDraft() throws {
        isSaving = true
        defer { isSaving = false }

        saveImages()
        member.syncStatus = .draft

        if let dbID = member.dbID {
            var updated = member
            updated.dbID = dbID
            try MemberRepository.shared.updateDraft(updated)
        } else {
            let newID = try MemberRepository.shared.saveDraft(member)
            member.dbID = newID
        }
    }

    // MARK: - Private

    private func saveImages() {
        if let img = ktpImage {
            let fileName = "ktp_utama_\(UUID().uuidString).jpg"
            member.ktpFilePath = ImageCompressor.saveToDocuments(img, fileName: fileName)
        }
        if let img = ktpImageSecondary {
            let fileName = "ktp_pendukung_\(UUID().uuidString).jpg"
            member.ktpFileSecondaryPath = ImageCompressor.saveToDocuments(img, fileName: fileName)
        }
    }
}
