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
LIGHT_WINDOW = "#F8FAFC"

IMPELLER_META = """
        <meta-data
            android:name="io.flutter.embedding.android.EnableImpeller"
            android:value="false" />
"""

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
    text = _place_impeller_on_application(text)

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


def _place_impeller_on_application(text: str) -> str:
    """Impeller is ignored unless this meta-data is a direct child of application.

    A failed Impeller surface on some Android GPUs is a solid black window.
    Skia (EnableImpeller=false) is the startup-safe renderer for this app.
    """
    text = re.sub(
        r"\n[ \t]*<meta-data\b[^>]*io\.flutter\.embedding\.android\.EnableImpeller[^>]*/>",
        "",
        text,
    )
    match = re.search(r"<application\b[^>]*>", text, flags=re.DOTALL)
    if match is None:
        return text
    tag = match.group(0)
    if "android:hardwareAccelerated" not in tag:
        tag = tag[:-1] + '\n        android:hardwareAccelerated="true">'
    rest = text[match.end() :]
    if rest.startswith("\n"):
        rest = rest[1:]
    return text[: match.start()] + tag + IMPELLER_META + rest


def _upsert_splash_color(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    snippet = f'    <color name="splash_color">{LIGHT_WINDOW}</color>\n'
    if not path.exists():
        path.write_text(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            "<resources>\n"
            f"{snippet}</resources>\n",
            encoding="utf-8",
        )
        return
    colors = path.read_text(encoding="utf-8")
    if 'name="splash_color"' in colors:
        colors = re.sub(
            r'(<color name="splash_color">)[^<]*(</color>)',
            rf"\g<1>{LIGHT_WINDOW}\g<2>",
            colors,
        )
    elif "</resources>" in colors:
        colors = colors.replace("</resources>", snippet + "</resources>", 1)
    else:
        colors += f"\n<resources>\n{snippet}</resources>\n"
    path.write_text(colors, encoding="utf-8")


def _lighten_known_splash_hex(text: str) -> str:
    text = re.sub(r"#0[Ff]172[Aa]", LIGHT_WINDOW, text)
    text = re.sub(r"#020617", LIGHT_WINDOW, text, flags=re.IGNORECASE)
    return text


def _force_light_window(styles: str) -> str:
    window_item = '<item name="android:windowBackground">@color/splash_color</item>'

    def repl_style(match: re.Match[str]) -> str:
        block = match.group(0)
        block = block.replace(
            "@android:style/Theme.Black.NoTitleBar",
            "@android:style/Theme.Light.NoTitleBar",
        )
        if 'name="android:windowBackground"' in block:
            block = re.sub(
                r'<item name="android:windowBackground">[^<]*</item>',
                window_item,
                block,
            )
        else:
            block = block.replace(">", ">\n        " + window_item, 1)
        return block

    styles = re.sub(
        r'<style name="(?:LaunchTheme|NormalTheme)"[^>]*>.*?</style>',
        repl_style,
        styles,
        flags=re.DOTALL,
    )
    return _lighten_known_splash_hex(styles)


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

    res = ANDROID / "app" / "src" / "main" / "res"
    color_files = [COLORS]
    if res.exists():
        color_files.extend(path for path in res.glob("values*/colors.xml") if path != COLORS)
    seen: set[Path] = set()
    for color_file in color_files:
        if color_file in seen:
            continue
        seen.add(color_file)
        _upsert_splash_color(color_file)

    if res.exists():
        for styles in res.glob("values*/styles.xml"):
            styles.write_text(_force_light_window(styles.read_text(encoding="utf-8")), encoding="utf-8")
        for xml in res.rglob("*.xml"):
            original = xml.read_text(encoding="utf-8")
            updated = _lighten_known_splash_hex(original)
            if updated != original:
                xml.write_text(updated, encoding="utf-8")

    if not LAUNCH.exists():
        LAUNCH.parent.mkdir(parents=True, exist_ok=True)
        LAUNCH.write_text(
            """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_color" />
</layer-list>
""",
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
