#!/data/data/com.termux/files/usr/bin/bash
set -e

GITHUB_USER="jmartinsuarez20-lab"
REPO_NAME="android-minimal-app"
REPO_SSH="git@github.com:$GITHUB_USER/$REPO_NAME.git"
ANDROID_HOME=$HOME/android-sdk
ANDROID_SDK_ROOT=$HOME/android-sdk
export ANDROID_HOME ANDROID_SDK_ROOT
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

pkg update -y && pkg upgrade -y
pkg install -y openjdk-17 wget unzip git gradle

if [ ! -d "$ANDROID_HOME" ]; then
    mkdir -p "$ANDROID_HOME"
    cd "$ANDROID_HOME"
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
    unzip -q cmdline-tools.zip
    mkdir -p cmdline-tools/latest
    mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
    yes | sdkmanager --sdk_root=$ANDROID_HOME "platform-tools" "platforms;android-34" "build-tools;34.0.0"
    yes | sdkmanager --licenses || true
fi

cd ~
rm -rf "$REPO_NAME"
mkdir -p "$REPO_NAME/app/src/main/java/com/example/minimalapp"
mkdir -p "$REPO_NAME/app/src/main/res/layout"
mkdir -p "$REPO_NAME/app/src/main/res/values"

cat > "$REPO_NAME/settings.gradle" <<EOG
rootProject.name = "$REPO_NAME"
include ':app'
EOG

cat > "$REPO_NAME/build.gradle" <<'EOG'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.4' }
}
allprojects {
    repositories { google(); mavenCentral() }
}
EOG

cat > "$REPO_NAME/app/build.gradle" <<'EOG'
plugins { id 'com.android.application' }
android {
    namespace 'com.example.minimalapp'
    compileSdk 34
    defaultConfig {
        applicationId "com.example.minimalapp"
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
}
EOG

cat > "$REPO_NAME/app/src/main/java/com/example/minimalapp/MainActivity.java" <<'EOG'
package com.example.minimalapp;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.widget.TextView;
public class MainActivity extends AppCompatActivity {
    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("Hola Jorge 👋, tu APK funciona!");
        tv.setTextSize(24);
        setContentView(tv);
    }
}
EOG

cat > "$REPO_NAME/app/src/main/AndroidManifest.xml" <<'EOG'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.minimalapp">
    <application
        android:allowBackup="true"
        android:label="MinimalApp"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOG

cat > "$REPO_NAME/app/src/main/res/layout/activity_main.xml" <<'EOG'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical">
    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Hola Jorge!"
        android:textSize="24sp"/>
</LinearLayout>
EOG

cat > "$REPO_NAME/app/src/main/res/values/strings.xml" <<'EOG'
<resources>
    <string name="app_name">MinimalApp</string>
</resources>
EOG

cd "$REPO_NAME"
gradle wrapper
chmod +x gradlew
echo "sdk.dir=$ANDROID_HOME" > local.properties

git init
git add .
git commit -m "Proyecto Android mínimo"
git branch -M main
git remote add origin "$REPO_SSH" || git remote set-url origin "$REPO_SSH"
git push -u origin main --force

./gradlew clean assembleDebug -Pandroid.aapt2FromMaven=true

APK_PATH="$(pwd)/app/build/outputs/apk/debug/app-debug.apk"
echo "✅ APK generado en: $APK_PATH"

am start -a android.intent.action.VIEW \
   -d "file://$APK_PATH" \
   -t "application/vnd.android.package-archive" || true
