# InngageSDK

**InngageSDK** é uma biblioteca Swift para facilitar a integração com os serviços de notificação e conteúdo rico da [Inngage](https://www.inngage.com.br/), incluindo suporte a push notifications com Firebase, mensagens ricas com SDWebImageSwiftUI e funcionalidades customizadas para engajamento do usuário.

---

## 📲 Requisitos

- iOS 14.0+
- Swift 5.7+
- Xcode 14+
- Firebase Messaging
- Swift Package Manager

---

## 🔧 Instalação

### ✅ Swift Package Manager (via GitHub)

Adicione a dependência ao seu projeto através do Xcode:

1. **File → Add Package Dependencies…**
2. Informe a URL `https://github.com/inngage/inngage-ios-swift`
3. Selecione a versão desejada (ex.: `2.1.0`) e adicione o produto `InngageSDK` ao target do app.

```swift
import InngageSDK
```

---

## 👤 Registro de assinante

Após obter o token FCM (o app host é responsável pelo Firebase), registre o assinante:

```swift
try await InngageSDK.shared.registerSubscriber(
    appToken: "YOUR_APP_TOKEN",
    identifier: "USER_ID",          // opcional; vazio/nil = identifier anônimo estável
    fcmToken: fcmToken,
    email: nil,
    phoneNumber: nil,
    customFields: ["plan": "pro"],
    requestGeolocation: false,
    blockDeepLink: false
)
```

| Parâmetro | Default | Descrição |
|-----------|---------|-----------|
| `identifier` | `nil` | Identificador do usuário. Se ausente, a SDK gera e persiste um `UUID` anônimo. |
| `email`, `phoneNumber` | `nil` | Dados de contato do assinante. |
| `customFields` | `nil` | Campos customizados enviados no subscribe. |
| `requestGeolocation` | `false` | Solicita a localização (o app host deve declarar `NSLocationWhenInUseUsageDescription`). |
| `blockDeepLink` | `false` | Quando `true`, a SDK **não abre o link do push** ao tocar na notificação — nem `deep` (browser) nem `inapp` (webview interna). Ver abaixo. |

### `blockDeepLink`

- Vale a partir do último `registerSubscriber` e **persiste entre execuções** (inclusive quando o tap no push ocorre com o app encerrado). Um novo `registerSubscriber` com `false` reverte o bloqueio.
- O reporte de abertura da notificação (`notId`) **continua sendo enviado**; apenas a navegação é suprimida.
- Não afeta os botões das in-app messages (`InngageInApp`).
- Use quando o app quiser tratar a URL do push por conta própria (ex.: roteamento interno via `userInfo["url"]`).

---

## 🔔 Tap na notificação

No `UNUserNotificationCenterDelegate`, repasse o `userInfo` para a SDK. Ela reporta a abertura e roteia o link conforme `type`:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse) async {
    let userInfo = response.notification.request.content.userInfo
    do {
        try await InngageSDK.shared.handleNotificationInteraction(data: userInfo)
    } catch {
        // trate o erro (ex.: log)
    }
}
```

| `type` no payload | Ação da SDK | Com `blockDeepLink: true` |
|-------------------|-------------|---------------------------|
| `deep` | Abre a `url` via `UIApplication.open` (browser ou app dono do scheme). | Não abre. |
| `inapp` | Abre a `url` em `SFSafariViewController` (webview interna). | Não abre. |
| outro / ausente | Nada; apenas log (`InngageLogger`). | Nada. |

---

## 🗒️ Versões

- **2.1.0** — adiciona `blockDeepLink` a `registerSubscriber` (bloqueia o tratamento de `deep`/`inapp` no tap da notificação).
- **2.0.0** — fachada `InngageSDK.shared` com métodos `async throws`, sessão persistida, identifier anônimo.
