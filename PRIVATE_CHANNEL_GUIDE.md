# راهنمای استفاده از Private Channel

این راهنما نحوه استفاده از برنامه با Private Channel های Laravel Reverb را توضیح می‌دهد.

## تفاوت Public و Private Channel

### Public Channel
- همه می‌توانند به آن subscribe کنند
- نیازی به authorization ندارد
- نام channel: `orders`, `notifications`, etc.

### Private Channel
- فقط کاربران authorized می‌توانند subscribe کنند
- نیاز به authentication endpoint دارد
- نام channel باید با `private-` شروع شود
- مثال: `private-Ecommerce.Orders.All`

## تنظیمات Laravel برای Private Channel

### 1. فایل `routes/channels.php`

```php
<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('Ecommerce.Orders.All', function ($user) {
    // بررسی اینکه آیا کاربر اجازه دسترسی دارد؟
    // مثلا فقط admin ها یا کاربران خاص
    return $user->hasRole('admin') || $user->hasRole('kitchen');
});
```

### 2. Event در Laravel

```php
<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
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
        $this->customerName = $order?->user?->name ?? '-';
        $this->orderDetails = $order?->description ?? '-';
        $this->totalPrice = (float) ($order?->total ?? 0);
        $this->createdAt = $order?->created_at?->toIso8601String() ?? now()->toIso8601String();
    }

    /**
     * Private Channel - نیاز به Authorization دارد
     */
    public function broadcastOn(): array
    {
        return [
            new PrivateChannel('Ecommerce.Orders.All'),
        ];
    }

    public function broadcastAs(): string
    {
        return 'CreateOrderEvent';
    }

    public function broadcastWith(): array
    {
        return [
            'id' => $this->id,
            'customerName' => $this->customerName,
            'orderDetails' => $this->orderDetails,
            'totalPrice' => $this->totalPrice,
            'createdAt' => $this->createdAt,
        ];
    }
}
```

### 3. Authentication Endpoint

در Laravel، endpoint پیش‌فرض برای authorization این است:

```
POST /broadcasting/auth
```

این endpoint به صورت خودکار توسط Laravel تعریف شده است (در `BroadcastServiceProvider`).

برای تست، می‌توانید یک endpoint سفارشی بسازید:

```php
// routes/api.php
Route::post('/broadcasting/auth', function (Request $request) {
    $user = $request->user();

    if (!$user) {
        return response()->json(['error' => 'Unauthorized'], 403);
    }

    $channelName = $request->input('channel_name');
    $socketId = $request->input('socket_id');

    // بررسی دسترسی
    $hasAccess = $user->hasRole('admin') || $user->hasRole('kitchen');

    if (!$hasAccess) {
        return response()->json(['error' => 'Forbidden'], 403);
    }

    // ساخت auth signature
    $appKey = config('reverb.app_key');
    $appSecret = config('reverb.app_secret');

    $stringToSign = $socketId . ':' . $channelName;
    $signature = hash_hmac('sha256', $stringToSign, $appSecret);
    $auth = $appKey . ':' . $signature;

    return response()->json([
        'auth' => $auth,
    ]);
})->middleware('auth:sanctum');
```

## تنظیمات برنامه Flutter

### برای Public Channel

```
App Key: ICS7DPZtPJyrRLjNFDBcsTiDzkNrj4QA
Host: ws1.binacity.com
Port: 443
Channel Name: orders
Event Name: CreateOrderEvent
Auth Token: (خالی بگذارید)
Auth Endpoint: (خالی بگذارید)
```

### برای Private Channel

```
App Key: ICS7DPZtPJyrRLjNFDBcsTiDzkNrj4QA
Host: ws1.binacity.com
Port: 443
Channel Name: private-Ecommerce.Orders.All
Event Name: CreateOrderEvent
Auth Token: your-bearer-token-here
Auth Endpoint: https://your-domain.com/api/broadcasting/auth
```

**نکات مهم:**
- نام channel باید دقیقا با `private-` شروع شود
- Auth Token باید یک Bearer token معتبر باشد (مثلا از Sanctum)
- Auth Endpoint باید URL کامل باشد

## دریافت Bearer Token

### روش 1: Laravel Sanctum

```php
// در Controller یا Route
$user = User::find(1); // کاربر مورد نظر
$token = $user->createToken('flutter-app')->plainTextToken;

// این token را در برنامه Flutter استفاده کنید
```

### روش 2: دستی از Postman/cURL

```bash
curl -X POST https://your-domain.com/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@example.com", "password": "password"}'
```

پاسخ:
```json
{
  "token": "1|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

این token را در فیلد Auth Token وارد کنید.

## عیب‌یابی

### خطا: Authorization failed: 403

**علت:** Bearer token نامعتبر است یا کاربر دسترسی ندارد

**راه‌حل:**
- مطمئن شوید token صحیح است
- بررسی کنید که کاربر role مناسب دارد
- لاگ‌های Laravel را بررسی کنید

### خطا: WebSocket هنوز متصل نشده است

**علت:** اتصال WebSocket برقرار نشده است

**راه‌حل:**
- مطمئن شوید Laravel Reverb در حال اجرا است
- آدرس و port را بررسی کنید
- Firewall را بررسی کنید

### Event دریافت نمی‌شود

**علت:** Channel یا Event name اشتباه است

**راه‌حل:**
- نام channel را بررسی کنید (باید با `private-` شروع شود)
- نام event را با Laravel مطابقت دهید
- لاگ‌های console برنامه را بررسی کنید

## مثال کامل

### 1. Laravel

```php
// Event
$order = Order::create([...]);
event(new CreateOrderEvent($order));
```

### 2. Flutter App

```
App Key: ICS7DPZtPJyrRLjNFDBcsTiDzkNrj4QA
Host: ws1.binacity.com
Port: 443
Channel Name: private-Ecommerce.Orders.All
Event Name: CreateOrderEvent
Auth Token: 1|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Auth Endpoint: https://ws1.binacity.com/api/broadcasting/auth
```

### 3. نتیجه

وقتی سفارش جدید ایجاد شود:
1. Laravel event را broadcast می‌کند
2. Reverb event را به channel مربوطه می‌فرستد
3. برنامه Flutter event را دریافت می‌کند
4. Notification نمایش داده می‌شود

---

**موفق باشید! 🎉**
