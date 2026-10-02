<div align="center">
  <img src="../tool/branding/icon.svg" width="144" height="144" alt="Avalon Gate icon">
  <h1>Avalon</h1>
  <p><strong>Route · Connect · Control</strong></p>
  <p>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/github/v/release/MasterAlanLab/avalon?display_name=tag&amp;style=flat-square&amp;logo=github&amp;logoColor=white&amp;label=Release&amp;color=E3A72F&amp;cacheSeconds=300" alt="Latest release"></a>
    <a href="https://github.com/MasterAlanLab/avalon/actions/workflows/build.yaml"><img src="https://img.shields.io/github/actions/workflow/status/MasterAlanLab/avalon/build.yaml?style=flat-square&amp;logo=githubactions&amp;logoColor=white&amp;label=Build" alt="Build status"></a>
    <a href="../LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-17191D?style=flat-square&amp;logo=gnu&amp;logoColor=white" alt="AGPL-3.0 license"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Android-arm64%20%7C%20armv7%20%7C%20x86__64-3DDC84?style=flat-square&amp;logo=android&amp;logoColor=white" alt="Android: arm64, armv7, x86_64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Windows-x64-0078D4?style=flat-square&amp;logo=windows11&amp;logoColor=white" alt="Windows: x64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/macOS-ARM64-000000?style=flat-square&amp;logo=apple&amp;logoColor=white" alt="macOS: ARM64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Linux-x64-FCC624?style=flat-square&amp;logo=linux&amp;logoColor=17191D" alt="Linux: x64"></a>
  </p>
</div>

