# TO Best Monorepo 🏋️

نظام Flutter Monorepo كامل لتطبيقَي **TO Best** (المستخدم والمدرب) و **TO Best Management** (الإدارة).

---

## 📁 هيكل المشروع

```
tobest_monorepo/
├── packages/
│   └── shared/                 # الكود المشترك بين التطبيقين
│       └── lib/
│           ├── config/         # AppConfig، Secrets
│           ├── domain/         # Entities، Repositories (مجردة)
│           ├── data/           # Models (Isar)، Datasources
│           ├── infrastructure/ # GasClient، IsarService، SyncService، VideoService
│           ├── design/         # Tokens، Themes، Widgets
│           └── utils/          # Evaluator، Validators، Extensions
├── apps/
│   ├── tobest/                 # تطبيق USER + COACH
│   └── tobest_management/      # تطبيق MANAGER + SUPPORT + SUBSCRIPTIONS
└── .github/
    └── workflows/              # CI/CD: بناء APK تلقائياً
```

---

## ⚡ البدء السريع

### 1. المتطلبات
- Flutter SDK ≥ 3.44.0 (Stable)
- Dart ≥ 3.3.0
- Java 17 (للـ Android Build)
- Melos CLI

### 2. تثبيت Melos
```bash
dart pub global activate melos
```

### 3. تهيئة الأسرار
انسخ `packages/shared/lib/config/secrets.dart` واملأه:
```dart
class AppSecrets {
  static const String gasBaseUrl = 'YOUR_GAS_URL';
  static const String gasSecretKey = 'YOUR_SECRET';
  static const String geminiApiKey = 'YOUR_GEMINI_KEY';
}
```

### 4. Bootstrap + Code Generation
```bash
# تثبيت كل الـ Dependencies
melos bootstrap

# توليد الكود (Isar + Riverpod)
melos run gen:shared
melos run gen:apps
```

### 5. تشغيل التطبيقات
```bash
# TO Best
cd apps/tobest && flutter run

# TO Best Management
cd apps/tobest_management && flutter run
```

---

## 🏗️ Architecture

### Clean Architecture (بدون تعقيد زائد)
```
Domain Layer      → Entities + Repositories (abstract)
Data Layer        → Models (Isar) + GAS DataSource
Infrastructure    → GasClient, IsarService, SyncService
Presentation      → Riverpod Providers + Screens
```

### State Management
- **Riverpod 2.x** مع Code Generation (`@riverpod`)
- **AsyncValue** لكل العمليات الـ async
- **Hooks** للـ Local UI state

### Local Storage
- **Isar 3.x** — قاعدة بيانات محلية سريعة
- **Weekly Cleanup**: مزامنة → مسح Isar → إعادة سحب
- **Sync Queue**: للعمليات الـ Offline

### Backend
- **Google Apps Script (GAS)** — Backend as a Service
- كل الطلبات عبر `POST` بـ `action` field
- **لا Firebase** — لا Push Notifications

### Video
- **VideoServiceDrive** (Google Drive عبر GAS)
- قابل للاستبدال بـ Cloudflare / Bunny بدون تغيير UI
- LRU Cache محلي (500MB حد أقصى)

### AI Coach
- **Gemini 2.0 Flash** — مباشر من التطبيق
- Context المستخدم الكامل في الـ System Prompt
- سجل المحادثات محفوظ في Isar

---

## 🎨 التصميم

### ثيمات (5 خيارات)
| الثيم | الوصف |
|-------|-------|
| Auto | يتبع نظام الجهاز |
| Light | فاتح (أبيض) |
| Dark | داكن (أسود) |
| Blue | أزرق |
| Pink | وردي |

### ألوان التمييز (5 خيارات)
| اللون | الكود |
|-------|-------|
| Slate Indigo | `#4F46E5` |
| Deep Teal | `#0F766E` |
| Warm Amber | `#D97706` |
| Dusty Rose | `#E11D48` |
| Slate Gray | `#475569` |

---

## 🔐 الأمان

- **FLAG_SECURE** على شاشات التمرين والتغذية وتغيير كلمة المرور والـ OTP
- **Force Logout** من الإدارة يُلغي جلسات كل الأجهزة
- **Device Limit** قابل للتخصيص من GAS
- **OTP Rate Limiting**: 3 طلبات/ساعة، صلاحية 10 دقائق
- **Secrets** في `FlutterSecureStorage` (مشفرة)

---

