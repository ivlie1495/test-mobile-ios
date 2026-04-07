//
//  KTPCameraView.swift
//  Test Mobile iOS
//

import SwiftUI
import AVFoundation

// MARK: - Photo picker + Confirm flow
// Mirrors Android's ActivityResultContracts.GetContent — picks from gallery only.

struct KTPCaptureFlow: View {
    var onConfirm: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var capturedImage: UIImage? = nil

    var body: some View {
        if let image = capturedImage {
            KTPConfirmView(
                image: image,
                onUse: { onConfirm(image); dismiss() },
                onRetake: { capturedImage = nil }
            )
        } else {
            KTPPhotoPickerView(onPick: { capturedImage = $0 })
                .ignoresSafeArea()
        }
    }
}

// MARK: - Photo library picker (mirrors Android's GetContent intent)

struct KTPPhotoPickerView: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: KTPPhotoPickerView
        init(_ parent: KTPPhotoPickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onPick(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {}
    }
}

// MARK: - Confirm / review photo screen

struct KTPConfirmView: View {
    let image: UIImage
    var onUse: () -> Void
    var onRetake: () -> Void

    private var isGoodQuality: Bool {
        // Simple heuristic: image must be at least 200x200 px
        image.size.width >= 200 && image.size.height >= 200
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 4) {
                Text("Tinjau Gambar")
                    .font(.title3.bold())
                Text("Pastikan foto KTP jelas dan mudah dibaca.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)

            // Preview
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(24)

            // Quality indicator
            HStack(spacing: 8) {
                Image(systemName: isGoodQuality ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isGoodQuality ? Color(hex: "#1A7A3C") : Color(hex: "#E07B00"))
                Text(isGoodQuality
                     ? "Kualitas foto ini sudah baik"
                     : "Kualitas foto ini kurang baik. Kami sarankan untuk ambil foto ulang.")
                    .font(.subheadline)
                    .foregroundStyle(isGoodQuality ? Color(hex: "#1A7A3C") : Color(hex: "#E07B00"))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isGoodQuality ? Color(hex: "#E6F4EC") : Color(hex: "#FFF3E0"))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 24)

            Spacer()

            // Action buttons
            VStack(spacing: 10) {
                Button(action: onUse) {
                    Text("Gunakan foto ini")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(hex: "#3D5A99"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: onRetake) {
                    Text("Ambil foto ulang")
                        .font(.body.weight(.medium))
                        .foregroundStyle(Color(hex: "#3D5A99"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "#3D5A99"), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
}
