#!/usr/bin/env bash
# ============================================================
# generate_secrets.sh — توليد secrets.dart من متغيرات البيئة
#
# الاستخدام:
#   bash scripts/generate_secrets.sh
#
# المتطلبات (يجب أن تكون مضبوطة في البيئة):
#   GAS_BASE_URL    — رابط Google Apps Script
#   GAS_SECRET_KEY  — المفتاح السري للـ GAS
#   GEMINI_API_KEY  — مفتاح Gemini API
#
# ملاحظة: secrets.dart مُدرج في .gitignore — لا يُرفع أبداً
# ============================================================

set -euo pipefail

TARGET="packages/shared/lib/config/secrets.dart"

# ── التحقق من المتغيرات ───────────────────────────────────────

missing=()

[ -z "${GAS_BASE_URL:-}" ] && missing+=("GAS_BASE_URL")
[ -z "${GAS_SECRET_KEY:-}" ] && missing+=("GAS_SECRET_KEY")
[ -z "${GEMINI_API_KEY:-}" ] && missing+=("GEMINI_API_KEY")

if [ ${#missing[@]} -gt 0 ]; then
  echo "❌ المتغيرات التالية غير مضبوطة:" >&2
  for var in "${missing[@]}"; do
    echo "   - $var" >&2
  done
  echo "" >&2
  echo "اضبطها في Replit Secrets أو كمتغيرات بيئة قبل تشغيل هذا السكريبت." >&2
  exit 1
fi

# ── توليد الملف ──────────────────────────────────────────────

cat > "$TARGET" << EOF
// ============================================================
// TO Best — secrets.dart  (GENERATED — do not edit manually)
// ⚠️ مُولَّد تلقائياً بواسطة scripts/generate_secrets.sh
// ⚠️ هذا الملف في .gitignore — لا ترفعه أبداً
// ============================================================

class AppSecrets {
  AppSecrets._();

  static const String gasBaseUrl = '${GAS_BASE_URL}';
  static const String gasSecretKey = '${GAS_SECRET_KEY}';
  static const String geminiApiKey = '${GEMINI_API_KEY}';
}
EOF

echo "✅ تم توليد $TARGET بنجاح"
