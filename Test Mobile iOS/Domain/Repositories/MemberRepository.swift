//
//  MemberRepository.swift
//  Test Mobile iOS
//
//  Mirrors Android's IdentityUploadService + ItemRepositoryImpl:
//  - Converts tanggalLahir from DD/MM/YYYY → YYYY-MM-DD before upload
//  - Copies KTP address to domicile when samaKtp == true
//  - Compresses photos via ImageUtils before attaching as multipart
//

import Foundation
import UIKit

private struct MemberResponse: Decodable {
    let name: String?
    let nik: String?
    let phone: String?
    let ktpUrl: String?
    let ktpUrlSecondary: String?

    enum CodingKeys: String, CodingKey {
        case name, nik, phone
        case ktpUrl = "ktp_url"
        case ktpUrlSecondary = "ktp_url_secondary"
    }
}

final class MemberRepository {
    static let shared = MemberRepository()
    private init() {}

    // MARK: - Local CRUD (mirrors ItemRepositoryImpl)

    @discardableResult
    func saveDraft(_ member: Member) throws -> Int64 {
        try MemberDAO.shared.insertMember(member)
    }

    func updateDraft(_ member: Member) throws {
        try MemberDAO.shared.updateMember(member)
    }

    func getDrafts() throws -> [Member] {
        try MemberDAO.shared.fetchAllDrafts()
    }

    func getSynced() throws -> [Member] {
        try MemberDAO.shared.fetchSynced()
    }

    // MARK: - Upload single (mirrors IdentityUploadService)

    func uploadMember(_ member: Member) async throws {
        guard let dbID = member.dbID else { throw DBError.missingID }

        // Convert tanggal_lahir: DD/MM/YYYY → YYYY-MM-DD (mirrors Android's IdentityUploadService)
        let birthDateForAPI = convertDateForAPI(member.birthDate)

        // If samaKtp == true, reuse KTP address for domicile (mirrors Android)
        let domisiliAddress   = member.sameAsKTP ? member.address       : member.alamatDomisili
        let domisiliProvinsi  = member.sameAsKTP ? member.provinsi      : member.provinsiDomisili
        let domisiliKota      = member.sameAsKTP ? member.kotaKabupaten : member.kotaDomisili
        let domisiliKecamatan = member.sameAsKTP ? member.kecamatan     : member.kecamatanDomisili
        let domisiliKelurahan = member.sameAsKTP ? member.kelurahan     : member.kelurahanDomisili
        let domisiliKodePos   = member.sameAsKTP ? member.kodePos       : member.kodePosDomisili

        let fields: [String: String] = [
            "name":                    member.name,
            "nik":                     member.nik,
            "phone":                   member.phone,
            "birth_place":             member.birthPlace,
            "birth_date":              birthDateForAPI,
            "status":                  member.status,
            "occupation":              member.occupation,
            "address":                 member.address,
            "provinsi":                member.provinsi,
            "kota_kabupaten":          member.kotaKabupaten,
            "kecamatan":               member.kecamatan,
            "kelurahan":               member.kelurahan,
            "kode_pos":                member.kodePos,
            "alamat_domisili":         domisiliAddress,
            "provinsi_domisili":       domisiliProvinsi,
            "kota_kabupaten_domisili": domisiliKota,
            "kecamatan_domisili":      domisiliKecamatan,
            "kelurahan_domisili":      domisiliKelurahan,
            "kode_pos_domisili":       domisiliKodePos,
        ]

        // Compress photos before upload — mirrors ImageUtils.compressImage()
        var files: [MultipartFile] = []
        if let path = member.ktpFilePath,
           let data = ImageCompressor.loadData(from: path) {
            files.append(MultipartFile(
                fieldName: "ktp_file",
                fileName:  "ktp_utama_\(dbID).jpg",
                mimeType:  "image/jpeg",
                data:       data
            ))
        }
        if let path = member.ktpFileSecondaryPath,
           let data = ImageCompressor.loadData(from: path) {
            files.append(MultipartFile(
                fieldName: "ktp_file_secondary",
                fileName:  "ktp_pendukung_\(dbID).jpg",
                mimeType:  "image/jpeg",
                data:       data
            ))
        }

        _ = try await APIClient.shared.uploadMultipart(
            url: APIEndpoints.members,
            fields: fields,
            files: files
        )

        // Mark as synced locally — mirrors IdentityDao.markAsSynced
        try MemberDAO.shared.markAsSynced(id: dbID)
    }

    // MARK: - Bulk upload (mirrors MainViewModel.syncAll)

    func uploadAllDrafts(onProgress: ((Int, Int) -> Void)? = nil) async throws {
        let drafts = try getDrafts()
        let total = drafts.count
        for (index, member) in drafts.enumerated() {
            try await uploadMember(member)
            onProgress?(index + 1, total)
        }
    }

    // MARK: - Fetch from server (mirrors ApiService.getMembers)

    func getServerMembers() async throws -> [Member] {
        let list: [MemberResponse] = try await APIClient.shared.request(
            url: APIEndpoints.members
        )
        return list.map { r in
            var m = Member()
            m.name       = r.name  ?? ""
            m.nik        = r.nik   ?? ""
            m.phone      = r.phone ?? ""
            m.syncStatus = .synced
            return m
        }
    }

    // MARK: - Date conversion (mirrors Android's IdentityUploadService)

    /// Converts "DD/MM/YYYY" → "YYYY-MM-DD" for the API.
    private func convertDateForAPI(_ date: String) -> String {
        let parts = date.split(separator: "/")
        guard parts.count == 3 else { return date }
        return "\(parts[2])-\(parts[1])-\(parts[0])"
    }
}
