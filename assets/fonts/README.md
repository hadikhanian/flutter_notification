# فونت Vazir

این پوشه برای فونت‌های Vazir است.

## دانلود فونت

لطفا فونت Vazir را از لینک زیر دانلود کنید:

**لینک دانلود**: https://github.com/rastikerdar/vazir-font/releases/latest

یا مستقیم:
```
https://github.com/rastikerdar/vazir-font/releases/download/v33.003/vazir-font-v33.003.zip
```

## نصب

1. فایل zip را دانلود و extract کنید
2. فایل‌های زیر را در این پوشه قرار دهید:
   - `Vazir.ttf` (نسخه Regular)
   - `Vazir-Bold.ttf` (نسخه Bold)

3. پس از قرار دادن فایل‌ها، حتما rebuild کنید:
```bash
flutter clean
flutter pub get
flutter run -d windows
```

## یا به صورت دستی:

اگر فایل‌ها را پیدا نکردید، می‌توانید هر فونت فارسی دیگری (مثل IRANSans) استفاده کنید.

فقط نام فونت را در `pubspec.yaml` و `lib/main.dart` تغییر دهید.
