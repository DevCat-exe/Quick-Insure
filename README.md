# Quick Insure

**Quick Insure** is a Flutter insurance calculator for Android and Windows. It helps users calculate premiums with a clean interface and supports offline calculations.

The app currently supports **Motor Insurance**, **Fire Insurance**, and
**Overseas Mediclaim**.

---

## Screenshots

| Home (Light Mode)               | Home (Dark Mode)               |
| ------------------------------- | ------------------------------ |
| ![](screenshots/home_light.png) | ![](screenshots/home_dark.png) |

| Motor Insurance Calculator      | Fire Insurance Calculator      | Calculation History          |
| ------------------------------- | ------------------------------ | ---------------------------- |
| ![](screenshots/motor_calc.png) | ![](screenshots/fire_calc.png) | ![](screenshots/history.png) |

---

## 🚀 Download

Every release is published on the [releases page](https://github.com/DevCat-exe/Quick-Insure/releases/latest).

| Platform            | Download                                                                                                                             |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Android             | [quick_insure.apk](https://github.com/DevCat-exe/Quick-Insure/releases/latest/download/quick_insure.apk)                             |
| Windows (installer) | [quick_insure_windows_setup.exe](https://github.com/DevCat-exe/Quick-Insure/releases/latest/download/quick_insure_windows_setup.exe) |
| Windows (portable)  | [quick_insure_windows.zip](https://github.com/DevCat-exe/Quick-Insure/releases/latest/download/quick_insure_windows.zip)             |

The Windows installer adds Start Menu and optional desktop shortcuts and can be removed from Windows Settings.
The portable ZIP only needs to be unpacked, then `quick_insure.exe` can be run from that folder.

---

## ✨ Features

- **Motor Insurance Calculator**  
  Calculate premiums with accurate breakdowns and instant results

- **Fire Insurance Calculator**  
  Zone-based property insurance with multiple risk options (Fire, Earthquake, Cyclone, Flood)
  and individual premium breakdowns

- **Overseas Mediclaim Calculator**
  Calculate travel premiums using Plan A or Plan C tariffs, traveller age, trip duration,
  and destination, with country suggestions and coverage validation

- **Calculation History**  
  Automatically saves previous calculations for quick reference

- **Light & Dark Mode**  
  Seamless theme switching with a polished UI

- **Clean UX**  
  Minimal design, smooth transitions, and intuitive navigation

---

## Tech Stack

| Category  | Technologies                                        |
| --------- | --------------------------------------------------- |
| Framework | Flutter                                             |
| Language  | Dart                                                |
| UI        | Material Design, Custom Animations                  |
| State     | Local state management                              |
| Platform  | Android (APK), Windows (installer and portable ZIP) |

## 📦 Getting Started

```bash
# Clone the repository
git clone https://github.com/DevCat-exe/Quick-Insure.git

# Install dependencies
flutter pub get

# Run the app
flutter run
```

**Prerequisites**

- Flutter SDK (stable)
- Android Studio or VS Code
- Android emulator or physical device

---
