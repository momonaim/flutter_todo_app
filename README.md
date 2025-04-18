# 📝 Daily To-Do App

A simple and elegant cross-platform To-Do app built with Flutter.  
Supports both **desktop (Windows/Linux/macOS)** and **mobile (Android/iOS)** platforms.

## ✨ Features

- ✅ Add, check, and delete daily to-dos
- 📅 Select date to view tasks for a specific day
- 🗃️ Local storage using **SQLite**
  - Uses `sqflite` on mobile
  - Uses `sqflite_common_ffi` on desktop
- 🔔 Daily reminders via **local notifications**
- 💾 Tasks are stored per day and persist between sessions
- 🖥️ Custom window sizing & centering on desktop with `window_manager`

## 📸 Screenshots

| Android                                        | Desktop                                        |
| ---------------------------------------------- | ---------------------------------------------- |
| ![android screenshot](screenshots/android.png) | ![desktop screenshot](screenshots/desktop.png) |

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/momonaim/flutter_todo_app.git
cd flutter_todo_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

- **Mobile (Android/iOS):**

```bash
flutter run
```

- **Desktop (Windows/Linux/macOS):**

```bash
flutter config --enable-windows-desktop  # or macos/linux
flutter run -d windows
```

---

## ⚙️ Platform-specific Notes

### ✅ Android/iOS

- Uses `sqflite` for SQLite.
- Uses `flutter_local_notifications` for notifications.

### 💻 Desktop (Windows/Linux/macOS)

- Uses `sqflite_common_ffi` for SQLite.
- Uses `window_manager` for controlling window size and position.

> 💡 `WidgetsFlutterBinding.ensureInitialized()` is used **before** setting the window manager or initializing the database.

---

## 📂 Project Structure

```
lib/
├── db/
│   └── database_helper.dart     # Handles SQLite init/queries
├── models/
│   └── todo.dart                # To-do model
├── screens/
│   └── home_screen.dart         # Main UI
├── utils/
│   └── notification_helper.dart # Local notifications
└── main.dart                    # Entry point
```

---

## 📦 Dependencies

| Package                       | Usage                                            |
| ----------------------------- | ------------------------------------------------ |
| `sqflite`                     | SQLite on mobile                                 |
| `sqflite_common_ffi`          | SQLite on desktop                                |
| `flutter_local_notifications` | Local daily reminders                            |
| `window_manager`              | Custom window position and sizing (desktop only) |
| `timezone`                    | Timezone support for accurate notifications      |

---

## 📤 Export Feature (Coming Soon)

Planned for future version:

- Export tasks as `.json` for backup or sharing
- Sync across devices via cloud integration

---

## 🧪 Testing

To run unit or widget tests:

```bash
flutter test
```

---

## 📃 License

This project is licensed under the [MIT License](LICENSE).

---

## 🙌 Credits

Built with 💚 using [Flutter](https://flutter.dev)  
Inspired by the need to manage daily tasks easily across platforms.

---

## 📫 Contact

Have feedback or want to contribute?  
Open an issue or reach out at [your.email@example.com](mailto:your.email@example.com)