## 📱 شاشات TO Best

| الشاشة | الوصف |
|--------|-------|
| Splash | Breathing Animation + تحقق من Auth |
| Login | Email/Phone + Google Sign In + Guest |
| Register | 2 خطوات: بيانات حساب + جسم |
| Forgot Password | OTP → كلمة مرور جديدة |
| Home | نظرة عامة + Streak + AI Coach |
| Workout | برنامج اليوم + تسجيل سيتات + Rest Timer |
| Nutrition | Macro Summary + وجبات + AI Parse |
| Progress | Heatmap + Volume Chart + Personal Records |
| Chat | محادثات + صور + صوت + Reactions |
| AI Coach | Gemini 2.0 + تحليل صور |
| Settings | ثيم + لون + خط + لغة + حساب |

## 📱 شاشات TO Best Management

| الشاشة | الصلاحية |
|--------|---------|
| Dashboard | الكل |
| Users | الكل (SUPPORT: بدون حذف) |
| Subscription Requests | MANAGER + SUBSCRIPTIONS |
| Program Requests | MANAGER + SUPPORT |
| Chat | الكل |
| Subscription Plans | MANAGER |
| Connection Settings | MANAGER |
| Referral Stats | MANAGER |

---

## 🤖 CI/CD

### GitHub Actions (تلقائي)
- **Trigger**: Push لـ `main` أو `develop`
- **Build**: APK منفصل لكل Architecture (arm64, arm32, x86_64)
- **Obfuscation**: تعتيم الكود في الـ Release
- **Artifacts**: محفوظة 30 يوم

### GitHub Secrets المطلوبة
```
GAS_BASE_URL          # رابط GAS
GAS_SECRET_KEY        # المفتاح السري
GEMINI_API_KEY        # مفتاح Gemini
KEYSTORE_BASE64       # Keystore مشفر بـ Base64 (tobest)
KEY_ALIAS             # اسم Key
KEY_PASSWORD          # كلمة مرور Key
STORE_PASSWORD        # كلمة مرور Keystore
MGMT_KEYSTORE_BASE64  # Keystore الإدارة
MGMT_KEY_ALIAS
MGMT_KEY_PASSWORD
MGMT_STORE_PASSWORD
```

---

## 📊 محرك التقييم (Evaluator)

مُحوَّل حرفياً من `evaluator.js`:

| الكود | التقييم |
|-------|---------|
| `s1` | ممتاز جداً جداً |
| `s2` | ممتاز جداً |
| `s3` | ممتاز |
| `rv` | استعادة المستوى |
| `gd` | جيد |
| `st` | ثبات |
| `ws` | تحذير ثبات |
| `dn` | انخفاض |
| `beg` | بداية |

---

## 🍎 قاعدة الأطعمة

- **100+ عنصر أساسي** مُضمَّن في التطبيق (يُبذَر في Isar عند أول تشغيل)
- **1000+ عنصر موسّع** يُحمَّل من GAS عند الـ Onboarding
- دعم **وحدات عربية** (كوب، ملعقة، حبة، جرام...)
- **Fuzzy Matching** مع تطبيع النص العربي
- **Levenshtein Distance** للمطابقة التقريبية

---

## 🔧 إضافة ميزة جديدة

1. أضف **Entity** في `packages/shared/lib/domain/entities/`
2. أضف **Repository** (abstract) في `packages/shared/lib/domain/repositories/`
3. أضف **Isar Model** في `packages/shared/lib/data/models/`
4. نفّذ **Repository** في `packages/shared/lib/data/repositories/`
5. أضف **Provider** في التطبيق المعني
6. أضف **Screen** مع الـ Route في `router.dart`

---

## ⚠️ ملاحظات تقنية مهمة

### Google Drive للفيديو
Drive لا يدعم HTTP Range Requests كاملاً → Seeking محدود.
للترقية إلى Cloudflare/Bunny: استبدل `VideoServiceDrive` فقط.

### Isar 3.x
- لا تستخدم `Isar 4.0.0-dev` — API مختلف
- `@Collection` مع `@Index` للاستعلامات السريعة
- `writeTxn()` لكل العمليات الكتابية

### Code Generation
بعد أي تعديل على `@riverpod` أو `@Collection`:
```bash
melos run gen:all
```

---

## 📞 Support

للتواصل مع الفريق التقني — افتح Issue في الـ Repository.

---

*TO Best — تدريبك، تغذيتك، تميّزك* 🌿
