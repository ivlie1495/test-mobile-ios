//
//  DatabaseManager.swift
//  Test Mobile iOS
//
//  Schema mirrors Android's identity_data table (IdentityEntity.kt).
//  Uses built-in SQLite3 — no external packages required.
//

import Foundation
import SQLite3

final class DatabaseManager {
    static let shared = DatabaseManager()

    private(set) var db: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
    }

    private func openDatabase() {
        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("testmobile.db")

        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        if sqlite3_open(url.path, &db) != SQLITE_OK {
            print("DatabaseManager: failed to open database")
        }
    }

    private func createTables() {
        // Column names match Android's IdentityEntity field names
        let sql = """
        CREATE TABLE IF NOT EXISTS identity_data (
            id                  INTEGER PRIMARY KEY AUTOINCREMENT,
            nama                TEXT NOT NULL DEFAULT '',
            nik                 TEXT NOT NULL DEFAULT '',
            telepon             TEXT NOT NULL DEFAULT '',
            tempat_lahir        TEXT NOT NULL DEFAULT '',
            tanggal_lahir       TEXT NOT NULL DEFAULT '',
            jenis_kelamin       TEXT NOT NULL DEFAULT '',
            status_pernikahan   TEXT NOT NULL DEFAULT '',
            pekerjaan           TEXT NOT NULL DEFAULT '',
            alamat_ktp          TEXT NOT NULL DEFAULT '',
            provinsi_ktp        TEXT NOT NULL DEFAULT '',
            kota_ktp            TEXT NOT NULL DEFAULT '',
            kecamatan_ktp       TEXT NOT NULL DEFAULT '',
            kelurahan_ktp       TEXT NOT NULL DEFAULT '',
            kode_pos_ktp        TEXT NOT NULL DEFAULT '',
            sama_ktp            INTEGER NOT NULL DEFAULT 1,
            alamat_domisili     TEXT NOT NULL DEFAULT '',
            provinsi_domisili   TEXT NOT NULL DEFAULT '',
            kota_domisili       TEXT NOT NULL DEFAULT '',
            kecamatan_domisili  TEXT NOT NULL DEFAULT '',
            kelurahan_domisili  TEXT NOT NULL DEFAULT '',
            kode_pos_domisili   TEXT NOT NULL DEFAULT '',
            foto_ktp_utama      TEXT,
            foto_ktp_pendukung  TEXT,
            status_form         TEXT NOT NULL DEFAULT 'Draft',
            created_at          INTEGER NOT NULL DEFAULT 0,
            updated_at          INTEGER NOT NULL DEFAULT 0
        );
        """
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_step(stmt)
        }
        sqlite3_finalize(stmt)
    }
}
