# سنترود (Centrode)

<p align="center">
  <img src="assets/branding/banner.png" alt="Centrode Banner" width="100%">
</p>

<p align="center">
  <a href="#license"><img src="https://img.shields.io/badge/license-Proprietary-red.svg?style=flat-square" alt="لایسنس"></a>
  <a href="https://github.com/Celestios/Centrode/releases"><img src="https://img.shields.io/badge/version-v0.10.1--preview-blue.svg?style=flat-square" alt="نسخه 0.10.0 پیش‌انتشار"></a>
  <a href="https://github.com/Celestios/Centrode/releases"><img src="https://img.shields.io/badge/platform-Windows%20%7C%20Android-green.svg?style=flat-square" alt="پلتفرم"></a>
  <img src="https://img.shields.io/badge/architecture-Flutter%20%7C%20Rust-orange.svg?style=flat-square" alt="معماری">
  <img src="https://img.shields.io/badge/storage-Local%20First-00D4B2.svg?style=flat-square" alt="ذخیره‌سازی">
</p>

<p align="center">
  <strong>مرکز واحد برای مدیریت دانش شخصی، پیوند ایده‌ها و تفکر بصری.</strong><br>
  <em>چون ذهن شما خطی کار نمی‌کند، ابزارهایتان هم نباید خطی باشند.</em>
</p>

<p align="center">
  <a href="README.md">English</a> • <a href="README_fa.md">فارسی</a>
</p>

---

## پیش‌نمایش تصویری (Visual Preview)

<p align="center">
  <img src="assets/screenshots/canvas_main.png" alt="فضای کار Infinite Canvas در Centrode" width="100%">
  <br>
  <em>محیط Spatial Canvas بی‌نهایت با قابلیت Connection Routing و ساختارهای Nested</em>
</p>

<p align="center">
  <img src="assets/screenshots/workspace_hub.png" alt="هاب پروژه‌ها در Centrode" width="49%">
  <img src="assets/screenshots/container_nesting.png" alt="نودهای تودرتو در Centrode" width="49%">
</p>

---

## سنترود چیست؟

سنترود (Centrode) ابزاری برای مدیریت دانش شخصی بر پایه معماری **Local-First**، کاملاً **Offline** و با تمرکز بر حفظ کامل **Privacy** است که به شما امکان می‌دهد ایده‌ها، پژوهش‌ها و ساختار پروژه‌هایتان را در یک شبکه بصری یکپارچه سازمان‌دهی کنید.

برخلاف ابزارهای مبتنی بر وب یا بسته‌های سنگین Electron، سنترود به‌صورت کاملاً آفلاین اجرا می‌شود و رابط گرافیکی Native Flutter را با Database امبدد در هسته Rust (از طریق Native Bindings پرسرعت) ترکیب می‌کند. تمامی ساختارهای گراف، یادداشت‌ها و فایل‌های پیوست به‌صورت محلی (با سیستم Content-Addressable Asset Management) روی دستگاه شما ذخیره می‌شوند؛ بدون هرگونه وابستگی یا ارسال داده به Cloud یا سرور خارجی. نتیجه این معماری، امنیت کامل، **اجرای آنی (Instant Startup)** و **مصرف حداقلی رم (Minimal RAM Usage)** است.

در حال حاضر برای **ویندوز (نسخه ۶۴ بیتی)** و **اندروید (معماری ARM64)** ارائه می‌شود.

---

## دانلود و نصب (Downloads)

> **توجه:** سنترود در حال حاضر در فاز پیش‌انتشار (Pre-release) قرار دارد. نسخه **v0.10.1-preview** برای آزمایش و ارزیابی روی ویندوز و اندروید در دسترس است.

