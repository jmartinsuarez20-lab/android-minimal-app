#!/data/data/com.termux/files/usr/bin/bash
set -e

# -------- Config Android SDK en Termux --------
export ANDROID_HOME="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "🔧 Preparando entorno..."
pkg update -y && pkg upgrade -y
pkg install -y openjdk-17 wget unzip git gradle

# Instalar Commandline Tools + SDK si faltan
if ! command -v sdkmanager >/dev/null 2>&1; then
  mkdir -p "$ANDROID_HOME"
  cd "$ANDROID_HOME"
  wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip
  unzip -q -o cmdline-tools.zip
  mkdir -p cmdline-tools/latest
  mv cmdline-tools/* cmdline-tools/latest/ 2>/dev/null || true
  yes | sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
  yes | sdkmanager --licenses || true
fi

cd "$HOME/android-minimal-app"

echo "📂 Generando proyecto Ritsu IA..."
rm -rf app gradle .gradle build settings.gradle build.gradle
mkdir -p app/src/main/java/com/example/ritsuia
mkdir -p app/src/main/res/{drawable,layout,values}

# -------- Gradle (root) --------
cat > settings.gradle <<'EOG'
rootProject.name = "android-minimal-app"
include(":app")
EOG

cat > build.gradle <<'EOG'
buildscript {
  repositories { google(); mavenCentral() }
  dependencies { classpath "com.android.tools.build:gradle:8.1.4" }
}
allprojects {
  repositories { google(); mavenCentral() }
}
EOG

# -------- Gradle (app) SIN module() --------
apply plugin: 'com.android.application'

android {
  namespace "com.example.ritsuia"
  compileSdk 34

  defaultConfig {
    applicationId "com.example.ritsuia"
    minSdk 24
    targetSdk 34
    versionCode 1
    versionName "1.0"
    vectorDrawables.useSupportLibrary = true
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

# -------- AndroidManifest --------
cat > app/src/main/AndroidManifest.xml <<'EOG'
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  package="com.example.ritsuia">
  <application
    android:allowBackup="true"
    android:label="Ritsu IA"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar">
    <activity android:name=".SplashActivity">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
    <activity android:name=".MainActivity"/>
  </application>
</manifest>
EOG

# -------- Values --------
cat > app/src/main/res/values/strings.xml <<'EOG'
<resources>
  <string name="app_name">Ritsu IA</string>
</resources>
EOG

# -------- Layouts --------
cat > app/src/main/res/layout/activity_splash.xml <<'EOG'
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
  android:layout_width="match_parent"
  android:layout_height="match_parent"
  android:background="#FADADD">

  <ImageView
    android:id="@+id/ritsuImage"
    android:layout_width="220dp"
    android:layout_height="220dp"
    android:layout_centerInParent="true"
    android:src="@drawable/ritsu_splash"
    android:contentDescription="@string/app_name"
    android:scaleType="fitCenter"/>

  <TextView
    android:id="@+id/welcomeText"
    android:layout_width="wrap_content"
    android:layout_height="wrap_content"
    android:layout_below="@id/ritsuImage"
    android:layout_centerHorizontal="true"
    android:text="Bienvenida, Ritsu IA"
    android:textSize="22sp"
    android:textColor="#D81B60"
    android:alpha="0"/>
</RelativeLayout>
EOG

# -------- Fallback drawable kawaii (vector) --------
cat > app/src/main/res/drawable/ritsu_splash.xml <<'EOG'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
  android:width="220dp" android:height="220dp" android:viewportWidth="220" android:viewportHeight="220">
  <!-- fondo círculo pastel -->
  <path android:fillColor="#FFE4EC" android:pathData="M110,10a100,100 0 1,0 0,200a100,100 0 1,0 0,-200"/>
  <!-- estrella kawaii -->
  <path android:fillColor="#FFC1E3" android:pathData="M110,50 l15,40 h42 l-34,25 l13,40 l-36,-25 l-36,25 l13,-40 l-34,-25 h42z"/>
  <!-- carita simple -->
  <path android:fillColor="#D81B60" android:pathData="M85,110 a6,6 0 1,0 0.1,0 z"/>
  <path android:fillColor="#D81B60" android:pathData="M135,110 a6,6 0 1,0 0.1,0 z"/>
  <path android:fillColor="#D81B60" android:strokeWidth="4" android:strokeColor="#D81B60"
    android:fillAlpha="0" android:pathData="M90,135 Q110,148 130,135"/>
</vector>
EOG

# -------- Intento de descargar imagen (opcional) + validación --------
try_dl() {
  url="$1"
  out="app/src/main/res/drawable/ritsu_splash.png"
  echo "⬇️ Intentando descargar imagen: $url"
  if curl -L --max-time 15 --retry 2 --retry-delay 2 -o "$out" "$url"; then
    # archivo válido si pesa > 2KB
    if [ -s "$out" ] && [ "$(stat -c%s "$out" 2>/dev/null || stat -f%z "$out")" -gt 2048 ]; then
      echo "✅ Imagen descargada correctamente."
      return 0
    fi
  fi
  echo "⚠️ Descarga no válida. Se usará el vector kawaii de fallback."
  rm -f "$out" || true
  return 1
}

# Lista de URLs candidatas (si todas fallan, queda el vector)
# Nota: si alguna no está accesible en tu red, el fallback ya está listo.
URLS=(
  "https://images.unsplash.com/photo-1543589077-47d81606c1bf?auto=format&fit=crop&w=512&q=60"
  "https://upload.wikimedia.org/wikipedia/commons/3/33/Cartoon_Girl_Icon.png"
)
for u in "${URLS[@]}"; do try_dl "$u" && break; done || true

# -------- Clases Java --------
cat > app/src/main/java/com/example/ritsuia/SplashActivity.java <<'EOG'
package com.example.ritsuia;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.animation.AlphaAnimation;
import android.view.animation.TranslateAnimation;
import android.widget.ImageView;
import android.widget.TextView;

public class SplashActivity extends Activity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_splash);

    ImageView ritsuImage = findViewById(R.id.ritsuImage);
    TextView welcomeText = findViewById(R.id.welcomeText);

    TranslateAnimation slideUp = new TranslateAnimation(0, 0, 300, 0);
    slideUp.setDuration(800);
    ritsuImage.startAnimation(slideUp);

    AlphaAnimation fadeIn = new AlphaAnimation(0f, 1f);
    fadeIn.setDuration(900);
    fadeIn.setStartOffset(400);
    welcomeText.startAnimation(fadeIn);

    new Handler().postDelayed(() -> {
      startActivity(new Intent(SplashActivity.this, MainActivity.class));
      finish();
    }, 1500);
  }
}
EOG

cat > app/src/main/java/com/example/ritsuia/MainActivity.java <<'EOG'
package com.example.ritsuia;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.widget.TextView;
import android.view.Gravity;

public class MainActivity extends AppCompatActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    TextView tv = new TextView(this);
    tv.setText("Hola, soy Ritsu IA 💖");
    tv.setTextSize(24f);
    tv.setGravity(Gravity.CENTER);
    setContentView(tv);
  }
}
EOG

# -------- Proguard vacío --------
echo -n "" > app/proguard-rules.pro

# -------- Wrapper y compilación --------
echo "🧱 Preparando Gradle..."
gradle wrapper --gradle-version 8.2.1
chmod +x gradlew
echo "sdk.dir=$ANDROID_HOME" > local.properties

echo "🛠 Compilando APK..."
./gradlew --no-daemon clean assembleDebug -Pandroid.aapt2FromMaven=true

APK_PATH="$(pwd)/app/build/outputs/apk/debug/app-debug.apk"
echo "✅ APK generado en: $APK_PATH"

# -------- Lanzar instalador en Android --------
if command -v am >/dev/null 2>&1; then
  echo "📲 Abriendo instalador..."
  am start -a android.intent.action.VIEW \
     -d "file://$APK_PATH" \
     -t "application/vnd.android.package-archive" || true
else
  echo "ℹ️ Ejecuta este APK en tu dispositivo para instalarlo."
fi

echo "🎉 Listo: Ritsu IA con splash chibi animado."

# 🔹 Forzar build.gradle limpio
rm -f app/build.gradle
cat > app/build.gradle <<'EOG'
apply plugin: 'com.android.application'

android {
    namespace "com.example.ritsuia"
    compileSdk 34

    defaultConfig {
        applicationId "com.example.ritsuia"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
        vectorDrawables.useSupportLibrary = true
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

# 🔹 Compilar e instalar
./gradlew clean assembleDebug -Pandroid.aapt2FromMaven=true
APK_PATH="$(pwd)/app/build/outputs/apk/debug/app-debug.apk"
echo "✅ APK generado en: $APK_PATH"
if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW \
       -d "file://$APK_PATH" \
       -t "application/vnd.android.package-archive" || true
fi
