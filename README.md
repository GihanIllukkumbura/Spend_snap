# Project setup: Python virtualenv (myenv) and Flutter

This repository contains two main parts:

- `Python_API/` — Python backend including `requirements.txt`.
- `Mobile_APP/firebasefluttter/` — Flutter app.

This README explains how to create the Python virtual environment named `myenv` and how to get the Flutter project running. Commands below are for Windows PowerShell.

## 1) Create Python virtual environment (myenv)

Open PowerShell and run:

```powershell
cd .\Python_API
# Create a virtual environment named myenv
python -m venv myenv

# If ExecutionPolicy prevents running Activate.ps1 you can enable for this session:
# (runs only in the current PowerShell process)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Activate the venv (PowerShell)
.\myenv\Scripts\Activate.ps1

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Optional: save frozen requirements after install
pip freeze > requirements.txt
```

Notes:
- If you prefer cmd.exe activation, run `myenv\Scripts\activate.bat` instead.
- The virtualenv directory `Python_API/myenv/` is ignored by git (see `.gitignore`).

## 2) Setup and run the Flutter app

Prerequisites:
- Install Flutter SDK and add `flutter` to your PATH: https://docs.flutter.dev/get-started/install/windows
- Install Android SDK (for Android builds) and set up platform tools. For Windows desktop apps enable the Windows tooling.

From PowerShell:

```powershell
cd .\Mobile_APP\firebasefluttter

# Get Dart/Flutter packages
flutter pub get

# Run the app (specify device or platform). Example to run on Windows desktop:
flutter run -d windows

# To run on connected Android device or emulator:
# flutter run -d <device-id>

# Build an APK for distribution
# flutter build apk --release

# Build for iOS (macOS only):
# flutter build ios
```

Notes:
- The Flutter `.dart_tool/` and `build/` directories are ignored by git (see `.gitignore`).
- If you need to add Firebase or platform-specific keys, avoid committing secrets — add them to local-only files and list them in `.gitignore`.

## 3) Helpful tips
- Use the repo-level `.gitignore` to add any other local-only files you do not want to push.
- If PowerShell blocks activation, the temporary `Set-ExecutionPolicy` command above is safe and limited to the session.

If you want, I can also add a small script to automate venv creation & activation or add a VS Code recommended extensions file. What would you like next?