دریافت فایل‌های نصبی و باینری از [GitHub Releases](https://github.com/Celestios/Centrode/releases/latest):

| پلتفرم | نوع بسته | معماری | لینک دانلود |
| :--- | :--- | :--- | :--- |
| **Windows** | فایل نصبی (Setup Installer) | x64 | [centrode-windows-x64-installer.exe](https://github.com/Celestios/Centrode/releases/download/v0.10.1/centrode-windows-x64-installer.exe) |
| **Windows** | نسخه پرتابل (Portable Zip) | x64 | [centrode-windows-x64.zip](https://github.com/Celestios/Centrode/releases/download/v0.10.1/centrode-windows-x64.zip) |
| **Android** | فایل نصبی APK | ARM64 (v8a) | [app-arm64-v8a-release.apk](https://github.com/Celestios/Centrode/releases/download/v0.10.1/app-arm64-v8a-release.apk) |

*جهت مشاهده یادداشت‌های تغییرات و نسخه‌های پیشین، به [صفحه ریلیزها](https://github.com/Celestios/Centrode/releases) مراجعه فرمایید.*

---

## قابلیت‌های کلیدی (Core Capabilities)

### محیط Workspace پویا و Spatial Canvas
- **Infinite Canvas**: امکان Pan، Zoom و سازمان‌دهی آزادانه اطلاعات در یک فضای کار دو‌بعدی نامحدود.
- **Hierarchical Nodes**: قرار دادن Sub-canvasها و گروه‌های مفهومی در دل Nodeهای والد با انیمیشن‌های نرم زوم (Smooth Zoom Transitions).
- **Structural Frames**: دسته‌بندی و مرزبندی بصری Nodeهای مرتبط به کمک کادرهای اختصاصی Frame.
- **Flexible Node Placement**: ایجاد و چیدمان سریع Nodeها در هر کجای Canvas بدون وقفه در جریان تفکر.
- **Connection Routing**: رسم Connection بین Nodeها با Routing خودکار مسیرها از میان موانع Canvas.

### موتور متن و تایپوگرافی Native
- **پشتیبانی از Markdown**: قالب‌بندی و ویرایش مستقیم متن داخل Nodeها.
- **پشتیبانی از متن دوزبانه (BiDi Text)**: تشخیص خودکار و رندر بی‌نقص متون راست‌به‌چپ (RTL)، چپ‌به‌راست (LTR) و عبارات ترکیبی فارسی و انگلیسی.

---

## نقشه راه (Roadmap & Future Plans)

### اولویت فعلی: پایدارسازی و Performance Optimization
*بهینه‌سازی‌ها و ارتقای فنی در حال انجام در هسته برنامه:*

- [ ] **Performance & Shader Optimization**: پروفایل مصرف RAM و بهینه‌سازی پایپ‌لاین رندر افکت‌های بلور و Liquid Glass.
- [ ] **Routing Stability**: بهبود محاسبات هندسی مسیر Connectionها، حفظ ثبات اشکال و عبور تمیزتر از موانع.
- [ ] **Node & Connection Customization**: توسعه پالت‌های رنگی، استایل‌های بصری جدید و کنترل ظاهر خطوط اتصال.
- [ ] **Portable Packaging (`.cent`)**: قابلیت Export و Import کامل نقشه در قالب یک فایل مستقل شامل ساختار گراف، Schema و Assetها.
- [ ] **Embedded Transformer Intelligence**: مدل‌های On-device سبک برای Semantic Search محلی، تگ‌گذاری هوشمند و پیشنهاد روابط بین ایده‌ها.

### فاز پیش‌رو (Near-Term Pipeline)
*توسعه بخش‌های معماری که بلافاصله پس از فاز پایدارسازی آغاز می‌شوند:*

- [ ] **External Agent Protocol (MCP / API)**: یکپارچه‌سازی عمیق با مدل‌های زبانی بزرگ تولیدی (Generative LLMs) از طریق پروتکل MCP و API اختصاصی؛ شکل‌دهی یک فضای تعاملی مشترک بین انسان و هوش مصنوعی (Collaborative AI-User Dynamic) به‌منظور بررسی، استدلال و گسترش مشارکتی نقشه دانش در کنار شما.
- [ ] **نماهای ساختاری جدید**: ویوهای اختصاصی Timeline و Global Graph Explorer.

### چشم‌انداز بلندمدت (Long-Term Vision)
- [ ] **Integrated Execution System**: معماری پیگیری تسک‌ها، انواع Task Node، تقویم و سیستم زمان‌بندی (Scheduling).

---

## لایسنس (License)

سنترود یک نرم‌افزار انحصاری و سورس‌بسته (Proprietary & Closed-Source) است. تمامی حقوق برای توسعه‌دهنده محفوظ است. مهندسی معکوس، دی‌کامپایل، بازتوزیع یا تکثیر این نرم‌افزار و متعلقات توزیعی آن بدون اجازه مجاز نمی‌باشد.
