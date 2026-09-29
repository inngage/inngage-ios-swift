# CLAUDE.md — InngageSDK (package Swift 2.0.0)

Guia para agentes de IA (e desenvolvedores) trabalhando no **código-fonte da SDK**. Leia antes de alterar qualquer arquivo. Este é o local da **lógica de negócio** da Inngage para iOS — o app de exemplo apenas a consome.

## O que é

`InngageSDK` é uma biblioteca Swift (Swift Package Manager) para integração com os serviços da Inngage: registro de assinante (push), event tracking, reporte de status de notificação e in-app messages (inclusive rich content / carrossel).

- **Plataforma:** iOS 14+ (`Package.swift`). *Obs.: a docc menciona iOS 15/Xcode 14 — inconsistência a alinhar.*
- **Swift tools:** 5.7
- **Dependência externa:** [`SDWebImageSwiftUI`](https://github.com/SDWebImage/SDWebImageSwiftUI) (imagens das in-app).
- **Agnóstica de Firebase:** a SDK **não** depende de Firebase. O app host obtém o token FCM e o passa via `registerSubscriber(fcmToken:)`.
- **Backend:** `https://api.inngage.com.br` (endpoints em `Services/Networking/ApiManager.swift`).

## Arquitetura

Camadas (em `Sources/InngageSDK/`):

```
Core/        Fachada pública + composição
  InngageSDK.swift          -> classe pública `InngageSDK.shared` (a API)
  InngageInApp.swift        -> View SwiftUI pública das in-app
  Abstractions.swift        -> protocolos (APIClient, DeviceInfoProvider, AppInfoProvider, PayloadStore)
  Providers.swift           -> implementações default dos protocolos + DateTracker
Models/      DTOs de rede (Encodable): Event, Subscribe, Notification, InApp, RichContent
Services/    Casos de uso
  SubscriberOrchestrator.swift  -> monta o payload de subscribe (DI via protocolos)
  SubscribeService.swift        -> LEGADO/duplicado (ver backlog)
  EventService.swift            -> envio de evento
  NotificationService.swift     -> reporte de status de notificação
  LocationService.swift         -> geolocalização opt-in (CoreLocation, async)
  Networking/ApiManager.swift   -> camada HTTP (URLSession)
Utils/       AnyCodable, ColorHex, DataParser, InngageAnalytics (UTM),
             InngageImageHelper, InngageLogger, InngageProperties (estado global)
View/        Componentes SwiftUI das in-app (Button, Carrousel, BaseInAppView,
             InAppNormal, InAppBackgroundImage, InAppRichContent)
```

**Fluxo de registro (caminho recomendado):**
`InngageSDK.registerSubscriber(...)` → monta `SubscribeInput` → `SubscriberOrchestrator.register(...)` → (opcional `LocationService`) → `Subscribe` payload → `APIClient` (`DefaultAPIClient` → `ApiManager.sendSubscriptionRequest`) → `POST /v1/subscription/`.

O design com `Abstractions` + `Providers` é **protocol-oriented com injeção de dependência** — feito para ser testável (dá para injetar um `APIClient`/`DeviceInfoProvider` fake). Preservar esse padrão ao evoluir.

## API pública (contrato a manter estável)

O ponto de entrada pretendido é a fachada **`InngageSDK.shared`**:

```swift
public func registerSubscriber(appToken:identifier:fcmToken:email:phoneNumber:customFields:requestGeolocation:) async
public func sendEvent(eventName:appToken:identifier:registration:eventValues:conversionEvent:conversionValue:conversionNotId:) async
public func handleNotificationInteraction(data: [AnyHashable: Any]) async
```

Mais a view `public struct InngageInApp: View`.

> ⚠️ Hoje também estão `public` vários tipos que **deveriam ser internos** (`EventService`, `NotificationService`, `SubscriberOrchestrator`, `LocationService`, `ApiManager`, `SubscribeInput`). Ver backlog — reduzir a superfície pública é uma melhoria prioritária.

## Regras para alterar a SDK

- **Não** vazar detalhes de implementação como `public`. Só a fachada, a view e os modelos estritamente necessários devem ser públicos.
- Toda I/O de rede passa pelo `ApiManager`. Não criar `URLSession` avulso em services.
- Manter os services sem estado de UI; a apresentação fica em `View/`.
- Preservar a injeção via protocolos (`Abstractions`/`Providers`) — não instanciar dependências concretas dentro dos casos de uso quando houver protocolo.
- Logs sempre via `InngageLogger` (nunca `print` — há vários `print` a migrar).
- Versão da SDK: **fonte única de verdade** (ver backlog); não espalhar string de versão hardcoded.
- Qualquer mudança de API pública deve ser refletida no app de exemplo e na docc.

## Backlog de melhorias (estrutural & arquitetura)

Priorizado. Itens 🔴 têm impacto funcional.

> **Rodada 1 (concluída):** ✅ itens 1, 2, 3, 4, 5, 7, 12; parciais 6 (removido só o protocolo morto `PayloadStore`; fila offline pendente), 9 (aceita 2xx e mapeia `InngageError`; timeout/retry/auth pendentes) e 10 (deduplicado `DynamicKey`; unificação via `AnyCodable` pendente). **Pendentes:** 8 (concorrência/Swift 6), 11 (suíte de testes real — só há testes mínimos de verificação).

1. ✅ 🔴 **`appToken` não persistido quebra o reporte de abertura.** `registerSubscriber(...)` monta o `SubscribeInput` mas **não popula** `InngageProperties.shared` (appToken/identifier/registration). Já `handleNotificationInteraction(...)` usa `properties.appToken` e `EventService` faz fallback para `props.identifier/registration`. Resultado: após um registro "normal", o reporte de status de notificação envia `appToken` vazio. **Corrigir:** popular `InngageProperties` no fluxo de registro (fonte única do estado da sessão).
2. ✅ 🔴 **Erros são engolidos.** Os métodos `async` públicos retornam `Void` e apenas logam falhas (`InngageLogger.log`). O integrador não sabe se o registro/evento teve sucesso. **Corrigir:** propagar resultado (`throws` ou `Result`/status), sem quebrar a ergonomia.
3. ✅ 🟠 **Código duplicado / legado: `SubscriberService` vs `SubscriberOrchestrator`.** Ambos montam `Subscribe` e postam; a lógica de `DateTracker` (install/update ISO8601) está duplicada em `SubscriberService` e em `Providers.swift`. `SubscriberService` está inclusive comentado em `InngageSDK.swift`. **Corrigir:** remover `SubscriberService` e centralizar datas em `DateTracker`.
4. ✅ 🟠 **Versão da SDK inconsistente e espalhada.** Constante `sdkVersion = "1.0.3"` aparece em `SubscriberService` e `SubscriberOrchestrator`; a pasta é `2.0.0`; o app consome `v1.0.2`; a docc diz iOS 15. **Corrigir:** um único `InngageSDK.version` (ou ler do bundle) e alinhar docc/Package/pasta.
5. ✅ 🟠 **Superfície pública ampla demais.** Marcar como `internal` os tipos de implementação (services, orchestrator, `ApiManager`, `SubscribeInput`). Reduz o contrato a manter e evita uso indevido.
6. ◑ 🟡 **`PayloadStore` declarado mas não usado.** Protocolo de persistência (savePending/load/clear) sem implementação; não há retry offline — falhas de subscribe/evento se perdem. **Decidir:** implementar fila offline ou remover o protocolo morto.
7. ✅ 🟡 **API deprecada `UIApplication.shared.keyWindow`** em `InngageSDK.handleNotificationInteraction` (apresentação do `SFSafariViewController`). Sob cenas, pode ser `nil`. **Corrigir:** obter o top VC via `connectedScenes`.
8. 🟡 **Concorrência / thread-safety.** `InngageProperties.shared` é um singleton **mutável** (`static var shared`) acessado de contextos `async` sem sincronização. Preparar para Swift 6 (isolamento, `Sendable`); evitar `static var` reatribuível.
9. ◑ 🟡 **Networking minimalista.** `ApiManager` fixa a base URL, trata só HTTP `200` como sucesso (ignora 201/204), sem timeout/retry/cabeçalho de auth. Rever conforme necessidade do backend.
10. ◑ 🟡 **Modelos com `Encodable` manual e `DynamicKey` duplicado** em `Event.swift` e `Subscribe.swift`. Existe `Utils/AnyCodable.swift` que pode unificar a serialização de `[String: Any]`.
11. 🟡 **Testes vazios.** `InngageSDKTests` só tem stubs. O design é testável de propósito — adicionar testes reais (ex.: orchestrator com `APIClient` fake, serialização de `Event`/`Subscribe`, extração de UTM em `InngageAnalytics`).
12. ✅ 🔵 **Código morto / cosmético.** `InngageInApp.handleDeepLink()` só faz `print`; `#Preview` comentado; docc (`InngageSDK.md`) cortada na seção "Instalação" — completar com exemplos de uso.

## Build & test

```bash
# Na raiz do package:
swift build
swift test
# ou abrir InngageSDK.xcodeproj / o workspace e rodar o scheme InngageSDK
```

## Ao concluir uma alteração

- Rodar `swift build` e `swift test`.
- Se mexeu em API pública: atualizar o app de exemplo e a docc.
- Se corrigiu um item do backlog acima: removê-lo/atualizá-lo neste arquivo.
