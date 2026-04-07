# Register Offline — iOS App

An iOS application for offline-first member registration. Data is saved locally first, then synchronized to the server when an internet connection is available.

---

## Tech Stack

| Layer | Library |
|-------|---------|
| Language | Swift |
| Architecture | MVVM + Repository Pattern |
| Local DB | SQLite3 (built-in) |
| Network | URLSession (native) |
| Secure Storage | Keychain Services |
| UI | SwiftUI |

---

## How to Run

1. Clone this repository
2. Open with **Xcode** (16 or newer)
3. Select a simulator or physical device from the scheme selector
4. Press **Cmd+R** to build and run (minOS iOS 17+)

> **API Base URL:** `https://api-test.partaiperindo.com/api/v1`

---

## Project Structure

```
Test Mobile iOS/
│
├── App/                    # AppCoordinator (navigation), Color extension
│
├── Core/
│   ├── Database/           # SQLite3 setup, DAO (CRUD operations)
│   ├── Keychain/           # JWT token storage via Keychain
│   ├── Network/            # URLSession client, endpoints, multipart builder
│   └── ImageCompressor     # Photo resize + JPEG compression
│
├── Domain/
│   ├── Models/             # Member, UserProfile, SyncStatus, SyncState
│   └── Repositories/       # AuthRepository, MemberRepository
│
└── Features/
    ├── Splash/             # Splash screen
    ├── Auth/               # Login, Profile
    ├── MemberForm/         # Member registration form + photo picker
    └── MemberList/         # Member list + synchronization
```

---

## Features

### Authentication
- Login with email & password (JWT stored securely in Keychain)
- Logout with confirmation dialog

### Member Registration Form (Offline)
- Identity fields: Full Name, NIK, Phone, Place & Date of Birth, Marital Status, Occupation
- KTP address & Domicile address (can be same as KTP)
- Pick primary & secondary KTP photos from gallery (automatically compressed before upload)
- Data is saved to local database with **Draft** status

### Member List & Synchronization
- **Draft** tab — shows local data not yet sent to the server
- **Uploaded** tab — shows data already sent to the server (fetched from API)
- **Upload All** button — sends all Draft records to the server one by one
- **Upload** button per item — uploads a single record directly from the list

### Image Optimization
- KTP photos are compressed to a maximum of 1024×1024 px at 70% JPEG quality before uploading

---

## Demo Flow

```
Splash Screen
  → Login
    → Main Screen (Draft tab — empty)
      → Add Data → fill form → Save as Draft
    → Main Screen (Draft appears in list)
      → Upload All → data sent to server
    → Uploaded tab → data fetched from API
```
