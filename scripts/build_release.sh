#!/usr/bin/env bash
# بناء نسخة Release موقّعة ومشوّشة وتنظيمها في مجلد Releases (جوه المشروع، برا Git):
#   Releases/<X.Y>v/
#     Ganbak-<X.Y>-arm64-v8a.apk     أغلب الموبايلات
#     Ganbak-<X.Y>-armeabi-v7a.apk   الموبايلات القديمة
#     Ganbak-<X.Y>-x86_64.apk        المحاكي / Chromebook
#     Ganbak-<X.Y>-universal.apk     أي موبايل (أكبر)
#     SHA256SUMS.txt + Release_Notes.txt
#   Ganbak-android.apk / Ganbak-android-universal.apk  ← نفس arm64 / الشاملة بأسامي ثابتة (لزرار التحميل في الموقع)
#   Releases/Ganbak.apk  ← آخر إصدار (النسخة الشاملة)
#
# كل النسخ بنفس رقم الإصدار الداخلي (versionCode): اللي سطّب نسخة يقدر يحدّث بأي نسخة تانية.
set -euo pipefail

cd "$(dirname "$0")/.."

# جافا النظام (25) مفيهاش javac — بنستخدم JDK 21 لو موجود
JDK21="$HOME/Downloads/Files/toolchains/jdk-21.0.12.1+1"
if [ -z "${JAVA_HOME:-}" ] && [ -d "$JDK21" ]; then
  export JAVA_HOME="$JDK21" PATH="$JDK21/bin:$PATH"
fi

if [ ! -f ../Signing_Key/key.properties ]; then
  echo "⚠️  مفتاح التوقيع مش موجود في ../Signing_Key — شوف README هناك"
  exit 1
fi

# 1.0.0+1 ← 1.0
VERSION=$(grep '^version:' pubspec.yaml | sed -E 's/version: ([0-9]+)\.([0-9]+).*/\1.\2/')
NOTES="release_notes/${VERSION}v.txt"
NOTES_EN="release_notes/${VERSION}v.en.md"
for f in "$NOTES" "$NOTES_EN"; do
  if [ ! -f "$f" ]; then
    echo "⚠️  اكتب ملاحظات الإصدار الأول في: $f (عربي .txt + إنجليزي .en.md)"
    exit 1
  fi
done

flutter pub get
flutter analyze
flutter test
SYMBOLS="build/symbols/${VERSION}"
COMMON=(--release --obfuscate --split-debug-info="$SYMBOLS" -P force-version-code-ignoring-abi=true)
APKS=build/app/outputs/flutter-apk
OUT="Releases/${VERSION}v"
mkdir -p "$OUT"
rm -f "$OUT"/Ganbak-*.apk "$OUT"/SHA256SUMS.txt

# 1) النسخة الشاملة
flutter build apk "${COMMON[@]}"
cp "$APKS/app-release.apk" "$OUT/Ganbak-${VERSION}-universal.apk"

# 2) نسخة لكل نوع معالج
flutter build apk "${COMMON[@]}" --split-per-abi
for ABI in arm64-v8a armeabi-v7a x86_64; do
  cp "$APKS/app-${ABI}-release.apk" "$OUT/Ganbak-${VERSION}-${ABI}.apk"
done

# نسخ بأسامي ثابتة: زرار التحميل في الموقع بيشاور على releases/latest/download/<الاسم> فبيجيب آخر إصدار على طول
cp "$OUT/Ganbak-${VERSION}-arm64-v8a.apk" "$OUT/Ganbak-android.apk"
cp "$OUT/Ganbak-${VERSION}-universal.apk" "$OUT/Ganbak-android-universal.apk"

cp "$NOTES" "$OUT/Release_Notes.txt"
(cd "$OUT" && sha256sum Ganbak-*.apk > SHA256SUMS.txt)

# ملاحظات GitHub: الإنجليزي فوق والعربي تحته
{
  cat "$NOTES_EN"
  printf '\n---\n\n<div dir="rtl">\n\n'
  sed -e 's/^=\+$//' -e 's/^-\+$//' "$NOTES"
  printf '\n</div>\n'
} > "$OUT/github_release.md"
cp "$OUT/Ganbak-${VERSION}-universal.apk" Releases/Ganbak.apk

# نقفل Gradle عشان ميفضلش ماسك ~2 جيجا رام
(cd android && ./gradlew --stop >/dev/null 2>&1) || true

echo
echo "✅ الإصدار ${VERSION}v جاهز في $(realpath "$OUT"):"
(cd "$OUT" && ls -lh Ganbak-*.apk | awk '{print "   " $5 "\t" $9}')
echo
echo "النشر على GitHub (بعد ما تعمل تاج v${VERSION} وتعمل له push):"
echo "   gh release create v${VERSION} $OUT/Ganbak-*.apk $OUT/SHA256SUMS.txt --title \"Ganbak ${VERSION}\" --notes-file $OUT/github_release.md"
