#!/usr/bin/env python3
"""Idempotent Android configuration for Англисиро Омӯз."""

from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
APP_GRADLE = ANDROID / "app" / "build.gradle.kts"
MANIFEST = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
STRINGS = ANDROID / "app" / "src" / "main" / "res" / "values" / "strings.xml"
COLORS = ANDROID / "app" / "src" / "main" / "res" / "values" / "colors.xml"
STYLES = ANDROID / "app" / "src" / "main" / "res" / "values" / "styles.xml"
LAUNCH = ANDROID / "app" / "src" / "main" / "res" / "drawable" / "launch_background.xml"

APP_ID = "tj.mzaynuddinov.english_kids"
APP_LABEL = "Англисиро Омӯз"

PERMISSIONS = [
    "android.permission.POST_NOTIFICATIONS",
    "android.permission.SCHEDULE_EXACT_ALARM",
    "android.permission.USE_EXACT_ALARM",
    "android.permission.RECEIVE_BOOT_COMPLETED",
    "android.permission.WAKE_LOCK",
    "android.permission.VIBRATE",
    "android.permission.FOREGROUND_SERVICE",
]

ALARM_SNIPPET = """
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""

QUERIES_SNIPPET = """
        <intent>
            <action android:name="android.intent.action.TTS_SERVICE" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="http" />
        </intent>
        <intent>
            <action android:name="android.intent.action.DIAL" />
            <data android:scheme="tel" />
        </intent>
        <intent>
            <action android:name="android.intent.action.SENDTO" />
            <data android:scheme="mailto" />
        </intent>
"""


def patch_gradle() -> None:
    text = APP_GRADLE.read_text(encoding="utf-8")
    text = re.sub(r'namespace\s*=\s*"[^"]+"', f'namespace = "{APP_ID}"', text)
    text = re.sub(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{APP_ID}"', text)
    text = re.sub(r"minSdk\s*=\s*[^\n]+", "minSdk = 24", text)

    if "isCoreLibraryDesugaringEnabled" not in text:
        text = text.replace(
            "compileOptions {",
            "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )

    dep = 'coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")'
    if dep not in text:
        if re.search(r"\ndependencies\s*\{", text):
            text = re.sub(
                r"\ndependencies\s*\{",
                "\ndependencies {\n    " + dep,
                text,
                count=1,
            )
        else:
            text += f"\n\ndependencies {{\n    {dep}\n}}\n"

    APP_GRADLE.write_text(text, encoding="utf-8")


def patch_manifest() -> None:
    text = MANIFEST.read_text(encoding="utf-8")

    for perm in PERMISSIONS:
        tag = f'<uses-permission android:name="{perm}" />'
        if perm not in text:
            text = text.replace("<application", f"    {tag}\n    <application", 1)

    text = re.sub(r'android:label="[^"]+"', 'android:label="@string/app_name"', text)

    if "io.flutter.embedding.android.EnableImpeller" not in text:
        text = text.replace(
            "<activity",
            """<activity""",
            1,
        )
        impeller = """            <meta-data
                android:name="io.flutter.embedding.android.EnableImpeller"
                android:value="false" />
"""
        if "io.flutter.embedding.android.NormalTheme" in text:
            text = text.replace(
                """<meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />""",
                impeller
                + """            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />""",
                1,
            )
        else:
            text = text.replace(
                "<intent-filter>",
                impeller + "            <intent-filter>",
                1,
            )

    if "ScheduledNotificationReceiver" not in text:
        text = text.replace("</application>", ALARM_SNIPPET + "    </application>", 1)

    if "android.intent.action.TTS_SERVICE" not in text:
        if "<queries>" in text:
            text = text.replace("<queries>", "<queries>" + QUERIES_SNIPPET, 1)
        else:
            text = text.replace(
                "</manifest>",
                "    <queries>" + QUERIES_SNIPPET + "    </queries>\n</manifest>",
                1,
            )

    MANIFEST.write_text(text, encoding="utf-8")


def write_resources() -> None:
    STRINGS.parent.mkdir(parents=True, exist_ok=True)
    if STRINGS.exists():
        strings = STRINGS.read_text(encoding="utf-8")
        if "app_name" in strings:
            strings = re.sub(
                r'<string name="app_name">[^<]*</string>',
                f'<string name="app_name">{APP_LABEL}</string>',
                strings,
            )
        else:
            strings = strings.replace(
                "</resources>",
                f'    <string name="app_name">{APP_LABEL}</string>\n</resources>',
            )
        STRINGS.write_text(strings, encoding="utf-8")
    else:
        STRINGS.write_text(
            f'''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">{APP_LABEL}</string>
</resources>
''',
            encoding="utf-8",
        )

    if COLORS.exists():
        colors = COLORS.read_text(encoding="utf-8")
        if "splash_color" not in colors:
            colors = colors.replace(
                "</resources>",
                '    <color name="splash_color">#020617</color>\n</resources>',
            )
            COLORS.write_text(colors, encoding="utf-8")
    else:
        COLORS.write_text(
            '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_color">#020617</color>
</resources>
''',
            encoding="utf-8",
        )

    if STYLES.exists():
        styles = STYLES.read_text(encoding="utf-8")
        if "splash_color" not in styles and "LaunchTheme" in styles:
            styles = styles.replace(
                'parent="@android:style/Theme.Light.NoTitleBar">',
                'parent="@android:style/Theme.Light.NoTitleBar">\n        <item name="android:windowBackground">@color/splash_color</item>',
                1,
            )
            STYLES.write_text(styles, encoding="utf-8")

    if not LAUNCH.exists():
        LAUNCH.parent.mkdir(parents=True, exist_ok=True)
        LAUNCH.write_text(
            '''<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_color" />
</layer-list>
''',
            encoding="utf-8",
        )


def main() -> None:
    if not APP_GRADLE.exists() or not MANIFEST.exists():
        raise SystemExit("Android platform is missing. Run flutter create --platforms=android . first.")
    patch_gradle()
    patch_manifest()
    write_resources()
    print("Configured Android project for Англисиро Омӯз")


if __name__ == "__main__":
    main()
