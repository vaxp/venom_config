# دليل مطور نظام Venom (Venom Developer Guide)

هذا الدليل يشرح كيفية ربط تطبيقاتك بنظام التحكم المركزي **Venom Configuration System (VCS)**.

## 🛠️ نظرة عامة (Architecture)

النظام يعتمد على مبدأ **"مصدر الحقيقة الواحد" (Single Source of Truth)**.
1.  **تطبيق الإعدادات (Settings App):** هو الوحيد الذي يملك صلاحية **الكتابة**.
2.  **ملف التكوين (`settings.vaxp`):** ملف محلي يخزن القيم بصيغة VAXP السريعة.
3.  **تطبيقات العميل (Client Apps):** تراقب الملف وتستقبل التحديثات **لحظياً**.

---

## 1️⃣ الإعداد (Setup)

أضف مكتبة `venom_config` إلى ملف `pubspec.yaml` في أي تطبيق تريد ربطه (سواء كان عميلاً أو إعدادات).

```yaml
dependencies:
  flutter:
    sdk: flutter
  # أضف المسار المحلي للمكتبة
  venom_config:
    path: /path/to/venom_config
```

في دالة `main()`، يجب تهيئة النظام قبل تشغيل التطبيق:

```dart
import 'package:venom_config/venom_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 تهيئة النظام وبدء المراقبة
  await VenomConfig().init();
  
  runApp(const MyApp());
}
```

---

## 2️⃣ جانب العميل (Client Side) - القراءة والاستماع

هذا الكود يستخدم في التطبيقات التي **تتأثر** بالإعدادات (مثل التيرمينال، المتصفح، مدير الملفات).

### أ. قراءة قيمة مرة واحدة (Get Value)
استخدم هذا إذا كنت تريد القيمة فقط عند بدء التشغيل.

```dart
// قراءة لون الخلفية (مع قيمة افتراضية)
final bgColor = VenomConfig().get('system.background_color', defaultValue: '#000000');

// قراءة حجم الخط
final fontSize = VenomConfig().get('apps.terminal.font_size', defaultValue: 14);
```

### ب. الاستماع للتغييرات لحظياً (Real-time Listening)
هذا هو السحر! استخدم هذا الكود لجعل واجهتك تتحدث تلقائياً.

```dart
class MyResponsiveWidget extends StatefulWidget {
  @override
  _MyResponsiveWidgetState createState() => _MyResponsiveWidgetState();
}

class _MyResponsiveWidgetState extends State<MyResponsiveWidget> {
  // قيم افتراضية
  String _themeMode = 'dark';

  @override
  void initState() {
    super.initState();
    
    // 1. قراءة القيمة الحالية
    _updateValues(VenomConfig().getAll());

    // 2. الاشتراك في التحديثات الحية
    VenomConfig().onConfigChanged.listen((config) {
      // سيتم استدعاء هذا الكود فوراً عند تغيير الإعدادات من أي مكان
      _updateValues(config);
    });
  }

  void _updateValues(Map<String, dynamic> config) {
    if (mounted) {
      setState(() {
        _themeMode = config['system.theme_mode'] ?? 'dark';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _themeMode == 'dark' ? Colors.black : Colors.white,
      child: Text("أنا أتغير تلقائياً!"),
    );
  }
}
```

---

## 3️⃣ جانب الإعدادات (Settings Side) - الكتابة

هذا الكود يستخدم **حصرياً** في تطبيق الإعدادات (Control Center).

### كتابة قيمة (Set Value)
عندما يضغط المستخدم على زر تغيير الإعداد، استدعِ دالة `set`.

```dart
// تغيير الثيم
await VenomConfig().set('system.theme_mode', 'light');

// تغيير لون النظام
await VenomConfig().set('system.accent_color', '#FF5722');

// تغيير إعداد خاص بتطبيق معين
await VenomConfig().set('apps.terminal.font_size', 18);
```

> **ملاحظة:** دالة `set` تقوم بحفظ القيمة في الملف فوراً، وتبلغ جميع التطبيقات المفتوحة بالتغيير في أجزاء من الثانية.

---

## 📋 ملخص API

| الدالة | الوصف |
| :--- | :--- |
| `init()` | تهيئة النظام (يجب استدعاؤها في `main`). |
| `get<T>(key, {defaultValue})` | قراءة قيمة مفتاح معين. |
| `getAll()` | قراءة كل الإعدادات كـ `Map`. |
| `set(key, value)` | كتابة قيمة وحفظها ونشرها لكل التطبيقات. |
| `onConfigChanged` | `Stream` يطلق حدثاً عند أي تغيير في الإعدادات. |
