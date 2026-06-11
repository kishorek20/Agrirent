# 🌾 AgriRent — Smart Agriculture Vehicle Rental Platform

A full-stack Flutter mobile application connecting **farmers** who need agricultural vehicles with **owners** who list them for rent, managed by an **admin** portal.

---

## 📱 App Screenshots Overview

| Farmer Portal | Owner Portal | Admin Dashboard |
|---|---|---|
| Browse Vehicles | List Vehicles | Approve Listings |
| Book Vehicles | Manage Bookings | Monitor Platform |
| Booking History | Track Earnings | Analytics Charts |

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Mobile Framework | Flutter 3.x (Dart 3.x) |
| Backend | Supabase (PostgreSQL + Auth + Storage) |
| State Management | Provider (ChangeNotifier) |
| Navigation | GoRouter 13.x |
| UI Theme | Material 3 – Green Agriculture |
| Charts | fl_chart |
| Images | cached_network_image + image_picker |

---

## 📁 Project Structure

```
agrirent/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── vehicle_model.dart
│   │   ├── booking_model.dart
│   │   ├── review_model.dart
│   │   └── payment_model.dart
│   ├── services/
│   │   ├── supabase_service.dart        # Auth + Supabase client
│   │   ├── vehicle_service.dart         # Vehicle CRUD
│   │   ├── booking_service.dart         # Booking CRUD
│   │   └── review_service.dart          # Review CRUD
│   ├── providers/
│   │   └── auth_provider.dart           # Auth state (ChangeNotifier)
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── farmer/
│   │   │   ├── farmer_home_screen.dart
│   │   │   ├── search_vehicles_screen.dart
│   │   │   ├── vehicle_detail_screen.dart
│   │   │   ├── book_vehicle_screen.dart
│   │   │   ├── booking_history_screen.dart
│   │   │   └── farmer_profile_screen.dart
│   │   ├── owner/
│   │   │   ├── owner_home_screen.dart
│   │   │   ├── add_vehicle_screen.dart
│   │   │   ├── edit_vehicle_screen.dart
│   │   │   ├── manage_bookings_screen.dart
│   │   │   ├── earnings_screen.dart
│   │   │   └── owner_profile_screen.dart
│   │   └── admin/
│   │       ├── admin_home_screen.dart
│   │       ├── manage_users_screen.dart
│   │       ├── manage_vehicles_screen.dart
│   │       ├── view_bookings_screen.dart
│   │       └── analytics_screen.dart
│   ├── widgets/
│   │   ├── custom_text_field.dart
│   │   ├── loading_button.dart
│   │   ├── vehicle_card.dart
│   │   ├── booking_status_chip.dart
│   │   ├── section_header.dart
│   │   └── stat_card.dart
│   └── utils/
│       ├── constants.dart               # ⚠️ Add your Supabase keys here
│       ├── app_theme.dart
│       └── app_router.dart
├── assets/
│   ├── images/
│   └── icons/
├── android/                             # Android native config
├── supabase_schema.sql                  # Run this in Supabase SQL Editor
├── pubspec.yaml
└── README.md
```

---

## ⚡ Quick Start (5 Steps)

### Step 1 — Prerequisites

```bash
flutter doctor   # must show ✓ Flutter, ✓ Android toolchain
```

Required:
- Flutter SDK ≥ 3.0.0
- Android Studio with Android SDK (API 21+)
- A [Supabase](https://supabase.com) account (free tier works)

---

### Step 2 — Supabase Setup

1. Go to **https://supabase.com** → create a new project
2. Open **SQL Editor** → paste and run the full contents of `supabase_schema.sql`
3. Go to **Settings → API** and copy:
   - **Project URL** → e.g. `https://abcxyz.supabase.co`
   - **anon public** key

---

### Step 3 — Configure the App

Open `lib/utils/constants.dart` and replace the two placeholders:

```dart
static const String supabaseUrl     = 'https://YOUR_PROJECT_ID.supabase.co';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

---

### Step 4 — Install & Run

```bash
flutter pub get
flutter run
```

For a specific device:
```bash
flutter devices               # list available
flutter run -d emulator-5554
```

---

### Step 5 — Create Demo Accounts

Register three accounts in the app:

| Role | Email | Password |
|------|-------|----------|
| Farmer | farmer@agrirent.com | demo@1234 |
| Owner | owner@agrirent.com | demo@1234 |
| Admin | admin@agrirent.com | demo@1234 |

Then promote the admin in Supabase SQL Editor:
```sql
UPDATE public.users SET role = 'admin' WHERE email = 'admin@agrirent.com';
```

---

## 🧩 Features

### 👨‍🌾 Farmer Portal
- Browse all approved & available vehicles
- Filter by type, city, price
- Full-text search
- View vehicle details with photo gallery
- Book vehicles with date picker
- Booking price calculator (subtotal + 5% GST)
- Booking history with status tabs
- Cancel pending bookings
- Profile management

### 🚜 Owner Portal
- Dashboard with vehicle stats
- Add new vehicles (full form with features)
- Edit existing listings
- Toggle vehicle availability
- Manage bookings — Confirm / Reject / Activate / Complete
- Earnings dashboard with monthly bar chart
- Profile management

### 🛡 Admin Dashboard
- Overview stats (vehicles, bookings, revenue)
- Manage all users — activate / deactivate
- Approve / reject vehicle listings
- View all bookings with status filter
- Platform analytics — line chart, pie chart, highlights

---

## 🏗 Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK (for distribution)
flutter build apk --release

# App Bundle (for Google Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔧 Troubleshooting

| Problem | Fix |
|---------|-----|
| Gradle build fails | `flutter clean && flutter pub get` |
| Supabase 401 error | Check your URL and anon key in `constants.dart` |
| minSdkVersion error | Ensure `minSdkVersion 21` in `android/app/build.gradle` |
| Blank screen on launch | Check Supabase project is not paused (free tier auto-pauses) |
| Images not loading | Verify storage bucket RLS policies in Supabase |

---

## 📌 Environment

- **Min Android SDK**: API 21 (Android 5.0 Lollipop)
- **Target Android SDK**: API 34 (Android 14)
- **Flutter**: 3.x
- **Dart**: 3.x

---

## 📄 License

MIT License — Free to use for educational and commercial projects.

---

*Built with ❤️ for Indian Farmers 🌾*