[简体中文](../README.md) · [English](README.en.md) · [العربية](README.ar.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

عميل بروكسي لأنظمة Android وWindows وmacOS وLinux، يعتمد على نواة [mihomo](https://github.com/MetaCubeX/mihomo). يدعم العقد المستقلة وإدارة الاشتراكات وسلاسل البروكسي متعددة القفزات. طُوّر باستخدام Flutter.

> طُوّر Avalon بالاعتماد على [FlClash](https://github.com/chen08209/FlClash).

نزّل حزمة التثبيت المناسبة لنظامك من [Releases](https://github.com/MasterAlanLab/avalon/releases).

## الميزات

- دعم البروتوكولات: VLESS وVMess وShadowsocks وTrojan وHysteria2 وTUIC وAnyTLS وSOCKS4/4a/5 وHTTP(S) وغيرها.
- إدارة العقد: إدارة كل عقدة بشكل مستقل، مع الإضافة والتعديل والنسخ والربط بملفات التعريف.
- إدارة الاشتراكات: استيراد ملفات التعريف من الروابط أو الملفات المحلية، مع التحديث التلقائي للاشتراكات.
- سلاسل البروكسي: الجمع بين العقد ومجموعات البروكسي ونقاط اتصال البروكسي المحلية، مع دعم البروكسي الأمامي والاتصالات متعددة القفزات ومعاينة المسارات.
- إنشاء ملفات التعريف: إنشاء ملفات جاهزة للتشغيل من السلاسل، أو إضافة السلاسل إلى مجموعات البروكسي في ملفات التعريف الحالية.
- الاستيراد والتصدير: دعم روابط URI للعقد ورموز QR وصيغ YAML / JSON، وتصدير العقد والسلاسل في حزمة تشمل مرفقاتها.
- قواعد التوجيه: أوضاع Rule وGlobal وDirect، مع إمكانية تعديل قواعد التوجيه ومجموعات البروكسي.
- تشخيص الشبكة: اختبار زمن استجابة العقد، وعرض الاتصالات في الوقت الفعلي، وسجلات التشغيل.
- مزامنة البيانات: نسخ احتياطي واستعادة محليان، مع المزامنة عبر WebDAV.
- المظهر: واجهات للحاسوب والهاتف، مع الوضع الداكن وتخصيص الألوان.
- Tailscale: عرض الأجهزة وإعداد توجيه Tailnet والشبكات الفرعية البعيدة وعقد الخروج.

## أوضاع التشغيل

| الوضع | الوصف |
| :--- | ---: |
| Rule | اختيار مسار الخروج وفق قواعد ملف التعريف |
| Global | توجيه كل حركة المرور الداخلة إلى النواة عبر مسار الخروج المحدد في مجموعة البروكسي العامة |
| Direct | الاتصال بالوجهة مباشرة دون عقدة بروكسي |

تدعم منصات سطح المكتب بروكسي النظام وTUN، ويستقبل Android حركة المرور عبر خدمة VPN. يشمل بروكسي النظام التطبيقات التي تتبع إعدادات البروكسي فقط، بينما يعتمد نطاق TUN/VPN على المسارات وإعدادات IPv6 والتحكم في الوصول.

## النواة

تتولى [mihomo](https://github.com/MetaCubeX/mihomo) اتصالات البروكسي وحل أسماء DNS والتوجيه القائم على القواعد وحركة مرور TUN. إلى جانب نماذج الإعداد الخاصة بالبروتوكولات، يمكن استخدام Raw YAML / JSON لإعداد أنواع أخرى من عقد mihomo.

تُدمج الاشتراكات ومكتبة العقد وسلاسل البروكسي في إعداد تشغيل موحد. تربط السلاسل القفزات باستخدام `dialer-proxy` بترتيب «العميل ← البروكسي الأمامي ← العقدة الرئيسية ← البروكسي الخلفي ← الوجهة»، ضمن مثيل واحد للنواة.

## التطوير

شغّل الأوامر من جذر المستودع. تستخدم CI إصداري Flutter 3.44.4 وGo 1.26.4؛ وتتطلب المكونات الأصلية أيضًا Rust وأدوات المنصة.

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## التوثيق

- [التطوير والبناء (بالصينية)](development.md): إعداد البيئة وبناء النواة والتطبيق والاختبارات وتوليد الشيفرة وCI.
- [Tailscale (بالصينية)](tailscale.md): تسجيل الدخول والتوجيه وعقد الخروج وإدارة الهوية والمشكلات المعروفة.
- [سير عمل الإصدار](../.github/workflows/build.yaml): إعداد حزم المنصات والنشر.

## التقنيات المستخدمة

- اللغات: Dart وGo وRust
- إطار الواجهة: Flutter / Material Design
- إدارة الحالة: Riverpod
- قاعدة البيانات: SQLite / Drift
- نواة البروكسي: mihomo
- إدارة الحزم: Pub وGo Modules وCargo

## موارد موصى بها

بعض الروابط هي روابط تسويق بالعمولة. قد يحصل المؤلف على عمولة عند التسجيل أو الشراء عبرها. تفاصيل الخدمات وأسعارها موضحة في المواقع المعنية.

| الفئة | المشروع / الخدمة | الوصف |
| ---: | ---: | ---: |
| مجمّع بروكسي | [Free Proxy](https://github.com/MasterAlanLab/free-proxy) | مجمّع بروكسي ذاتي الاستضافة للاستخدام مع مكتبة العقد أو سلاسل البروكسي |
| VPS | [BandwagonHost](https://cutt.ly/qywJNWzd) · [DMIT](https://cutt.ly/YywJIzY0) | استضافة العقد والتطبيقات |
| بطاقات ائتمان افتراضية | [بطاقات افتراضية دولية](https://cutt.ly/IyrMR4Mg) | الدفع للخدمات الدولية |
| البحث عن الموارد | [بوت بحث Telegram](https://cutt.ly/2yeh3GOE) | البحث عن موارد على Telegram |
| الحسابات وشرائح SIM | [حسابات وشرائح SIM دولية](https://cutt.ly/dywt86NC) | خدمات الحسابات والاتصالات |
| متصفح البصمات الرقمية | [BitBrowser](https://client.bitbrowser.cn/register?lang=zh&code=Alan123) | إدارة بيئات متصفح مستقلة |
| استضافة البريد | [Emailbox](https://github.com/MasterAlanLab/emailbox) | إدارة البريد بالجملة وتجميع البروكسيات |
| خدمات CAPTCHA | [Captcha.run](https://captcha.run/sso?inviter=542f4f4f-31b6-4b70-b485-c4762c45d1e8) · [YesCaptcha](https://cutt.ly/Mywt39r0) | التعرف على رموز CAPTCHA |
| واجهات الذكاء الاصطناعي | [وسيط CC / GPT](https://cutt.ly/JywJG3G5) | خدمات واجهات برمجة النماذج |
| مشاركة الاشتراكات | [منصة مشاركة الاشتراكات](https://cutt.ly/5ywt8vb4) | استخدام الاشتراكات بشكل مشترك |

## الترخيص

[AGPL-3.0](../LICENSE). تحتفظ أكواد الأطراف الثالثة بتراخيصها الخاصة. تفاصيل حقوق النشر والتراخيص متاحة في [NOTICE](../NOTICE).

## شكر وتقدير

- [FlClash](https://github.com/chen08209/FlClash)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [Surfboard](https://github.com/getsurfboard/surfboard)
