# Register Offline — iOS App

An iOS application for **offline-first member registration**. Data is saved locally first, then synchronized to the server when an internet connection is available.

**API Base URL:** `https://api-test.partaiperindo.com/api/v1`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.0 |
| UI Framework | SwiftUI |
| Architecture | MVVM + Repository Pattern |
| Local Database | SQLite3 (built-in, no external packages) |
| Secure Storage | Keychain Services (JWT token) |
| Network | URLSession (native) |
| Image Compression | UIGraphicsImageRenderer — max 1024×1024 px, 70% JPEG quality |
| Connectivity | NWPathMonitor (Network framework) |
| Minimum iOS | iOS 17+ |

---

## Features

1. **Splash Screen** — 1.5s display, auto-routes to Login or Main based on saved session
2. **Authentication**
   - Login with email & password
   - JWT token stored securely in Keychain
   - Profile fetched and cached locally after login
3. **Profile**
   - Displays full name & email
   - Logout with confirmation dialog (warns about unsaved drafts)
4. **Offline Member Registration Form**
   - Identity: Name, NIK (16 digits), Phone, Birth Place & Date, Gender, Marital Status, Occupation
   - KTP Address: Full address, Province, City/Regency, District, Sub-district, Postal Code
   - Domicile Address: Toggle same-as-KTP or fill separately
   - KTP Photos: Pick from photo gallery for primary & secondary (with review screen and quality indicator)
   - Saved locally as **Draft** — no internet required
5. **Member List & Sync**
   - **Draft tab** — local unsent records, Edit & individual Upload per item
   - **Sudah Di-Upload tab** — records fetched from server
   - **Upload Semua** — bulk sync all drafts one-by-one with progress counter (`Mengupload X/N...`)
   - Confirmation dialog before bulk upload
6. **Image Optimization**
   - Resized to max 1024×1024 px before compression
   - Compressed at 70% JPEG quality
   - Adaptive quality reduction loop if still above 500 KB

---

## Project Structure

```
Test Mobile iOS/
├── App/
│   ├── AppCoordinator.swift        # Root navigation state (splash/login/main/profile)
│   └── ColorExtension.swift        # Color(hex:) SwiftUI helper
├── Core/
│   ├── Database/
│   │   ├── DatabaseManager.swift   # SQLite3 setup — creates identity_data table
│   │   └── MemberDAO.swift         # Full CRUD — insert, update, fetch, markAsSynced, delete
│   ├── Keychain/
│   │   └── KeychainService.swift   # JWT token save/get/delete via Keychain
│   ├── Network/
│   │   ├── APIClient.swift         # URLSession JSON requests + multipart/form-data builder
│   │   ├── APIEndpoints.swift      # Base URL and all endpoint constants
│   │   └── NetworkMonitor.swift    # NWPathMonitor — publishes isConnected boolean
│   └── ImageCompressor.swift       # Resize to 1024×1024, compress to 70% JPEG
├── Domain/
│   ├── Models/
│   │   ├── Member.swift            # Local member model (maps to identity_data table)
│   │   ├── UserProfile.swift       # Profile API response model
│   │   ├── SyncStatus.swift        # Enum: "Draft" / "Synced"
│   │   └── SyncState.swift         # Enum: idle / inProgress(done,total) / done(synced,total)
│   └── Repositories/
│       ├── AuthRepository.swift    # Login, fetchProfile, getCachedUser, isLoggedIn, logout
│       └── MemberRepository.swift  # saveDraft, uploadMember, uploadAllDrafts, getServerMembers
├── Features/
│   ├── Splash/
│   │   └── SplashView.swift        # 1.5s delay → route based on isLoggedIn()
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── LoginViewModel.swift    # AuthUiState: idle / loading / success / error
│   ├── MemberList/
│   │   ├── MemberListView.swift    # Draft + Sudah Di-Upload tabs, bulk upload UI
│   │   └── MemberListViewModel.swift
│   ├── MemberForm/
│   │   ├── MemberFormView.swift    # Full scrollable form with 4 sections
│   │   ├── MemberFormViewModel.swift
│   │   └── KTPCameraView.swift     # Camera capture → photo review → quality check
│   └── Profile/
│       ├── ProfileView.swift       # Name, email, logout menu
│       └── ProfileViewModel.swift
└── Test_Mobile_iOSApp.swift        # @main App entry point
```

---

## How to Run

### Requirements

