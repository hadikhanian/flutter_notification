# 🍽️ سیستم اعلان سفارشات رستوران

یک اپلیکیشن Desktop با Flutter که به Laravel Reverb WebSocket متصل می‌شود و سفارشات جدید رستوران را به صورت **فوری و Critical** نمایش می‌دهد.

## ✨ ویژگی‌های کلیدی

### 🚨 اعلان‌های Critical

### 🚨 اعلان‌های Critical
- **سیستم Always-on-top Window**: پنجره همیشه در بالای تمام برنامه‌ها (حتی بازی‌ها) نمایش داده می‌شود
- **صدای هشدار مداوم**: تا زمانی که سفارش تایید نشود، صدای هشدار به صورت loop پخش می‌شود
- **سیستم System Notification**: اعلان سیستمی با اولویت بالا برای Windows/Linux/macOS
- **غیرقابل بستن**: تا زمانی که کاربر سفارش را acknowledge نکند، پنجره بسته نمی‌شود
- **انیمیشن جذب توجه**: پنجره با انیمیشن‌های scale و rotation توجه کاربر را جلب می‌کند

### 🔌 اتصال به Laravel Reverb
- اتصال WebSocket به Laravel Reverb
- پشتیبانی از Events سفارشی
- اتصال مجدد خودکار در صورت قطع شدن
- نمایش وضعیت اتصال به صورت Real-time

### 📱 رابط کاربری
- پنل تنظیمات برای وارد کردن اطلاعات اتصال
- نمایش لیست سفارشات دریافتی
- پنجره Popup با طراحی جذاب برای هر سفارش جدید
- پشتیبانی از زبان فارسی

## 📋 پیش‌نیازها

### نصب Flutter
برای اجرای این پروژه نیاز به Flutter SDK دارید:

```bash
# دانلود Flutter از سایت رسمی
https://docs.flutter.dev/get-started/install

# تایید نصب
flutter doctor
```

### تنظیمات Laravel Reverb

در Laravel خود، باید Reverb را نصب و تنظیم کنید:

```bash
# نصب Laravel Reverb
composer require laravel/reverb

# انتشار فایل‌های تنظیمات
php artisan reverb:install

# اجرای Reverb
php artisan reverb:start
```

## 🚀 نصب و راه‌اندازی

### 1. Clone کردن پروژه

```bash
git clone <repository-url>
cd flutter_notification
```

### 2. نصب Dependencies

```bash
flutter pub get
```

### 3. اضافه کردن فایل صوتی

یک فایل صوتی با نام `notification.mp3` در مسیر `assets/sounds/` قرار دهید.

**توصیه**: از یک صدای واضح و بلند برای هشدار استفاده کنید.

می‌توانید از صداهای رایگان از منابع زیر استفاده کنید:
- https://freesound.org/
- https://www.zapsplat.com/
- https://soundbible.com/

### 4. Build و اجرا

#### برای Windows:
```bash
flutter run -d windows
```

#### برای Linux:
```bash
flutter run -d linux
```

#### برای macOS:
```bash
flutter run -d macos
```

### 5. Build برای Production

#### Windows:
```bash
flutter build windows --release
```
فایل exe در مسیر `build/windows/runner/Release/` قرار می‌گیرد.

#### Linux:
```bash
flutter build linux --release
```

#### macOS:
```bash
flutter build macos --release
```

## ⚙️ تنظیمات

پس از اجرای برنامه، موارد زیر را در پنل تنظیمات وارد کنید:

### Laravel Reverb Settings

| فیلد | توضیحات | مثال |
|------|---------|------|
| **App Key** | کلید application از فایل `.env` Laravel | `local` یا app key خود |
| **Host** | آدرس سرور Laravel Reverb | `ws://127.0.0.1` یا `wss://yourdomain.com` |
| **Port** | پورت Reverb (پیش‌فرض 6001) | `6001` |
| **Channel Name** | نام Channel که در Laravel تعریف شده | `orders` |
| **Event Name** | نام Event که broadcast می‌شود | `CreateOrderEvent` |

### مثال تنظیمات Laravel

#### در فایل `.env`:
```env
REVERB_APP_ID=your-app-id
REVERB_APP_KEY=local
REVERB_APP_SECRET=your-secret
REVERB_HOST=127.0.0.1
REVERB_PORT=6001
REVERB_SCHEME=http
```

