//
//  Member.swift
//  Test Mobile iOS
//

import Foundation

struct Member: Identifiable {
    // `id` conforms to Identifiable using a stable UUID (separate from DB row id).
    let id: UUID = UUID()
    var dbID: Int64?

    // Identity
    var name: String = ""
    var nik: String = ""
    var phone: String = ""
    var birthPlace: String = ""
    var birthDate: String = ""
    var gender: String = ""
    var status: String = ""
    var occupation: String = ""

    // KTP Address
    var address: String = ""
    var provinsi: String = ""
    var kotaKabupaten: String = ""
    var kecamatan: String = ""
    var kelurahan: String = ""
    var kodePos: String = ""

    // Domicile Address
    var sameAsKTP: Bool = true
    var alamatDomisili: String = ""
    var provinsiDomisili: String = ""
    var kotaDomisili: String = ""
    var kecamatanDomisili: String = ""
    var kelurahanDomisili: String = ""
    var kodePosDomisili: String = ""

    // Media (local file paths)
    var ktpFilePath: String?
    var ktpFileSecondaryPath: String?

    // Sync
    var syncStatus: SyncStatus = .draft
    var serverId: Int?

    // Computed: masked NIK for display
    var maskedNIK: String {
        guard nik.count == 16 else { return nik }
        let prefix = String(nik.prefix(3))
        let suffix = String(nik.suffix(3))
        return "\(prefix)*********\(suffix)"
    }
}
