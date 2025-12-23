# راهنمای نصب Laravel Reverb

این راهنما نحوه راه‌اندازی Laravel Reverb را برای استفاده با این اپلیکیشن توضیح می‌دهد.

## 1. نصب Laravel Reverb

```bash
composer require laravel/reverb
```

## 2. انتشار فایل‌های Configuration

```bash
php artisan reverb:install
```

## 3. تنظیم فایل `.env`

فایل `.env` خود را با تنظیمات زیر به‌روزرسانی کنید:

```env
BROADCAST_CONNECTION=reverb

REVERB_APP_ID=123456
REVERB_APP_KEY=local
REVERB_APP_SECRET=your-secret-key
REVERB_HOST=127.0.0.1
REVERB_PORT=6001
REVERB_SCHEME=http

VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST="${REVERB_HOST}"
VITE_REVERB_PORT="${REVERB_PORT}"
VITE_REVERB_SCHEME="${REVERB_SCHEME}"
```

## 4. ایجاد Event

فایل `app/Events/CreateOrderEvent.php` را ایجاد کنید:

```php
<?php

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

    /**
     * Create a new event instance.
     */
    public function __construct($order)
    {
        $this->id = $order->id;
        $this->customerName = $order->customer_name;
        $this->orderDetails = $order->details;
        $this->totalPrice = (float) $order->total;
        $this->createdAt = $order->created_at->toIso8601String();
    }

    /**
     * Get the channels the event should broadcast on.
     */
    public function broadcastOn(): Channel
    {
        return new Channel('orders');
    }

    /**
     * The event's broadcast name.
     */
    public function broadcastAs(): string
    {
        return 'CreateOrderEvent';
    }

    /**
     * Get the data to broadcast.
     */
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

## 5. استفاده در Controller

```php
<?php

namespace App\Http\Controllers;

use App\Events\CreateOrderEvent;
use App\Models\Order;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'customer_name' => 'required|string|max:255',
            'details' => 'required|string',
            'total' => 'required|numeric|min:0',
        ]);

        // ایجاد سفارش
        $order = Order::create($validated);

        // ارسال Event
        event(new CreateOrderEvent($order));

        return response()->json([
            'success' => true,
            'message' => 'سفارش با موفقیت ثبت شد',
            'order' => $order,
        ]);
    }
}
```

## 6. ایجاد Model (اختیاری)

اگر Model Order ندارید:

```bash
php artisan make:model Order -m
```

در فایل migration:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('customer_name');
            $table->text('details');
            $table->decimal('total', 10, 2);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

اجرای migration:

```bash
php artisan migrate
```

## 7. اجرای Reverb Server

```bash
php artisan reverb:start
```

یا برای اجرا در background:

```bash
php artisan reverb:start --daemon
```

## 8. تست

### تست از طریق Tinker:

```bash
php artisan tinker
```

```php
$order = new \stdClass();
$order->id = 1;
$order->customer_name = 'علی احمدی';
$order->details = 'یک پیتزا پپرونی، یک نوشابه';
$order->total = 250000;
$order->created_at = now();

event(new App\Events\CreateOrderEvent($order));
```

### تست از طریق Route:

در `routes/web.php` یا `routes/api.php`:

```php
Route::post('/test-order', function () {
    $order = new \stdClass();
    $order->id = rand(1, 1000);
    $order->customer_name = 'مشتری تستی';
    $order->details = 'سفارش تستی';
    $order->total = rand(10000, 500000);
    $order->created_at = now();

    event(new \App\Events\CreateOrderEvent($order));

    return response()->json(['success' => true, 'message' => 'Event ارسال شد']);
});
```

سپس از Postman یا مرورگر:

```
POST http://127.0.0.1:8000/test-order
```

## 9. مانیتورینگ

برای مشاهده لاگ‌های Reverb:

```bash
tail -f storage/logs/laravel.log
```

## 10. Production

برای استفاده در محیط production:

1. از HTTPS استفاده کنید (`wss://` به جای `ws://`)
2. یک reverse proxy مانند Nginx تنظیم کنید
3. از Supervisor برای اجرای مداوم Reverb استفاده کنید

### مثال Supervisor config:

```ini
[program:reverb]
command=php /path/to/your/project/artisan reverb:start
directory=/path/to/your/project
autostart=true
autorestart=true
user=www-data
redirect_stderr=true
stdout_logfile=/var/log/reverb.log
```

## عیب‌یابی

### Event ارسال نمی‌شود:
- مطمئن شوید `BROADCAST_CONNECTION=reverb` در `.env` تنظیم شده
- بررسی کنید که Reverb server در حال اجرا است
- لاگ‌های Laravel را بررسی کنید

### اتصال برقرار نمی‌شود:
- Firewall را بررسی کنید
- مطمئن شوید پورت 6001 باز است
- در محیط production از WSS استفاده کنید

### Event دریافت نمی‌شود:
- نام Channel و Event را در Laravel و Flutter بررسی کنید
- مطمئن شوید که Event implements `ShouldBroadcast` دارد
- لاگ‌های Reverb را بررسی کنید

---

**موفق باشید! 🎉**
