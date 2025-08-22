#!/bin/bash
set -e

mkdir -p app/src/main/java/com/example/app
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values

cat > app/build.gradle <<'EOG'
plugins {
    id 'com.android.application'
}

android {
    namespace "com.example.app"
    compileSdk 34

    defaultConfig {
        applicationId "com.example.app"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
}
EOG

echo "✅ Proyecto Android listo con build.gradle corregido"

# Generar wrapper de Gradle
gradle wrapper
chmod +x gradlew
echo "sdk.dir=$HOME/android-sdk" > local.properties

# Compilar APK en modo debug
./gradlew clean assembleDebug -Pandroid.aapt2FromMaven=true

# Ruta del APK generado
APK_PATH="$(pwd)/app/build/outputs/apk/debug/app-debug.apk"
echo "✅ APK generado en: $APK_PATH"

# Abrir instalador en Android (si se ejecuta en un dispositivo)
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW \
       -d "file://$APK_PATH" \
       -t "application/vnd.android.package-archive" || true
fi
