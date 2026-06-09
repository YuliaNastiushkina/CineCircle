# 🎬 CineCircle

## Description

The repository contains the source code of the CineCircle application.  
CineCircle is an iOS app for discovering movies and TV shows, tracking watched titles and episodes, saving favorites, and writing personal notes. Explore genres, view cast details, and manage your media library from one profile.

## 🛠️ Tech Stack
- **SwiftUI** — user interface framework  
- **SwiftData** — local persistence  
- **Firebase Authentication** — user sign-in and registration  
- **External APIs (TMDB)** — movie data source  
- **MVVM** — architectural pattern  
- **Swift Package Manager (SPM)** — dependency management  
- **GYB + `.env`** — secure API keys configuration
## 📱 Screenshots

### Main Screen
<p align="center">
    <img src="https://github.com/user-attachments/assets/3f0d06b6-7e82-4b3d-99f9-46c665e9f8c8" alt="screen1" width="220">
    <img src="https://github.com/user-attachments/assets/7ddcbb9b-1876-4556-a9c8-0598df7cc7ed" alt="screen2" width="220">
</p>

<details>
    <summary><strong>▶️ View more screens inside the app</strong></summary>

<br>
    
<p align="center">
<img src="https://github.com/user-attachments/assets/a055d3a4-27cd-4986-8b81-370a710a5f78" alt="screen3" width="180"/>
    
<img src="https://github.com/user-attachments/assets/1a56df13-db4a-4913-8e37-8d22549d7240" alt="screen4" width="180"/>
    
<img src="https://github.com/user-attachments/assets/5f59fec2-1f77-41c7-9f65-219a53222536" alt="screen5" width="180"/>
    
<img src="https://github.com/user-attachments/assets/9a9ae7c0-7514-4ed1-b231-0588ae209907" alt="screen6" width="180"/>
</p>
</details>

### The app is under active development.

### ❗️This application uses TMDB and the TMDB APIs but is not endorsed, certified, or otherwise approved by TMDB.❗️

## Badges

Versions of our environment:

![Swift](https://img.shields.io/badge/Swift-6.1-blueviolet) ![macOS](https://img.shields.io/badge/macOS-15.4+-green) ![Xcode](https://img.shields.io/badge/Xcode-16.3-blue) ![SwiftFormat](https://img.shields.io/badge/SwiftFormat-0.54.2-yellow) ![SwiftLint](https://img.shields.io/badge/SwiftLint-0.55.1-orange)
    ![Python](https://img.shields.io/badge/Python-3.10+-pink)

## Additional info

* Deployment target for iOS SDKs - 18.0+
* Supported devices - iPhone
*  Firebase Authentication is already set up in the project.  
If you plan to use your own Firebase project, replace `GoogleService-Info.plist` with your own configuration file from the Firebase Console.

## 🚀 Launch CineCircle
<details>
    <summary> Launch Instructions </summary>
    
### 1. Clone the Repository
```
git clone git@github.com:YuliaNastiushkina/CineCircle.git

cd CineCircle
```

### 2. Open the project: 
```
open CineCircleApp.xcodeproj
```

### 3. Set Up API Key Generation
* In the root of your project, create a file named `.env` with your API key:
```
API_KEY=your_real_api_key_here
```
*Make sure this file is never committed to Git.*

* Create the generate_keys.sh Script
Create this file at Scripts/generate_keys.sh:

```
#!/bin/bash

# Set project root (change to actual project path or use relative path)
SRCROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV_PATH="${SRCROOT}/.venv"
ENV_PATH="${SRCROOT}/.env"

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_PATH" ]; then
    echo "No virtual environment found. Creating..."
    python3 -m venv "$VENV_PATH"
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"

# Load .env variables
if [ -f "$ENV_PATH" ]; then
    export $(grep -v '^#' "$ENV_PATH" | xargs)
else
    echo ".env file not found."
fi

# Run GYB
python3 "${SRCROOT}/gyb.py" -o "${SRCROOT}/CineCircleApp/Services/API/APIKeys.swift" "${SRCROOT}/Scripts/APIKeys.swift.gyb"
```

### 4. Add `gyb.py`
Download gyb.py from Apple’s official [Swift repository](https://github.com/swiftlang/swift/blob/main/utils/gyb.py).

Place it into your project root (CineCircle/gyb.py) and make it executable:
```
chmod +x gyb.py
```


### 5. Install Python virtual environment
```
python3 -m venv .venv
source .venv/bin/activate
pip install python-dotenv
```

### 6. Then make generate_keys.sh executable:
```
chmod +x Scripts/generate_keys.sh
```

Run the script:
```
Scripts/generate_keys.sh
```

This will generate APIKeys.swift based on the obfuscated value of your API key.

❗ Don’t commit `.env` or `APIKeys.swift` to Git for security reasons.

✅ You’re Ready!
</details>

## Authors

| Name | Github Contact |
|---------------------|--------------------|
| Yuliya Nastiushkina | @YuliaNastiushkina |

If you have any questions about the application, feel free to reach me out.
