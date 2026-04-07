//
//  APIClient.swift
//  Test Mobile iOS
//

import Foundation

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int, String)
    case decodingError(Error)
    case noToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:       return "Invalid server response."
        case .httpError(let code, let msg): return "Error \(code): \(msg)"
        case .decodingError(let e):  return "Decoding error: \(e.localizedDescription)"
        case .noToken:               return "Authentication token not found."
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared

    // MARK: - Generic JSON request

    func request<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            guard let token = KeychainService.shared.getToken() else { throw APIError.noToken }
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: req)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(http.statusCode, msg)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Multipart upload

    func uploadMultipart(
        url: URL,
        fields: [String: String],
        files: [MultipartFile]
    ) async throws -> Data {
        guard let token = KeychainService.shared.getToken() else { throw APIError.noToken }

        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = buildMultipartBody(fields: fields, files: files, boundary: boundary)

        let (data, response) = try await session.data(for: req)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpError(http.statusCode, msg)
        }

        return data
    }

    // MARK: - Multipart body builder

    private func buildMultipartBody(
        fields: [String: String],
        files: [MultipartFile],
        boundary: String
    ) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let dash = "--"

        for (key, value) in fields {
            body.append("\(dash)\(boundary)\(crlf)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(crlf)\(crlf)")
            body.append("\(value)\(crlf)")
        }

        for file in files {
            body.append("\(dash)\(boundary)\(crlf)")
            body.append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\(crlf)")
            body.append("Content-Type: \(file.mimeType)\(crlf)\(crlf)")
            body.append(file.data)
            body.append(crlf)
        }

        body.append("\(dash)\(boundary)\(dash)\(crlf)")
        return body
    }
}

// MARK: - Helpers

struct MultipartFile {
    let fieldName: String
    let fileName: String
    let mimeType: String
    let data: Data
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
    mutating func append(_ string: String, encoding: String.Encoding) {
        if let data = string.data(using: encoding) { append(data) }
    }
}