#### Event در Laravel:
```php
namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CreateOrderEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $id;
    public $customerName;
    public $orderDetails;
    public $totalPrice;
    public $createdAt;

    public function __construct($order)
    {
        $this->id = $order->id;
        $this->customerName = $order->customer_name;
        $this->orderDetails = $order->details;
        $this->totalPrice = $order->total;
        $this->createdAt = $order->created_at;
    }

    public function broadcastOn()
    {
        return new Channel('orders');
    }

    public function broadcastAs()
    {
        return 'CreateOrderEvent';
    }
}
```

#### استفاده در Laravel:
```php
// در Controller یا هر جای دیگر
use App\Events\CreateOrderEvent;

$order = Order::create([
    'customer_name' => 'علی احمدی',
    'details' => 'یک پیتزا پپرونی، یک نوشابه',
    'total' => 250000,
]);

event(new CreateOrderEvent($order));
```

## 🎯 نحوه استفاده

1. برنامه را اجرا کنید
2. تنظیمات Laravel Reverb را وارد کنید
3. روی دکمه "اتصال به سرور" کلیک کنید
4. پس از اتصال موفق، برنامه منتظر دریافت سفارشات می‌ماند
5. هنگام دریافت سفارش جدید:
   - یک System Notification نمایش داده می‌شود
   - صدای هشدار شروع به پخش می‌شود
   - یک پنجره Always-on-top با جزئیات سفارش باز می‌شود
   - تا زمانی که روی دکمه تایید کلیک نکنید، پنجره و صدا ادامه دارد

## 🛠️ ساختار پروژه

```
flutter_notification/
├── lib/
│   ├── main.dart                           # Entry point
│   ├── models/
│   │   ├── order_event.dart               # Model سفارش
│   │   └── order_event.g.dart             # Generated JSON serialization
│   ├── services/
│   │   ├── websocket_service.dart         # سرویس WebSocket
│   │   └── notification_service.dart      # سرویس Notification
│   └── screens/
│       ├── main_screen.dart               # صفحه اصلی
│       └── order_notification_popup.dart  # پنجره Popup سفارش
├── assets/
│   └── sounds/
│       └── notification.mp3               # فایل صوتی (باید اضافه شود)
├── pubspec.yaml                           # Dependencies
└── README.md                              # این فایل
```

## 🐛 عیب‌یابی

### صدا پخش نمی‌شود
- مطمئن شوید فایل `notification.mp3` در `assets/sounds/` وجود دارد
- مطمئن شوید Volume سیستم روشن است
- در صورت نبود فایل صوتی، برنامه از یک URL backup استفاده می‌کند

### WebSocket متصل نمی‌شود
- مطمئن شوید Laravel Reverb در حال اجرا است (`php artisan reverb:start`)
- آدرس Host و Port را بررسی کنید
- Firewall را بررسی کنید
- در فایل `.env` Laravel، تنظیمات Reverb را بررسی کنید

### Notification نمایش داده نمی‌شود
- در Windows، مطمئن شوید Notification های برنامه در تنظیمات سیستم فعال است
- در Linux، مطمئن شوید که یک notification daemon نصب است
- در macOS، در System Preferences > Notifications اجازه دهید

### پنجره Always-on-top کار نمی‌کند
- این ویژگی فقط روی Desktop پشتیبانی می‌شود
- مطمئن شوید از نسخه Desktop برنامه استفاده می‌کنید
- در برخی سیستم‌عامل‌ها ممکن است نیاز به مجوز اضافی باشد

## 📦 Dependencies

- `flutter` - فریمورک اصلی
- `pusher_channels_flutter` - اتصال به Pusher/Reverb
- `flutter_local_notifications` - Notification های سیستمی
- `audioplayers` - پخش صدا
- `window_manager` - مدیریت پنجره برای always-on-top
- `provider` - State management
- `http` - درخواست‌های HTTP
- `json_annotation` - JSON serialization

## 📝 توجهات مهم

1. **استفاده در محیط تولید**: این برنامه برای استفاده در آشپزخانه رستوران طراحی شده است
2. **Always Running**: برنامه باید همیشه در حال اجرا باشد تا سفارشات را دریافت کند
3. **Network**: مطمئن شوید اتصال اینترنت پایدار دارید
4. **Sound File**: حتما یک فایل صوتی مناسب اضافه کنید

## 🤝 مشارکت

برای گزارش مشکلات یا پیشنهادات، لطفا یک Issue باز کنید.

## 📄 License

این پروژه تحت لایسنس MIT منتشر شده است.

---

**ساخته شده با ❤️ برای رستوران‌داران**
