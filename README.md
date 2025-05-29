# CineCircle

## Description

The repository contains the source code of the CineCircle application.  
The CineCircle application allows you to search for movies or actors, mark your favorites and share your thoughts about a particular movie.

CineCircle is an iOS application developed with SwiftUI using Firebase Authentication for user sign-in and registration. It integrates external APIs and adheres to the MVVM architectural pattern. Dependency management is handled through the Swift Package Manager. Configuration of private API keys is managed via GYB templates in conjunction with a `.env` configuration file.

### This application uses TMDB and the TMDB APIs but is not endorsed, certified, or otherwise approved by TMDB.

### The app is under active development.

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
* In the root of your project, create a file named .env with your API key:
```
API_KEY=your_real_api_key_here
```
Make sure this file is never committed to Git — it’s already in .gitignore.

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
python3 "${SRCROOT}/gyb.py" -o "${SRCROOT}/CineCircleApp/APIManager/APIKeys.swift" "${SRCROOT}/Scripts/APIKeys.swift.gyb"
```

###4. Add gyb.py
Download gyb.py from Apple’s official Swift repo:
https://github.com/swiftlang/swift/blob/main/utils/gyb.py
Place it into your project root (CineCircle/gyb.py) and make it executable:
```
chmod +x gyb.py
```


###5. Install Python virtual environment
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

❗ Don’t commit .env or APIKeys.swift to Git for security reasons.

✅ You’re Ready!


## Authors

| Name | Github Contact |
|---------------------|--------------------|
| Yuliya Nastiushkina | @YuliaNastiushkina |

If you have any questions about the application, feel free to reach out via GitHub or email.
