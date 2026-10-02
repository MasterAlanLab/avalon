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

Client proxy per Android, Windows, macOS e Linux, basato su [mihomo](https://github.com/MetaCubeX/mihomo). Supporta nodi indipendenti, gestione delle sottoscrizioni e catene di proxy multi-hop. Sviluppato con Flutter.

> Avalon è basato su [FlClash](https://github.com/chen08209/FlClash).

Scarica il pacchetto di installazione per la tua piattaforma da [Releases](https://github.com/MasterAlanLab/avalon/releases).

## Funzionalità

- Protocolli supportati: VLESS, VMess, Shadowsocks, Trojan, Hysteria2, TUIC, AnyTLS, SOCKS4/4a/5, HTTP(S) e altri.
- Gestione dei nodi: gestisci i singoli nodi in modo indipendente, aggiungendoli, modificandoli, duplicandoli e associandoli ai profili.
- Sottoscrizioni: importa profili da URL o file locali, con aggiornamento automatico delle sottoscrizioni.
- Catene di proxy: combina nodi, gruppi di proxy ed endpoint proxy locali, con proxy a monte, connessioni multi-hop e anteprima dei percorsi.
- Generazione dei profili: crea profili pronti all'uso a partire dalle catene oppure aggiungi le catene ai gruppi di proxy dei profili esistenti.
- Importazione ed esportazione: supporto per URI dei nodi, codici QR e YAML / JSON; esportazione di nodi e catene in un pacchetto con i relativi allegati.
- Regole di instradamento: modalità Rule, Global e Direct, con regole e gruppi di proxy modificabili.
- Diagnostica di rete: test di latenza dei nodi, visualizzazione delle connessioni in tempo reale e log di esecuzione.
- Sincronizzazione dei dati: backup e ripristino locali, con sincronizzazione tramite WebDAV.
- Temi: layout per desktop e dispositivi mobili, modalità scura e colori personalizzabili.
- Tailscale: visualizzazione dei dispositivi e configurazione di routing Tailnet, sottoreti remote e nodi di uscita.

## Modalità operative

| Modalità | Descrizione |
| :--- | :--- |
| Rule | Seleziona l'uscita in base alle regole del profilo |
| Global | Invia tutto il traffico che entra nel core attraverso l'uscita selezionata nel gruppo proxy globale |
| Direct | Si connette direttamente alla destinazione, senza un nodo proxy |

Le piattaforme desktop supportano proxy di sistema e TUN; Android acquisisce il traffico tramite un servizio VPN. Il proxy di sistema copre solo le app che ne rispettano le impostazioni. TUN/VPN seguono le rotte, le impostazioni IPv6 e i controlli di accesso configurati.

## Motore proxy

[mihomo](https://github.com/MetaCubeX/mihomo) gestisce le connessioni proxy, la risoluzione DNS, l'instradamento basato su regole e il traffico TUN. Oltre ai moduli specifici per protocollo, è possibile usare Raw YAML / JSON per configurare altri tipi di nodi mihomo.

Sottoscrizioni, libreria dei nodi e catene di proxy confluiscono in un'unica configurazione di esecuzione. Le catene collegano i vari hop tramite `dialer-proxy`, nell'ordine «client → proxy a monte → nodo principale → proxy a valle → destinazione», all'interno di una sola istanza del core.

## Sviluppo

Eseguire dalla radice del repository. La CI usa Flutter 3.44.4 e Go 1.26.4; i componenti nativi richiedono anche Rust e le toolchain delle piattaforme.

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## Documentazione

- [Sviluppo e compilazione (cinese)](development.md): ambiente, build del core e dell’app, test, generazione del codice e CI.
- [Tailscale (cinese)](tailscale.md): accesso, routing, nodi di uscita, identità e problemi noti.
- [Workflow di rilascio](../.github/workflows/build.yaml): pacchetti per piattaforma e configurazione dei rilasci.

## Stack tecnologico

- Linguaggi: Dart, Go, Rust
- Framework UI: Flutter / Material Design
- Gestione dello stato: Riverpod
- Database: SQLite / Drift
- Core proxy: mihomo
- Gestione dei pacchetti: Pub, Go Modules, Cargo

## Risorse consigliate

Alcuni link sono affiliati. L'autore può ricevere una commissione in caso di registrazione o acquisto tramite questi link. Dettagli dei servizi e prezzi sono indicati sui rispettivi siti.

| Categoria | Progetto / Servizio | Descrizione |
| :--- | :--- | :--- |
| Pool di proxy | [Free Proxy](https://github.com/MasterAlanLab/free-proxy) | Pool autogestito da usare con la libreria dei nodi o le catene di proxy |
| VPS | [BandwagonHost](https://cutt.ly/qywJNWzd) · [DMIT](https://cutt.ly/YywJIzY0) | Hosting di nodi e applicazioni |
| Carte di credito virtuali | [Carte virtuali internazionali](https://cutt.ly/IyrMR4Mg) | Pagamenti per servizi internazionali |
| Ricerca di risorse | [Bot di ricerca Telegram](https://cutt.ly/2yeh3GOE) | Ricerca di risorse su Telegram |
| Account e SIM | [Account e SIM internazionali](https://cutt.ly/dywt86NC) | Servizi di account e comunicazione |
| Browser con fingerprint | [BitBrowser](https://client.bitbrowser.cn/register?lang=zh&code=Alan123) | Gestione di ambienti browser indipendenti |
| Hosting email | [Emailbox](https://github.com/MasterAlanLab/emailbox) | Gestione in blocco delle email e raggruppamento dei proxy |
| Servizi CAPTCHA | [Captcha.run](https://captcha.run/sso?inviter=542f4f4f-31b6-4b70-b485-c4762c45d1e8) · [YesCaptcha](https://cutt.ly/Mywt39r0) | Riconoscimento CAPTCHA |
| API di IA | [Relay CC / GPT](https://cutt.ly/JywJG3G5) | Servizi API per modelli |
| Abbonamenti condivisi | [Piattaforma di abbonamenti condivisi](https://cutt.ly/5ywt8vb4) | Condivisione degli abbonamenti |

## Licenza

[AGPL-3.0](../LICENSE). Il codice di terze parti mantiene le rispettive licenze. Le informazioni su copyright e licenze sono in [NOTICE](../NOTICE).

## Ringraziamenti

- [FlClash](https://github.com/chen08209/FlClash)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [Surfboard](https://github.com/getsurfboard/surfboard)
