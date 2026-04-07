//
//  MemberFormView.swift
//  Test Mobile iOS
//
//  Mirrors Android's IdentityFormActivity:
//  - Single "Simpan sebagai Draft" button (no Upload in form)
//  - No gender field (not in IdentityEntity)
//  - Status: Belum Menikah / Menikah / Cerai Hidup / Cerai Mati
//  - Date format DD/MM/YYYY (setupDatePicker)
//  - Gallery photo picker (ActivityResultContracts.GetContent)
//  - Toast "Tersimpan sebagai Draft" on save then dismiss
//

import SwiftUI

struct MemberFormView: View {
    var editingMember: Member?

    @Environment(\.dismiss) private var dismiss
    @State private var vm = MemberFormViewModel()
    @State private var showPickerPrimary   = false
    @State private var showPickerSecondary = false
    @State private var showDatePicker      = false
    @State private var showToast           = false

    // Only dropdown in the form — mirrors Android's setupStatusDropdown
    private let statusOptions = ["Belum Menikah", "Menikah", "Cerai Hidup", "Cerai Mati"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        sectionDataUtama
                        sectionInformasiLainnya
                        sectionAlamatKTP
                        sectionAlamatDomisili
                        // Space for fixed bottom button
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                // MARK: Fixed bottom button — mirrors Android's btnSimpan
                btnSimpan
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                    .background(
                        Color(.systemBackground)
                            .shadow(color: .black.opacity(0.08), radius: 8, y: -4)
                    )

                // MARK: Toast — mirrors Android's Toast.makeText("Tersimpan sebagai Draft")
                if showToast {
                    toastView
                }
            }
            .navigationTitle(editingMember == nil ? "Tambah Data" : "Edit Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                if let m = editingMember { vm.load(m) }
            }
            .alert("Gagal", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .sheet(isPresented: $showPickerPrimary) {
                KTPCaptureFlow { vm.ktpImage = $0 }
            }
            .sheet(isPresented: $showPickerSecondary) {
                KTPCaptureFlow { vm.ktpImageSecondary = $0 }
            }
        }
    }

    // MARK: - Section: Data Utama

    private var sectionDataUtama: some View {
        FormSection(title: "Data Utama") {
            FormField(label: "Nomor Handphone") {
                TextField("Masukkan nomor handphone", text: $vm.member.phone)
                    .keyboardType(.phonePad)
            }

            FormField(label: "NIK") {
                TextField("16 digit no KTP", text: $vm.member.nik)
                    .keyboardType(.numberPad)
                    .onChange(of: vm.member.nik) { _, val in
                        if val.count > 16 { vm.member.nik = String(val.prefix(16)) }
                    }
            }

            // Foto KTP — mirrors fotoUtamaUri / fotoPendukungUri via GetContent
            VStack(alignment: .leading, spacing: 6) {
                Text("Foto KTP")
                    .font(.subheadline.weight(.medium))
                Text("Pilih 2 foto KTP dari galeri. Pastikan KTP terlihat jelas dan tidak blur.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ktpPhotoButton(image: vm.ktpImage, label: "Foto KTP Utama") {
                        showPickerPrimary = true
                    }
                    ktpPhotoButton(image: vm.ktpImageSecondary, label: "Foto KTP Pendukung") {
                        showPickerSecondary = true
                    }
                }
            }
        }
    }

    // MARK: - Section: Informasi Lainnya
    // No gender field — mirrors IdentityEntity (no jenisKelamin column)

    private var sectionInformasiLainnya: some View {
        FormSection(title: "Informasi Lainnya") {
            FormField(label: "Nama Lengkap") {
                TextField("Masukkan nama sesuai KTP", text: $vm.member.name)
            }

            FormField(label: "Tempat Lahir") {
                TextField("Masukkan tempat lahir sesuai KTP", text: $vm.member.birthPlace)
            }

            // Tanggal Lahir — mirrors setupDatePicker (DD/MM/YYYY)
            VStack(alignment: .leading, spacing: 6) {
                Text("Tanggal Lahir")
                    .font(.subheadline.weight(.medium))
                Button {
                    showDatePicker.toggle()
                } label: {
                    HStack {
                        Text(vm.member.birthDate.isEmpty ? "DD/MM/YYYY" : vm.member.birthDate)
                            .foregroundStyle(vm.member.birthDate.isEmpty ? Color(.placeholderText) : .primary)
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                if showDatePicker {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: {
                                let fmt = DateFormatter()
                                fmt.dateFormat = "dd/MM/yyyy"
                                return fmt.date(from: vm.member.birthDate) ?? Date()
                            },
                            set: { date in
                                let fmt = DateFormatter()
                                fmt.dateFormat = "dd/MM/yyyy"
                                vm.member.birthDate = fmt.string(from: date)
                                showDatePicker = false
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
            }

            // Status — mirrors setupStatusDropdown order
            FormField(label: "Status") {
                FormPicker(
                    placeholder: "Pilih status sesuai KTP",
                    selection: $vm.member.status,
                    options: statusOptions
                )
            }

            FormField(label: "Pekerjaan") {
                TextField("Masukkan pekerjaan sesuai KTP", text: $vm.member.occupation)
            }
        }
    }

    // MARK: - Section: Alamat KTP

    private var sectionAlamatKTP: some View {
        FormSection(title: "Informasi Alamat KTP") {
            FormField(label: "Alamat Lengkap") {
                TextField("Masukkan alamat sesuai KTP", text: $vm.member.address)
            }
            FormField(label: "Provinsi") {
                TextField("Masukkan provinsi", text: $vm.member.provinsi)
            }
            FormField(label: "Kota/Kabupaten") {
                TextField("Masukkan kota/kabupaten", text: $vm.member.kotaKabupaten)
            }
            FormField(label: "Kecamatan") {
                TextField("Masukkan kecamatan", text: $vm.member.kecamatan)
            }
            FormField(label: "Kelurahan") {
                TextField("Masukkan kelurahan", text: $vm.member.kelurahan)
            }
            FormField(label: "Kode Pos") {
                TextField("Masukkan kode pos", text: $vm.member.kodePos)
                    .keyboardType(.numberPad)
            }
        }
    }

    // MARK: - Section: Alamat Domisili
    // Mirrors setupSamaKtpCheckbox — auto-copies KTP fields when toggled on

    private var sectionAlamatDomisili: some View {
        FormSection(title: "Alamat Domisili") {
            Toggle(isOn: $vm.member.sameAsKTP) {
                Text("Alamat domisili sama dengan alamat pada KTP")
                    .font(.subheadline)
            }
            .tint(Color(hex: "#3D5A99"))

            if !vm.member.sameAsKTP {
                FormField(label: "Alamat Lengkap") {
                    TextField("Masukkan alamat domisili", text: $vm.member.alamatDomisili)
                }
                FormField(label: "Provinsi") {
                    TextField("Masukkan provinsi", text: $vm.member.provinsiDomisili)
                }
                FormField(label: "Kota/Kabupaten") {
                    TextField("Masukkan kota/kabupaten", text: $vm.member.kotaDomisili)
                }
                FormField(label: "Kecamatan") {
                    TextField("Masukkan kecamatan", text: $vm.member.kecamatanDomisili)
                }
                FormField(label: "Kelurahan") {
                    TextField("Masukkan kelurahan", text: $vm.member.kelurahanDomisili)
                }
                FormField(label: "Kode Pos") {
                    TextField("Masukkan kode pos", text: $vm.member.kodePosDomisili)
                        .keyboardType(.numberPad)
                }
            }
        }
    }

    // MARK: - Simpan sebagai Draft button
    // Mirrors Android's btnSimpan → collectAndSave() → vm.saveAsDraft() → Toast → finish()

    private var btnSimpan: some View {
        Button {
            do {
                try vm.saveDraft()
                showToast = true
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    dismiss()
                }
            } catch {
                vm.errorMessage = error.localizedDescription
            }
        } label: {
            ZStack {
                if vm.isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Simpan sebagai Draft")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "#3D5A99"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(vm.isSaving)
    }

    // MARK: - Toast — "Tersimpan sebagai Draft"

    private var toastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
            Text("Tersimpan sebagai Draft")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "#1A7A3C"))
        .clipShape(Capsule())
        .shadow(radius: 8)
        .padding(.bottom, 90)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: showToast)
    }

    // MARK: - KTP photo button
    // Uses photo library icon — mirrors Android's gallery intent

    private func ktpPhotoButton(image: UIImage?, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                    VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundStyle(Color(hex: "#3D5A99"))
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(image != nil ? Color(hex: "#3D5A99") : Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

// MARK: - Reusable form components

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            content()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct FormField<Content: View>: View {
    let label: String
    var required: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 2) {
                Text(label).font(.subheadline.weight(.medium))
                if required { Text("*").foregroundStyle(.red) }
            }
            content()
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct FormPicker: View {
    let placeholder: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { selection = option }
            }
        } label: {
            HStack {
                Text(selection.isEmpty ? placeholder : selection)
                    .foregroundStyle(selection.isEmpty ? Color(.placeholderText) : .primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    MemberFormView(editingMember: nil)
        .environment(AppCoordinator())
}
