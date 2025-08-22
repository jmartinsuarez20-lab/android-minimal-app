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