- Xcode 16 or later
- iOS 17+ simulator or physical device
- Camera capture requires a **physical device** (simulator uses photo library as fallback)

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/ivlie1495/test-mobile-app-ios
   cd "Test Mobile iOS"
   ```

2. **Open in Xcode**
   ```bash
   open "Test Mobile iOS.xcodeproj"
   ```

3. **Select target** — pick a simulator or connected device from the scheme selector

4. **Build & Run** — press `Cmd+R`

> **No external packages required.** The project uses only Apple's built-in frameworks:
> `SQLite3`, `Security`, `Network`, `AVFoundation`, `UIKit`, `SwiftUI`

---

## Architecture

```
┌─────────┐     ┌────────────┐     ┌──────────────┐     ┌────────────┐
│  View   │────▶│ ViewModel  │────▶│  Repository  │────▶│    DAO     │
│(SwiftUI)│     │(@Observable│     │  (Business   │     │ (SQLite3)  │
│         │     │  + State)  │     │    Logic)    │     └────────────┘
└─────────┘     └────────────┘     │              │     ┌────────────┐
                                   │              │────▶│ APIClient  │
                                   └──────────────┘     │(URLSession)│
                                                        └────────────┘
```

- **View** — SwiftUI views, reads state from ViewModel via `@Observable`
- **ViewModel** — owns UI state, calls Repository, no direct DB/network access
- **Repository** — coordinates local DB and remote API, single source of truth
- **DAO** — raw SQLite3 queries against `testmobile.db`
- **APIClient** — generic URLSession wrapper + multipart/form-data body builder

---

## Database Schema

Table: `identity_data` (mirrors Android's `IdentityEntity`)

| Column | Type | Description |
|---|---|---|
| `id` | INTEGER PK | Auto-increment local ID |
| `nama` | TEXT | Full name |
| `nik` | TEXT | 16-digit ID number |
| `telepon` | TEXT | Phone number |
| `tempat_lahir` | TEXT | Birth place |
| `tanggal_lahir` | TEXT | Birth date (DD/MM/YYYY stored, YYYY-MM-DD sent to API) |
| `jenis_kelamin` | TEXT | Gender |
| `status_pernikahan` | TEXT | Marital status |
| `pekerjaan` | TEXT | Occupation |
| `alamat_ktp` | TEXT | KTP full address |
| `provinsi_ktp` | TEXT | KTP province |
| `kota_ktp` | TEXT | KTP city/regency |
| `kecamatan_ktp` | TEXT | KTP district |
| `kelurahan_ktp` | TEXT | KTP sub-district |
| `kode_pos_ktp` | TEXT | KTP postal code |
| `sama_ktp` | INTEGER | 1 = domicile same as KTP |
| `alamat_domisili` | TEXT | Domicile address fields (×5) |
| `foto_ktp_utama` | TEXT | Local file path — primary KTP photo |
| `foto_ktp_pendukung` | TEXT | Local file path — secondary KTP photo |
| `status_form` | TEXT | `"Draft"` or `"Synced"` |
| `created_at` | INTEGER | Unix timestamp ms |
| `updated_at` | INTEGER | Unix timestamp ms |

---

## API Endpoints

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/login` | — | Login, returns JWT token |
| `GET` | `/profile` | Bearer | Fetch logged-in user profile |
| `POST` | `/member` | Bearer | Upload member (`multipart/form-data`) |
| `GET` | `/member` | Bearer | Fetch list of uploaded members |

---

## Offline-First Flow

```
[Fill Form] ──▶ Save to SQLite (status_form = "Draft")
                        │
                        │  (internet available)
                        ▼
              Tap Upload / Upload Semua
                        │
                        ▼
             POST /member (multipart/form-data)
             ├── Text fields (name, nik, phone, ...)
             ├── ktp_file      (compressed JPEG ≤ 500 KB)
             └── ktp_file_secondary (compressed JPEG ≤ 500 KB)
                        │
                  ┌─────┴──────┐
               Success        Failure
                  │               │
                  ▼               ▼
        status_form = "Synced"  Keep "Draft"
        Moves to "Sudah Di-Upload" tab
```

---

## Video Demo

> Screen recording showing the full flow:
> **Offline Input → List Member (Draft) → Koneksi Aktif → Sync Success**

_(Attach screen recording file here)_

---

## Submission Checklist

- [x] Login with email & password, JWT stored in Keychain
- [x] Profile screen showing full name & email
- [x] Logout with session clearing and confirmation dialog
- [x] Offline member registration form (all required fields)
- [x] KTP photo capture with review screen and quality indicator
- [x] Image compression — max 1024×1024 px, 70% JPEG
- [x] Local SQLite3 database with Draft status flag
- [x] Draft list with Edit & individual Upload
- [x] Bulk sync — upload all drafts one-by-one with progress
- [x] Synced items shown in "Sudah Di-Upload" tab
- [x] MVVM + Repository architecture
- [x] README with run instructions and project structure
