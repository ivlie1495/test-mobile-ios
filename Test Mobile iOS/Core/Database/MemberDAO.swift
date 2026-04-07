//
//  MemberDAO.swift
//  Test Mobile iOS
//
//  Targets the identity_data table — mirrors Android's IdentityDao.kt.
//

import Foundation
import SQLite3

final class MemberDAO {
    static let shared = MemberDAO()
    private init() {}

    private var db: OpaquePointer? { DatabaseManager.shared.db }

    // MARK: - Insert (mirrors IdentityDao.insert)

    func insertMember(_ member: Member) throws -> Int64 {
        let sql = """
        INSERT INTO identity_data (
            nama, nik, telepon, tempat_lahir, tanggal_lahir, jenis_kelamin,
            status_pernikahan, pekerjaan,
            alamat_ktp, provinsi_ktp, kota_ktp, kecamatan_ktp, kelurahan_ktp, kode_pos_ktp,
            sama_ktp,
            alamat_domisili, provinsi_domisili, kota_domisili,
            kecamatan_domisili, kelurahan_domisili, kode_pos_domisili,
            foto_ktp_utama, foto_ktp_pendukung,
            status_form, created_at, updated_at
        ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        bind(stmt, member)
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw DBError.stepFailed }
        return sqlite3_last_insert_rowid(db)
    }

    // MARK: - Update (mirrors IdentityDao.update)

    func updateMember(_ member: Member) throws {
        guard let dbID = member.dbID else { throw DBError.missingID }
        let sql = """
        UPDATE identity_data SET
            nama=?, nik=?, telepon=?, tempat_lahir=?, tanggal_lahir=?, jenis_kelamin=?,
            status_pernikahan=?, pekerjaan=?,
            alamat_ktp=?, provinsi_ktp=?, kota_ktp=?, kecamatan_ktp=?, kelurahan_ktp=?, kode_pos_ktp=?,
            sama_ktp=?,
            alamat_domisili=?, provinsi_domisili=?, kota_domisili=?,
            kecamatan_domisili=?, kelurahan_domisili=?, kode_pos_domisili=?,
            foto_ktp_utama=?, foto_ktp_pendukung=?,
            status_form=?, created_at=?, updated_at=?
        WHERE id=?;
        """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        bind(stmt, member)
        sqlite3_bind_int64(stmt, 27, dbID)
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw DBError.stepFailed }
    }

    // MARK: - Fetch (mirrors IdentityDao)

    /// Returns all drafts ordered by updatedAt DESC — mirrors getDrafts()
    func fetchAllDrafts() throws -> [Member] {
        try fetchWhere("status_form = 'Draft'")
    }

    /// Returns all synced records — mirrors getAll() filtered
    func fetchSynced() throws -> [Member] {
        try fetchWhere("status_form = 'Synced'")
    }

    func fetchAll() throws -> [Member] {
        try fetchWhere(nil)
    }

    // MARK: - Mark synced (mirrors IdentityDao.markAsSynced)

    func markAsSynced(id: Int64) throws {
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        let sql = "UPDATE identity_data SET status_form='Synced', updated_at=? WHERE id=?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int64(stmt, 1, now)
        sqlite3_bind_int64(stmt, 2, id)
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw DBError.stepFailed }
    }

    // MARK: - Delete (mirrors IdentityDao.delete)

    func deleteMember(id: Int64) throws {
        let sql = "DELETE FROM identity_data WHERE id=?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_int64(stmt, 1, id)
        guard sqlite3_step(stmt) == SQLITE_DONE else { throw DBError.stepFailed }
    }

    // MARK: - Private helpers

    private func fetchWhere(_ condition: String?) throws -> [Member] {
        let sql = condition != nil
            ? "SELECT * FROM identity_data WHERE \(condition!) ORDER BY updated_at DESC;"
            : "SELECT * FROM identity_data ORDER BY updated_at DESC;"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw DBError.prepareFailed
        }
        defer { sqlite3_finalize(stmt) }

        var members: [Member] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            members.append(row(stmt))
        }
        return members
    }

    private func bind(_ stmt: OpaquePointer?, _ m: Member) {
        let now = Int64(Date().timeIntervalSince1970 * 1000)

        func text(_ idx: Int32, _ val: String) {
            sqlite3_bind_text(stmt, idx, (val as NSString).utf8String, -1, nil)
        }
        func textOpt(_ idx: Int32, _ val: String?) {
            if let v = val { sqlite3_bind_text(stmt, idx, (v as NSString).utf8String, -1, nil) }
            else { sqlite3_bind_null(stmt, idx) }
        }

        text(1,  m.name);           text(2,  m.nik);          text(3,  m.phone)
        text(4,  m.birthPlace);     text(5,  m.birthDate);    text(6,  m.gender)
        text(7,  m.status);         text(8,  m.occupation)
        text(9,  m.address);        text(10, m.provinsi);     text(11, m.kotaKabupaten)
        text(12, m.kecamatan);      text(13, m.kelurahan);    text(14, m.kodePos)
        sqlite3_bind_int(stmt, 15, m.sameAsKTP ? 1 : 0)
        text(16, m.alamatDomisili);      text(17, m.provinsiDomisili)
        text(18, m.kotaDomisili);        text(19, m.kecamatanDomisili)
        text(20, m.kelurahanDomisili);   text(21, m.kodePosDomisili)
        textOpt(22, m.ktpFilePath);      textOpt(23, m.ktpFileSecondaryPath)
        text(24, m.syncStatus.rawValue)
        sqlite3_bind_int64(stmt, 25, m.dbID == nil ? now : now) // created_at (first insert keeps original)
        sqlite3_bind_int64(stmt, 26, now)                       // updated_at
    }

    private func row(_ stmt: OpaquePointer?) -> Member {
        func str(_ idx: Int32) -> String {
            guard let c = sqlite3_column_text(stmt, idx) else { return "" }
            return String(cString: c)
        }
        func strOpt(_ idx: Int32) -> String? {
            guard let c = sqlite3_column_text(stmt, idx) else { return nil }
            return String(cString: c)
        }

        var m = Member()
        m.dbID                  = sqlite3_column_int64(stmt, 0)
        m.name                  = str(1);   m.nik           = str(2);   m.phone         = str(3)
        m.birthPlace            = str(4);   m.birthDate     = str(5);   m.gender        = str(6)
        m.status                = str(7);   m.occupation    = str(8)
        m.address               = str(9);   m.provinsi      = str(10);  m.kotaKabupaten = str(11)
        m.kecamatan             = str(12);  m.kelurahan     = str(13);  m.kodePos       = str(14)
        m.sameAsKTP             = sqlite3_column_int(stmt, 15) == 1
        m.alamatDomisili        = str(16);  m.provinsiDomisili    = str(17)
        m.kotaDomisili          = str(18);  m.kecamatanDomisili   = str(19)
        m.kelurahanDomisili     = str(20);  m.kodePosDomisili     = str(21)
        m.ktpFilePath           = strOpt(22)
        m.ktpFileSecondaryPath  = strOpt(23)
        m.syncStatus            = SyncStatus(rawValue: str(24)) ?? .draft
        return m
    }
}

// MARK: - Errors

enum DBError: LocalizedError {
    case prepareFailed
    case stepFailed
    case missingID

    var errorDescription: String? {
        switch self {
        case .prepareFailed: return "Gagal mempersiapkan perintah SQL."
        case .stepFailed:    return "Gagal menjalankan perintah SQL."
        case .missingID:     return "Data tidak memiliki ID lokal."
        }
    }
}
