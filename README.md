# پرونده‌های کارآگاه محمدطاها (Detective Mohammad Taha)

بازی کارآگاهی و معمایی فارسی برای اندروید، ساخته‌شده با **Godot 4.3** و **GDScript**.
قهرمان بازی کارآگاه «محمدطاها طاهریان» است و چهره‌ی او از عکس ارسالی (`assets/characters/`) گرفته شده است.

> **وضعیت صادقانه:** این مخزن آماده‌ی ساخت است، اما APK هنوز توسط شما از طریق GitHub Actions ساخته نشده است.
> گزارش کامل چیزهای آزمایش‌شده و آزمایش‌نشده در `docs/GAME_REPORT.md` است.

## امکانات
- ۸ پرونده‌ی مستقل با داستان پیوسته (کارآگاهی، بازجویی، تناقض‌یابی)
- دفترچه‌ی شواهد، تخته‌ی ارتباط سرنخ‌ها، انتخاب مظنون با ارائه‌ی دلیل
- سه سطح راهنما، امتیازدهی هر پرونده، باز شدن تدریجی پرونده‌ها
- ذخیره‌ی خودکار محلی (`user://save.json`)، بدون نیاز به اینترنت یا حساب کاربری
- رابط راست‌چین فارسی، فونت Vazirmatn (SIL OFL)، گفتار فارسی از طریق TTS اندروید در صورت وجود و در غیر این صورت زیرنویس کامل

## مرحله‌به‌مرحله: گرفتن APK از GitHub
1. در GitHub یک مخزن خالی بسازید (مثلاً `detective-mohammad-taha`).
2. در پوشه‌ی پروژه:
   ```bash
   git init && git add . && git commit -m "init"
   git branch -M main
   git remote add origin https://github.com/<USER>/detective-mohammad-taha.git
   git push -u origin main
   ```
3. در GitHub به تب **Actions** بروید؛ Workflow با نام **Build Android APK** خودکار اجرا می‌شود (یا از دکمه‌ی **Run workflow** استفاده کنید).
4. بعد از سبز شدن، وارد همان اجرا شوید و در بخش **Artifacts** فایل **Detective-Mohammad-Taha-APK** را دانلود کنید (داخل zip، فایل `Detective-Mohammad-Taha.apk` است).
5. APK را روی گوشی منتقل و نصب کنید (نصب از منابع ناشناس را برای همان برنامه‌ی فایل‌منیجر فعال کنید).
6. برای انتشار روی GitHub Releases یک Tag بزنید: `git tag v1.0.0 && git push --tags`.

اگر مرحله‌ای قرمز شد، لاگ همان مرحله و Artifact **export-log** علت را نشان می‌دهد. Workflow در صورت نبودن APK شکست می‌خورد و موفقیت جعلی نشان نمی‌دهد.

## نسخه‌ی آزمایشی در برابر نسخه‌ی انتشار
- بدون Secret: APK با **کلید دیباگ موقتی** امضا می‌شود. قابل نصب است ولی برای Google Play مناسب نیست و هر بار کلید جدیدی دارد (آپدیت روی نسخه‌ی قبلی ممکن است نصب نشود).
- برای نسخه‌ی امضاشده، در Settings ← Secrets این‌ها را بسازید: `RELEASE_KEYSTORE_B64` (خروجی `base64 -w0 my.keystore`)، `RELEASE_KEY_ALIAS`، `RELEASE_KEYSTORE_PASSWORD`. هیچ رمزی داخل کد نیست.

## توسعه
- باز کردن: Godot 4.3 → Import → `project.godot`
- محتوای پرونده‌ها در `tools/build_cases.py` نوشته می‌شود و با `python3 tools/build_cases.py` به `data/cases/*.json` تبدیل می‌شود.
- اعتبارسنجی (ارجاع‌ها، دسترس‌پذیری مدارک، نبود بن‌بست): `python3 tools/validate_data.py`
- افزودن پرونده: یک `L`/`P`/`PL` جدید در `build_cases.py`، یک فایل `case_09.json` تولید می‌شود و `CASE_COUNT` را در `scripts/game.gd` بالا ببرید.
- تصاویر و صداها: `python3 tools/make_assets.py <عکس>`
- فونت: Workflow فونت Vazirmatn را موقع ساخت دانلود می‌کند. برای کار آفلاین، `Vazirmatn-Regular.ttf` را در `assets/fonts/` بگذارید.

## ساختار
`scenes/` صحنه‌ی اصلی · `scripts/` منطق (`game.gd` داده/ذخیره/صدا، `main.gd` رابط) · `data/cases/` پرونده‌ها · `assets/` تصاویر، صداها، فونت · `.github/workflows/` ساخت خودکار
