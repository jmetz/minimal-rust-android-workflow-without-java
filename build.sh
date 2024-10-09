#!/bin/bash
# Load .env; this holds the following for signing: 
# * KEYSTORE_PATH
# * KEY_ALIAS
# * KEYSTORE_PASS
# * KEY_PASS
set -a && source ./.env && set +a
set -e

# Configuration variables
APP_NAME="MinimalAndroidWorkflowWithoutJava"
PACKAGE_NAME="com.example.minimal_android_workflow_without_java"
RUST_PACKAGE_NAME="minimal_android_workflow_without_java"
RUST_ANDROID_TARGET="aarch64-linux-android" # Can be adjusted (e.g., armv7, x86_64)
ANDROID_TARGET="arm64-v8a"
SDK_PATH="$HOME/android"

# NDK_VERSION="26.2.11394342" # Adjust as needed
NDK_VERSION="23.1.7779620"
OUTPUT_DIR="./output"
MIN_SDK_VERSION="28"
TARGET_SDK_VERSION="34"

# Paths to Android tools (ensure they're correct for your environment)
AAPT2="$SDK_PATH/build-tools/34.0.0/aapt2"
ZIPALIGN="$SDK_PATH/build-tools/34.0.0/zipalign"
PLATFORM="$SDK_PATH/platforms/android-31/android.jar"
APKSIGNER="$SDK_PATH/build-tools/34.0.0/apksigner"

# NativeActivity path from NDK
NATIVE_ACTIVITY_PATH="$SDK_PATH/ndk/$NDK_VERSION/sources/android/native_app_glue"

# Ensure the output directory exists
mkdir -p $OUTPUT_DIR

rm $OUTPUT_DIR/*.apk -f

# Step 1: Add Android target for Rust if it's not already added
rustup target add $RUST_ANDROID_TARGET

# Step 2: Build the Rust project for the specified Android target
cargo ndk -t $RUST_ANDROID_TARGET --platform $TARGET_SDK_VERSION build --release

# Step 3: Create the APK directory structure
mkdir -p $OUTPUT_DIR/app/lib/$ANDROID_TARGET
mkdir -p $OUTPUT_DIR/app/res
mkdir -p $OUTPUT_DIR/app/values
mkdir -p $OUTPUT_DIR/app/META-INF

echo "dummy thing" > $OUTPUT_DIR/app/res/textfile.txt

# Step 4: Copy the Rust compiled shared library to the APK lib folder
cp "target/$RUST_ANDROID_TARGET/release/lib$RUST_PACKAGE_NAME.so" "$OUTPUT_DIR/app/lib/$ANDROID_TARGET/"


        # <activity android:name="android.app.NativeActivity"
        #           android:exported="true"
        #           android:theme="@android:style/Theme.NoTitleBar.Fullscreen"
        #           android:configChanges="orientation|keyboardHidden">
    # <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="31"/>
    # package="$PACKAGE_NAME"
    # android:versionCode="1"
    # android:versionName="1.0">

# <?xml version="1.0" encoding="utf-8"?>
            # <meta-data android:name="android.app.lib_name" android:value="$RUST_PACKAGE_NAME"/>
# Step 5: Create a minimal AndroidManifest.xml
cat <<EOL > $OUTPUT_DIR/app/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME"
    android:versionCode="1"
    android:versionName="1.0">
    <uses-sdk android:minSdkVersion="$MIN_SDK_VERSION" android:targetSdkVersion="$TARGET_SDK_VERSION" />
    <application 
            android:label="$APP_NAME" 
            android:hasCode="false"
            >
        <activity android:name="android.app.NativeActivity"
                  android:exported="true"
                  android:configChanges="orientation|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            <meta-data 
                    android:name="android.app.lib_name" 
                    android:value="$RUST_PACKAGE_NAME"/>
        </activity>
    </application>
</manifest>
EOL

# Step 6: Create the resources (minimal example, adjust as needed)
cat <<EOL > $OUTPUT_DIR/app/values/strings.xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">$APP_NAME</string>
</resources>
EOL

# Step 7: Compile resources using aapt2
echo "Compiling resources..."
$AAPT2 compile --dir $OUTPUT_DIR/app/res -o $OUTPUT_DIR/resources.zip
# echo "Compiling manifest..."
# $AAPT2 compile $OUTPUT_DIR/AndroidManifest.xml -o $OUTPUT_DIR/app/AndroidManifest.xml


echo "Linking into apk"
# Step 8: Link the resources into a binary APK format
$AAPT2 link \
    -o $OUTPUT_DIR/$APP_NAME-unaligned.apk \
    -I $PLATFORM \
    -R $OUTPUT_DIR/resources.zip \
    --manifest $OUTPUT_DIR/app/AndroidManifest.xml \
    --auto-add-overlay
    # --proto-format
    # --java $OUTPUT_DIR/app \
    # --manifest $OUTPUT_DIR/compiled_manifest.zip \
# $AAPT2 convert

rm $OUTPUT_DIR/app/AndroidManifest.xml

echo "Zipping rust library into APK"
# Step 9: Add the compiled Rust library to the APK
cd $OUTPUT_DIR/app
zip -r ../$APP_NAME-unaligned.apk ./*
cd -

# Step 10: Align the APK using zipalign
$ZIPALIGN -v -p 4 $OUTPUT_DIR/$APP_NAME-unaligned.apk $OUTPUT_DIR/$APP_NAME.apk

echo "Signing..."
# Signing the APK using apksigner
$APKSIGNER sign \
    --ks $KEYSTORE_PATH \
    --ks-key-alias $KEY_ALIAS \
    --ks-pass pass:$KEYSTORE_PASS \
    --key-pass pass:$KEY_PASS \
    --out $OUTPUT_DIR/$APP_NAME-signed.apk \
    --min-sdk-version $MIN_SDK_VERSION \
    $OUTPUT_DIR/$APP_NAME.apk

# Final output
echo "APK created successfully: $OUTPUT_DIR/$APP_NAME-signed.apk"
