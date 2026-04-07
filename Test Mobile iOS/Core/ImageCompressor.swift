//
//  ImageCompressor.swift
//  Test Mobile iOS
//

import UIKit

enum ImageCompressor {
    /// Resizes and compresses a UIImage — max 1024×1024 px at 70% JPEG quality,
    /// then adaptively reduces quality further until under maxSizeKB.
    static func compress(_ image: UIImage, maxSizeKB: Int = 500) -> Data {
        let resized = resize(image, maxDimension: 1024)
        let maxBytes = maxSizeKB * 1024
        var quality: CGFloat = 0.7
        var data = resized.jpegData(compressionQuality: quality) ?? Data()

        while data.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            data = resized.jpegData(compressionQuality: quality) ?? Data()
        }
        return data
    }

    /// Scales image down so neither dimension exceeds maxDimension, preserving aspect ratio.
    static func resize(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Saves compressed image to the app's Documents directory, returns the file path.
    static func saveToDocuments(_ image: UIImage, fileName: String) -> String? {
        let data = compress(image)
        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return url.path
        } catch {
            return nil
        }
    }

    /// Loads image data from a stored file path.
    static func loadData(from path: String) -> Data? {
        FileManager.default.contents(atPath: path)
    }
}
