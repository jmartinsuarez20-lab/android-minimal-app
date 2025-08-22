#!/bin/bash
set -e

# Crear carpetas necesarias
mkdir -p app/src/main/java/com/example/ritsuia
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values

# Descargar imagen chibi Ritsu
wget -O app/src/main/res/drawable/ritsu_splash.png "https://www.clipartmax.com/png/middle/m2H7i8m2i8i8m2G6_chibi-ritsu-k-on-ritsu-chibi.png"

# build.gradle
cat > app/build.gradle <<'EOG'
plugins { id 'com.android.application' }
android {
    namespace "com.example.ritsuia"
    compileSdk 34
    defaultConfig {
        applicationId "com.example.ritsuia"
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

# Layout del splash
cat > app/src/main/res/layout/activity_splash.xml <<'EOL'
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#FADADD">

    <ImageView
        android:id="@+id/ritsuImage"
        android:layout_width="200dp"
        android:layout_height="200dp"
        android:layout_centerInParent="true"
        android:src="@drawable/ritsu_splash"
        android:scaleType="fitCenter"/>

    <TextView
        android:id="@+id/welcomeText"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@id/ritsuImage"
        android:layout_centerHorizontal="true"
        android:text="Bienvenida, Ritsu IA"
        android:textSize="24sp"
        android:textColor="#D81B60"
        android:alpha="0"/>
</RelativeLayout>
EOL

# SplashActivity con animación
cat > app/src/main/java/com/example/ritsuia/SplashActivity.java <<'EOL'
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

        AlphaAnimation fadeIn = new AlphaAnimation(0, 1);
        fadeIn.setDuration(1000);
        fadeIn.setStartOffset(500);
        welcomeText.startAnimation(fadeIn);

        new Handler().postDelayed(() -> {
            startActivity(new Intent(SplashActivity.this, MainActivity.class));
            finish();
        }, 1500);
    }
}
EOL

# MainActivity
cat > app/src/main/java/com/example/ritsuia/MainActivity.java <<'EOL'
package com.example.ritsuia;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("Hola Jorge, soy Ritsu IA 💖");
        tv.setTextSize(24);
        setContentView(tv);
    }
cd ~ && \
rm -rf android-minimal-app && \
git clone git@github.com:jmartinsuarez20-lab/android-minimal-app.git && \
cd android-minimal-app && \
git config user.name "jmartinsuarez20-lab" && \
git config user.email "jmartinsuarez20@gmail.com" && \
cat > auto_android_build.sh <<'EOF'
#!/bin/bash
set -e

# Crear carpetas necesarias
mkdir -p app/src/main/java/com/example/ritsuia
mkdir -p app/src/main/res/drawable
mkdir -p app/src/main/res/layout
mkdir -p app/src/main/res/values

# Descargar imagen chibi Ritsu
wget -O app/src/main/res/drawable/ritsu_splash.png "https://www.clipartmax.com/png/middle/m2H7i8m2i8i8m2G6_chibi-ritsu-k-on-ritsu-chibi.png"

# build.gradle
cat > app/build.gradle <<'EOG'
plugins { id 'com.android.application' }
android {
    namespace "com.example.ritsuia"
    compileSdk 34
    defaultConfig {
        applicationId "com.example.ritsuia"
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

# Layout del splash
cat > app/src/main/res/layout/activity_splash.xml <<'EOL'
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#FADADD">

    <ImageView
        android:id="@+id/ritsuImage"
        android:layout_width="200dp"
        android:layout_height="200dp"
        android:layout_centerInParent="true"
        android:src="@drawable/ritsu_splash"
        android:scaleType="fitCenter"/>

    <TextView
        android:id="@+id/welcomeText"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@id/ritsuImage"
        android:layout_centerHorizontal="true"
        android:text="Bienvenida, Ritsu IA"
        android:textSize="24sp"
        android:textColor="#D81B60"
        android:alpha="0"/>
</RelativeLayout>
EOL

# SplashActivity con animación
cat > app/src/main/java/com/example/ritsuia/SplashActivity.java <<'EOL'
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

        AlphaAnimation fadeIn = new AlphaAnimation(0, 1);
        fadeIn.setDuration(1000);
        fadeIn.setStartOffset(500);
        welcomeText.startAnimation(fadeIn);

        new Handler().postDelayed(() -> {
            startActivity(new Intent(SplashActivity.this, MainActivity.class));
            finish();
        }, 1500);
    }
}
EOL

# MainActivity
cat > app/src/main/java/com/example/ritsuia/MainActivity.java <<'EOL'
package com.example.ritsuia;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("Hola Jorge, soy Ritsu IA 💖");
        tv.setTextSize(24);
        setContentView(tv);
    }
}
EOL

# AndroidManifest
cat > app/src/main/AndroidManifest.xml <<'EOL'
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
EOL

# Gradle wrapper y compilación
gradle wrapper
chmod +x gradlew
echo "sdk.dir=$HOME/android-sdk" > local.properties
./gradlew clean assembleDebug -Pandroid.aapt2FromMaven=true

APK_PATH="$(pwd)/app/build/outputs/apk/debug/app-debug.apk"
echo "✅ APK generado en: $APK_PATH"

if command -v am >/dev/null 2>&1; then
    am start -a android.intent.action.VIEW \
       -d "file://$APK_PATH" \
       -t "application/vnd.android.package-archive" || true
fi
