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

Cliente proxy para Android, Windows, macOS y Linux, basado en [mihomo](https://github.com/MetaCubeX/mihomo). Admite nodos independientes, gestión de suscripciones y cadenas de proxies de varios saltos. Desarrollado con Flutter.

> Avalon está basado en [FlClash](https://github.com/chen08209/FlClash).

Descarga el paquete de instalación para tu plataforma desde [Releases](https://github.com/MasterAlanLab/avalon/releases).

## Funciones

- Protocolos compatibles: VLESS, VMess, Shadowsocks, Trojan, Hysteria2, TUIC, AnyTLS, SOCKS4/4a/5, HTTP(S) y otros.
- Gestión de nodos: administra nodos individuales de forma independiente; permite añadirlos, editarlos, duplicarlos y vincularlos a perfiles.
- Suscripciones: importa perfiles desde enlaces o archivos locales, con actualización automática de las suscripciones.
- Cadenas de proxies: combina nodos, grupos de proxies y endpoints proxy locales, con proxies previos, conexiones de varios saltos y vista previa de las rutas.
- Generación de perfiles: crea perfiles listos para usar a partir de cadenas o añade cadenas a los grupos de proxies de perfiles existentes.
- Importación y exportación: admite URI de nodos, códigos QR y YAML / JSON; permite exportar nodos y cadenas junto con sus archivos adjuntos en un paquete.
- Reglas de enrutamiento: modos Rule, Global y Direct, con reglas y grupos de proxies editables.
- Diagnóstico de red: pruebas de latencia de nodos, consulta de conexiones en tiempo real y registros de ejecución.
- Sincronización de datos: copia de seguridad y restauración locales, con sincronización mediante WebDAV.
- Temas: diseños para escritorio y móvil, modo oscuro y colores personalizables.
- Tailscale: consulta dispositivos y configura rutas de Tailnet, subredes remotas y nodos de salida.

## Modos de funcionamiento

| Modo | Descripción |
| :--- | :--- |
| Rule | Selecciona la salida según las reglas del perfil |
| Global | Envía todo el tráfico que entra en el núcleo por la salida elegida en el grupo global de proxies |
| Direct | Conecta directamente con el destino, sin un nodo proxy |

En escritorio se admite proxy del sistema y TUN; Android captura tráfico mediante un servicio VPN. El proxy del sistema solo cubre aplicaciones que respetan sus ajustes. TUN/VPN siguen las rutas, la configuración IPv6 y los controles de acceso definidos.

## Motor de proxy

[mihomo](https://github.com/MetaCubeX/mihomo) gestiona las conexiones proxy, la resolución DNS, el enrutamiento por reglas y el tráfico TUN. Además de los formularios específicos de cada protocolo, se puede usar Raw YAML / JSON para configurar otros tipos de nodos de mihomo.

Las suscripciones, la biblioteca de nodos y las cadenas de proxies se integran en una única configuración de ejecución. Las cadenas enlazan cada salto mediante `dialer-proxy`, en el orden «cliente → proxy previo → nodo principal → proxy posterior → destino», dentro de una sola instancia del núcleo.

## Desarrollo

Ejecuta los comandos desde la raíz del repositorio. La CI usa Flutter 3.44.4 y Go 1.26.4; los componentes nativos también requieren Rust y las herramientas de cada plataforma.

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## Documentación

- [Desarrollo y compilación (chino)](development.md): entorno, compilación del núcleo y la aplicación, pruebas, generación de código y CI.
- [Tailscale (chino)](tailscale.md): inicio de sesión, rutas, nodos de salida, identidad y problemas conocidos.
- [Flujo de publicación](../.github/workflows/build.yaml): empaquetado por plataforma y configuración de versiones.

## Tecnologías

- Lenguajes: Dart, Go, Rust
- Framework de interfaz: Flutter / Material Design
- Gestión de estado: Riverpod
- Base de datos: SQLite / Drift
- Núcleo proxy: mihomo
- Gestión de paquetes: Pub, Go Modules, Cargo

## Recursos recomendados

Algunos enlaces son de afiliación. El autor puede recibir una comisión si te registras o compras a través de ellos. Los servicios y precios se detallan en los sitios correspondientes.

| Categoría | Proyecto / Servicio | Descripción |
| :--- | :--- | :--- |
| Pool de proxies | [Free Proxy](https://github.com/MasterAlanLab/free-proxy) | Pool autohospedado para la biblioteca de nodos o las cadenas de proxies |
| VPS | [BandwagonHost](https://cutt.ly/qywJNWzd) · [DMIT](https://cutt.ly/YywJIzY0) | Alojamiento de nodos y aplicaciones |
| Tarjetas de crédito virtuales | [Tarjetas virtuales internacionales](https://cutt.ly/IyrMR4Mg) | Pagos de servicios internacionales |
| Búsqueda de recursos | [Bot de búsqueda de Telegram](https://cutt.ly/2yeh3GOE) | Búsqueda de recursos en Telegram |
| Cuentas y tarjetas SIM | [Cuentas y tarjetas SIM internacionales](https://cutt.ly/dywt86NC) | Servicios de cuentas y comunicación |
| Navegador con huella digital | [BitBrowser](https://client.bitbrowser.cn/register?lang=zh&code=Alan123) | Gestión de entornos de navegador independientes |
| Alojamiento de correo | [Emailbox](https://github.com/MasterAlanLab/emailbox) | Gestión de correo en lotes y agrupación de proxies |
| Servicios CAPTCHA | [Captcha.run](https://captcha.run/sso?inviter=542f4f4f-31b6-4b70-b485-c4762c45d1e8) · [YesCaptcha](https://cutt.ly/Mywt39r0) | Reconocimiento de CAPTCHA |
| API de IA | [Intermediario CC / GPT](https://cutt.ly/JywJG3G5) | Servicios de API de modelos |
| Suscripciones compartidas | [Plataforma de suscripciones compartidas](https://cutt.ly/5ywt8vb4) | Uso compartido de suscripciones |

## Licencia

[AGPL-3.0](../LICENSE). El código de terceros conserva sus respectivas licencias. Consulta [NOTICE](../NOTICE) para ver los avisos de derechos de autor y licencias.

## Agradecimientos

- [FlClash](https://github.com/chen08209/FlClash)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [Surfboard](https://github.com/getsurfboard/surfboard)
