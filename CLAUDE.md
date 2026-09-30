# CLAUDE.md — InngageSDK (package Swift 2.1.0)

Guia para agentes de IA (e desenvolvedores) trabalhando no **código-fonte da SDK**. Leia antes de alterar qualquer arquivo. Este é o local da **lógica de negócio** da Inngage para iOS — o app de exemplo (`InngageSwift`, no diretório irmão `../InngageSwift`) apenas a consome via `XCLocalSwiftPackageReference "../inngage-ios-swift-2.0.0"`.

## 1. Escopo do projeto

`InngageSDK` é uma biblioteca Swift (Swift Package Manager) para integração com os serviços da Inngage:

- registro de assinante (push) — `POST /v1/subscription/`;
- event tracking, inclusive eventos de conversão — `POST /v1/events/newEvent/`;
- reporte de status/abertura de notificação — `POST /v1/notification/`;
- in-app messages em SwiftUI (normal, com imagem de fundo e rich content / carrossel);
- utilitários para o app host: extração de UTM do payload (`InngageAnalytics`) e anexos de imagem em notificação (`InngageImageHelper`).

**Está fora do escopo da SDK:** obter o token FCM/APNs (o app host obtém e passa via `registerSubscriber(fcmToken:)`), pedir permissão de push, arquitetura do app host, telas de demonstração. A SDK é **agnóstica de Firebase** — não adicionar dependência do Firebase aqui.

Nomenclatura: a pasta é `inngage-ios-swift-2.0.0` (nome histórico), o produto/target é `InngageSDK` e a versão reportada ao backend vem de `InngageVersion.current` (`"2.1.0"`).

## 2. Stack e comandos

| Item | Valor |
|------|-------|
| Plataforma | iOS 14+ (`Package.swift`) |
| Swift tools | 5.7 (`// swift-tools-version:5.7`) |
| Dependência externa | [`SDWebImageSwiftUI`](https://github.com/SDWebImage/SDWebImageSwiftUI) ≥ 3.1.3 (imagens das in-app) |
| Frameworks Apple | Foundation, UIKit, SwiftUI, SafariServices, CoreLocation, UserNotifications |
| Backend | `https://api.inngage.com.br` (base URL e endpoints em `Services/Networking/ApiManager.swift`) |
| Testes | XCTest em `Tests/InngageSDKTests/` (target `InngageSDKTests`) |
| Lint / E2E | **Não configurados.** Não inventar comandos de lint ou E2E. |

### Comandos que funcionam

```bash
# Build da SDK para iOS Simulator (não exige runtime de simulador instalado)
xcodebuild -workspace .swiftpm/xcode/package.xcworkspace -scheme InngageSDK \
  -destination 'generic/platform=iOS Simulator' build

# Suíte completa de testes (EXIGE um runtime de simulador iOS instalado; ajuste o nome do device)
xcodebuild -workspace .swiftpm/xcode/package.xcworkspace -scheme InngageSDK \
  -destination 'platform=iOS Simulator,name=iPhone 17' test

# Teste direcionado
xcodebuild -workspace .swiftpm/xcode/package.xcworkspace -scheme InngageSDK \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:InngageSDKTests/InngageSDKTests/testRegisterPropagatesError test
```

Alternativa: abrir `../InngageSwiftSDK.xcworkspace` (contém o app `InngageSwift`, que referencia este package localmente) e usar o scheme `InngageSDK` no Xcode.

### Ressalvas (verificadas)

- **`swift build` / `swift test` NÃO funcionam no host macOS**: a SDK importa `UIKit` e o package declara só iOS. Erro: `unable to resolve module dependency: 'UIKit'`. Não proponha esses comandos.
- **`InngageSDK.xcodeproj` está desatualizado**: referencia arquivos individualmente e não inclui `DynamicKey`, `SubscriberOrchestrator`, `InngageError`, `InngageVersion` etc. `xcodebuild` sem `-workspace` usa esse projeto e falha. Use o `package.xcworkspace` acima ou o workspace do app. Fonte canônica dos fontes é o `Package.swift` (pasta `Sources/InngageSDK`).
- `.swiftpm/xcode/package.xcworkspace` é gerado pelo Xcode ao abrir o package; em um clone novo pode não existir até abrir o package no Xcode.
- Sem runtime de simulador iOS instalado, a execução de testes falha; relate como "validação não executada", não como sucesso.

## 3. Arquitetura

Camadas (em `Sources/InngageSDK/`), organizadas por responsabilidade:

```
Core/        Fachada pública + composição
  InngageSDK.swift          -> classe pública `InngageSDK.shared` (a API)
  InngageInApp.swift        -> View SwiftUI pública das in-app
  Abstractions.swift        -> protocolos (APIClient, DeviceInfoProvider, AppInfoProvider)
  Providers.swift           -> implementações default dos protocolos + DateTracker
Models/      DTOs de rede (Encodable): Event, Subscribe, Notification, InApp, RichContent
Services/    Casos de uso (internal)
  SubscriberOrchestrator.swift  -> monta o payload de subscribe (DI via protocolos)
  EventService.swift            -> envio de evento (fallback de identifier/registration via sessão)
  NotificationService.swift     -> reporte de status de notificação
  NotificationLinkResolver.swift -> decide a ação para o link do push (deep/inapp/bloqueado), função pura
  LocationService.swift         -> geolocalização opt-in (CoreLocation, async)
  SubscribeService.swift        -> TOMBSTONE (só comentário; código legado em `_to_delete/`)
  Networking/ApiManager.swift   -> camada HTTP única (URLSession, JSON, mapeia InngageError)
Utils/       AnyCodable, ColorHex, DataParser, DynamicKey, InngageAnalytics (UTM),
             InngageError, InngageImageHelper, InngageLogger, InngageSession
             (estado de sessão em `actor`, persistido em UserDefaults), InngageVersion,
             UIApplication+TopViewController
View/        Componentes SwiftUI das in-app (Button, Carrousel, BaseInAppView,
             InAppNormal, InAppBackgroundImage, InAppRichContent)
InngageSDK.docc/  Documentação (InngageSDK.md)
```

O design com `Abstractions` + `Providers` é **protocol-oriented com injeção de dependência** — feito para ser testável (`SubscriberOrchestrator(api: FakeAPIClient())`, `InngageSession(defaults: UserDefaults(suiteName:))`). Preservar esse padrão ao evoluir.

### Regras de preservação e organização

- **Cada arquivo na camada certa.** Regra de negócio em `Services/`, DTO em `Models/`, apresentação em `View/`, utilitário sem estado de domínio em `Utils/`. Não criar novas pastas de topo sem justificar no plano técnico.
- **Fachada única.** Toda funcionalidade exposta ao integrador entra por `InngageSDK.shared` (ou pela view `InngageInApp`). Não criar novos singletons públicos.
- **Rede só pelo `ApiManager`.** Não criar `URLSession` avulso em services/views. Novo endpoint = novo case em `APIEndpoint` + método em `ApiManager` + DTO em `Models/`.
- **Preservar a injeção via protocolos.** Não instanciar dependências concretas dentro de casos de uso quando houver protocolo; novas dependências externas ganham protocolo em `Abstractions.swift` e default em `Providers.swift`.
- **Services sem estado de UI**; apresentação e `@State` ficam em `View/`.
- **Estado de sessão só em `InngageSession`** (`actor`). Não reintroduzir `static var` mutável compartilhado. Manter compatibilidade com Swift 6 (isolamento verificado, `Sendable`).
- **Logs só via `InngageLogger.log`** (desligado por padrão; `isLoggingEnabled`). Nunca `print` — restam 2 em `View/InAppView/InAppRichContent.swift` a migrar.
- **Versão em um único lugar:** `InngageVersion.current`. Nunca espalhar string de versão.
- **Visibilidade mínima.** `internal` por padrão; `public` somente no que está listado em "Compatibilidade de API". Não vazar detalhes de implementação.
- **Sem lógica do app de exemplo na SDK** e vice-versa.

## 4. Compatibilidade de API

### Superfície pública (contrato a manter estável)

```swift
// Core/InngageSDK.swift
public class InngageSDK { public static let shared: InngageSDK }
public func registerSubscriber(appToken:identifier:fcmToken:email:phoneNumber:customFields:requestGeolocation:blockDeepLink:) async throws
public func sendEvent(eventName:appToken:identifier:registration:eventValues:conversionEvent:conversionValue:conversionNotId:) async throws
public func handleNotificationInteraction(data: [AnyHashable: Any]) async throws

// Core/InngageInApp.swift
public struct InngageInApp: View
public init(data:isShowing:actionButtonRight:hasActionButtonRight:actionButtonLeft:hasActionButtonLeft:onDismissed:)

// Utils
public enum InngageError: Error { case badURL; case invalidResponse(status:body:); case network(Error) }
public enum InngageLogger { public static var isLoggingEnabled: Bool; public static func log(_:) }
public class InngageAnalytics { public static func extractUTMEvent(from:) -> (name: String, parameters: [String: Any])? }
public class InngageImageHelper { public static func attachment(from:completion:) }
public struct AnyCodable: Codable
```

Tudo o mais é `internal` — inclusive `EventService`, `NotificationService`, `NotificationLinkResolver`, `SubscriberOrchestrator`, `SubscribeInput`, `LocationService`, `ApiManager`, `InngageSession`, os DTOs e as views internas. (`InAppRichContent` tem `public init` sobre um `struct` internal — inofensivo, mas não é API pública.)

### Regras de compatibilidade

- **Não remover nem renomear** símbolos públicos, parâmetros ou labels sem: `@available(*, deprecated, renamed:)` mantendo o antigo funcional por pelo menos uma versão minor, entrada em "Como migrar" na docc e atualização do app de exemplo.
- **Novos parâmetros públicos** devem ter valor default para não quebrar chamadas existentes.
- **Semântica do `identifier` opcional:** a API exige identifier; quando o integrador não informa (nil/vazio/em branco), a SDK usa um **identifier anônimo estável** (`UUID` gerado uma vez, persistido em `InngageSession`). Não usar `identifierForVendor` (pode ser `nil` e reseta ao remover todos os apps do vendor → assinante duplicado). O mesmo identifier resolvido é reutilizado por `sendEvent` (fallback) e pelo reporte de abertura. Mudar isso muda a identidade de assinantes em produção — é mudança de contrato.
- **Erros são propagados** (`async throws` com `InngageError`), nunca engolidos. Novos casos de erro só podem ser adicionados em `InngageError` com nota de versão (integradores podem usar `switch` exaustivo).
- **Payloads do backend** (`Subscribe`, `Event`, `Notification` e wrappers `registerSubscriberRequest`, `newEventRequest`, `notificationRequest`) são contrato com `api.inngage.com.br`. Nomes de campo em snake_case são intencionais; não renomear sem alinhamento com o backend. Testes de encoding (`testEventEncodesCustomValues`) protegem isso — adicionar equivalentes ao mexer em DTOs.
- **Formato do payload de push/in-app** consumido por `handleNotificationInteraction` e `InngageInApp` (`notId`, `type` ∈ {`deep`, `inapp`}, `url`, `additional_data.rich_content`, `background_image`) é definido pela plataforma Inngage; tratar chaves ausentes de forma tolerante, nunca com crash.
- **Chaves de `UserDefaults`** (`inngage.session.*`: `appToken`, `identifier`, `registration`, `anonymousId`, `blockDeepLink`) são persistidas no device do usuário final; renomear exige migração.
- **Semântica do `blockDeepLink`** (`registerSubscriber`, default `false`): persistido na sessão; reflete sempre o **último** subscribe; quando `true`, `handleNotificationInteraction` não abre `deep` nem `inapp`, mas continua reportando a abertura (`notId`). Não afeta os botões das in-app messages.
- **Versionamento:** SemVer. Mudança incompatível → major; API nova compatível → minor; correção → patch. Atualizar `InngageVersion.current` e a docc na mesma alteração.

## 5. Segurança e configuração

- **Nunca** commitar `appToken` real, tokens FCM/APNs, chaves `.p8`/`.p12`, `GoogleService-Info.plist` com dados reais ou URLs de ambientes internos. Em testes e docc use placeholders (`"YOUR_APP_TOKEN"`, `"USER_ID"`).
- A SDK **não** embute credenciais; `appToken` é sempre fornecido pelo app host em runtime e guardado apenas em `UserDefaults` (via `InngageSession`) para o reporte de abertura após cold start. Não mover para Keychain nem para memória sem decisão explícita (impacta o fluxo de abertura).
- **Logs** ficam desligados por padrão. `ApiManager` loga request/response completos quando habilitado — isso inclui `appToken`, e-mail, telefone e `customFields`. Não habilitar logging por padrão; não adicionar logs de payload fora do `ApiManager`.
- **Geolocalização** é opt-in (`requestGeolocation: true`) e falha silenciosa é aceitável (registro segue sem lat/long). A SDK não declara `NSLocationWhenInUseUsageDescription` — é responsabilidade do app host; documentar na docc.
- **Rede:** HTTPS fixo; sem cabeçalho de autenticação hoje (ver backlog 9). Qualquer adição de auth passa por `ApiManager` e por revisão de segurança.
- **URLs recebidas em push** (`deep`/`inapp`) são abertas via `UIApplication.open` / `SFSafariViewController`, salvo `blockDeepLink == true` na sessão (a SDK então não abre nada e apenas loga). Não executar JavaScript, não usar `WKWebView` com bridge, não confiar em `type` desconhecido (cai em `.none` no `NotificationLinkResolver`, com log).
- **Arquivos gerados/locais que não devem ser versionados:** `.build/`, `.swiftpm/xcode/xcuserdata/`, `InngageSDK.xcodeproj/xcuserdata/`, `.DS_Store`, `_to_delete/`. O repositório ainda **não tem `.gitignore`** (ver backlog 14) — verificar o diff staged manualmente antes de cada commit.

## 6. Fluxos críticos

Alterações que toquem estes fluxos exigem testes direcionados e validação no app de exemplo.

1. **Registro de assinante**
   `InngageSDK.registerSubscriber(...)` → `InngageSession.resolvedIdentifier` (fallback anônimo) → `InngageSession.update(appToken:identifier:registration:blockDeepLink:)` (persiste) → `SubscribeInput` → `SubscriberOrchestrator.register` → (opcional `LocationService.getCurrentLocation`) → `Subscribe` (com `sdk = InngageVersion.current`, device/app info via providers, `DateTracker` install/update ISO8601) → `APIClient.postSubscription` → `ApiManager.sendSubscriptionRequest` → `POST /v1/subscription/`.
   Riscos: identifier vazio, versão errada no payload, sessão não persistida (quebra o fluxo 3 após cold start).

2. **Envio de evento**
   `sendEvent(...)` → `EventService.sendEvent` → fallback de `identifier`/`registration` pela sessão (e anônimo se a sessão estiver vazia) → `Event` (com `event_values` dinâmicos via `DynamicKey`) → `POST /v1/events/newEvent/`.
   Riscos: encoding de `[String: Any]`, evento de conversão sem `conversion_notid`.

3. **Interação com notificação (tap / abertura)**
   `handleNotificationInteraction(data:)` → se `notId`: `NotificationService.updateNotificationStatus(appToken: session.appToken, notId:)` → `POST /v1/notification/`; depois `NotificationLinkResolver.resolve(type:urlString:blockDeepLink: session.blockDeepLink)` → `.openExternal` (`deep` → `UIApplication.open`), `.openInApp` (`inapp` → `SFSafariViewController` no top VC via `connectedScenes`), `.blocked` (só log) ou `.none` (só log).
   Riscos: `appToken` vazio na sessão (cold start sem registro prévio), apresentação fora da main thread, top VC `nil`, bloqueio ignorado se a flag não estiver persistida. Coberto por `testLinkResolver*`.

4. **In-app message (SwiftUI)**
   `InngageInApp(data:isShowing:...)` → `parseAdditionalData` → escolhe `InAppRichContent` (carrossel) ou `InAppNormal`/`InAppBackgroundImage` → imagens via `SDWebImageSwiftUI` → callbacks de botão e `onDismissed`.
   Riscos: payload malformado, cores hex inválidas (`ColorHex`), regressão visual sem teste automatizado (validar no app de exemplo).

5. **Sessão e identidade**
   `InngageSession` (actor) — única fonte de `appToken`/`identifier`/`registration`/`anonymousId`/`blockDeepLink`, persistida em `UserDefaults`. Coberta por `testAnonymousIdentifierIsStable`, `testResolvedIdentifierFallsBackToAnonymous`, `testSessionPersistsAcrossInstances`, `testBlockDeepLink*`.

## 7. Processo de trabalho

- **Idioma:** documentação, comentários e mensagens ao usuário em português; identificadores de código em inglês.
- **Estilo Swift:** PascalCase para tipos, camelCase para membros; `let` por padrão; sem force unwrap fora de testes; 4 espaços; `async/await` em vez de Combine/callbacks (exceto onde a API da Apple exige, como `InngageImageHelper`); comentários curtos explicando o *porquê* de decisões não óbvias (ver `InngageSession`).
- **Comentários e docs:** manter os comentários existentes que explicam decisões (identifier anônimo, persistência, isolamento). Atualizar a docc (`InngageSDK.docc/InngageSDK.md`) sempre que a API pública ou o fluxo de integração mudar.
- **Testes:** XCTest, com dobles injetados pelos protocolos (`FailingAPIClient`, `CapturingAPIClient`) e `UserDefaults(suiteName:)` isolado por teste. Cada correção de bug ganha um teste que falharia antes. Não testar rede real.
- **Git:** branches `feat/<slug>`, `fix/<slug>`, `chore/<slug>` a partir de `release` sincronizada; Conventional Commits (`feat(session): ...`, `fix(api): ...`, `test(orchestrator): ...`, `docs(claude): ...`, `chore(repo): ...`); `git add` com caminhos explícitos, nunca `git add .`; sem `--force`, sem amend/rebase/reset/stash automáticos. PRs de `<branch>` → `release` no GitHub.
- **Estado atual do repositório (set/2026):** remote `origin` = `https://github.com/inngage/inngage-ios-swift`. A branch `release` (publicada) parte da tag `2.0.0` e contém as Rodadas 1 e 2 commitadas; é a base de todas as branches de trabalho e destino dos PRs. A branch `main` **local** (`Initial Commit`, sem pai) é um resíduo anterior à reconexão com o remoto — não usar como base; `origin/main` continua na tag `2.0.0` até o próximo release.
- **Limite de mudança:** alterar somente o que a demanda pede. Refatorações oportunistas e itens do backlog entram como demanda própria.
- **Relação com o app de exemplo:** qualquer mudança de API pública exige atualizar `../InngageSwift` (que consome este package localmente) e confirmar que ele compila. O exemplo nunca é fonte de verdade da SDK.

## 8. Início e condução de demandas

Toda história, bug, melhoria ou tarefa segue a skill **`iniciar-demanda`** (`.claude/skills/iniciar-demanda/SKILL.md`), que por sua vez usa:

- `.claude/agents/approval-gates.md` — os 11 estados e o que cada aprovação autoriza (revisão → sincronizar `release` → criar branch → plano técnico → implementação → testes → validações → revisão/plano de commits → commits → push → PR);
- `.claude/agents/output-templates.md` — formato do cabeçalho de estado, revisão consolidada, plano técnico, plano de commits e PR.

Regras invariantes:

- A mensagem inicial autoriza **apenas leitura e análise**. Nenhuma operação Git mutável, edição, criação de teste, execução de validação, commit, push ou PR sem a aprovação específica daquele gate.
- Toda resposta traz `Fase atual`, `Concluído` e `Aguardando aprovação` (uma única ação).
- Uma aprovação libera só a próxima ação descrita; "ok" só vale com uma única ação pendente e identificada.
- Mudança material de escopo → parar, explicar, voltar ao gate adequado.
- Dúvida material aberta → não avançar.
- Falha em validação → propor correção e voltar ao gate de implementação/testes; nunca editar direto.

## 9. Critérios de conclusão

Uma demanda só está pronta quando **todos** os itens abaixo forem verdadeiros e evidenciados (saída de comando, diff, hash):

- [ ] Critérios de aceite da revisão consolidada atendidos e conferidos um a um.
- [ ] Build da SDK para iOS Simulator passou (`xcodebuild ... build`, comando da seção 2).
- [ ] Testes direcionados e suíte `InngageSDKTests` executados e verdes — ou explicitamente reportados como **não executados** (ex.: sem runtime de simulador), nunca omitidos.
- [ ] Novo comportamento ou correção coberto por teste que falharia antes da mudança.
- [ ] API pública inalterada, ou alteração compatível documentada (deprecação, default, docc, `InngageVersion.current` ajustado).
- [ ] Payloads do backend e chaves de `UserDefaults` inalterados, ou mudança alinhada e documentada.
- [ ] App de exemplo `../InngageSwift` atualizado e compilando, se a API pública mudou.
- [ ] Nenhum `print`, credencial, arquivo gerado (`.build/`, `xcuserdata/`, `.DS_Store`) ou arquivo fora do escopo no diff.
- [ ] Commits no padrão Conventional Commits, cada um coerente e compilável; branch enviada sem force push; PR para `release` preparado com contexto, alterações, validação, riscos e checklist.
- [ ] Este `CLAUDE.md` atualizado se a demanda mudou arquitetura, comandos, contrato ou fechou um item do backlog.

## 10. Backlog de melhorias (estrutural & arquitetura)

Priorizado. Itens 🔴 têm impacto funcional. Cada item vira uma demanda própria pela skill `iniciar-demanda`.

> **Rodada 1 (concluída):** ✅ itens 1, 2, 3, 4, 5, 7, 12; parciais 6 (removido só o protocolo morto `PayloadStore`; fila offline pendente), 9 (aceita 2xx e mapeia `InngageError`; timeout/retry/auth pendentes) e 10 (deduplicado `DynamicKey`; unificação via `AnyCodable` pendente).
>
> **Rodada 2:** ✅ item 8 (`InngageProperties` → `InngageSession` actor persistido; identifier opcional com fallback anônimo). ◑ item 11 (6 testes reais cobrindo orchestrator, versão, sessão e encoding de `Event`; faltam `Subscribe`, `InngageAnalytics`, `NotificationService`). **Pendentes:** 6 (fila offline), 9 (timeout/retry/auth), 10 (unificar via `AnyCodable`), 11 (ampliar cobertura), 13–16 (higiene do repositório, identificados em set/2026).

1. ✅ 🔴 **`appToken` não persistido quebra o reporte de abertura.** `registerSubscriber(...)` monta o `SubscribeInput` mas **não popula** `InngageProperties.shared` (appToken/identifier/registration). Já `handleNotificationInteraction(...)` usa `properties.appToken` e `EventService` faz fallback para `props.identifier/registration`. Resultado: após um registro "normal", o reporte de status de notificação envia `appToken` vazio. **Corrigir:** popular `InngageProperties` no fluxo de registro (fonte única do estado da sessão).
2. ✅ 🔴 **Erros são engolidos.** Os métodos `async` públicos retornam `Void` e apenas logam falhas (`InngageLogger.log`). O integrador não sabe se o registro/evento teve sucesso. **Corrigir:** propagar resultado (`throws` ou `Result`/status), sem quebrar a ergonomia.
3. ✅ 🟠 **Código duplicado / legado: `SubscriberService` vs `SubscriberOrchestrator`.** Ambos montam `Subscribe` e postam; a lógica de `DateTracker` (install/update ISO8601) está duplicada em `SubscriberService` e em `Providers.swift`. `SubscriberService` está inclusive comentado em `InngageSDK.swift`. **Corrigir:** remover `SubscriberService` e centralizar datas em `DateTracker`.
4. ✅ 🟠 **Versão da SDK inconsistente e espalhada.** Constante `sdkVersion = "1.0.3"` aparece em `SubscriberService` e `SubscriberOrchestrator`; a pasta é `2.0.0`; o app consome `v1.0.2`; a docc diz iOS 15. **Corrigir:** um único `InngageSDK.version` (ou ler do bundle) e alinhar docc/Package/pasta.
5. ✅ 🟠 **Superfície pública ampla demais.** Marcar como `internal` os tipos de implementação (services, orchestrator, `ApiManager`, `SubscribeInput`). Reduz o contrato a manter e evita uso indevido.
6. ◑ 🟡 **`PayloadStore` declarado mas não usado.** Protocolo de persistência (savePending/load/clear) sem implementação; não há retry offline — falhas de subscribe/evento se perdem. **Decidir:** implementar fila offline ou remover o protocolo morto.
7. ✅ 🟡 **API deprecada `UIApplication.shared.keyWindow`** em `InngageSDK.handleNotificationInteraction` (apresentação do `SFSafariViewController`). Sob cenas, pode ser `nil`. **Corrigir:** obter o top VC via `connectedScenes`.
8. ✅ 🟡 **Concorrência / thread-safety.** O antigo `InngageProperties` (singleton `static var` mutável, acessado de contextos `async` sem sincronização) foi substituído por **`InngageSession` (`actor`)** — isolamento verificado pelo compilador (pronto para Swift 6, `Sendable` automático), estado enxuto (só `appToken`/`identifier`/`registration`; removidos os 5 campos mortos) e **persistido em `UserDefaults`**, o que também endurece o item 1 (o reporte de abertura sobrevive ao cold start). Novos testes cobrem estabilidade do id anônimo, fallback do identifier e persistência entre instâncias.
9. ◑ 🟡 **Networking minimalista.** `ApiManager` fixa a base URL, sem timeout/retry/cabeçalho de auth (já aceita 2xx e mapeia `InngageError`). Rever conforme necessidade do backend.
10. ◑ 🟡 **Modelos com `Encodable` manual** em `Event.swift` e `Subscribe.swift` (`DynamicKey` já deduplicado em `Utils/DynamicKey.swift`). Existe `Utils/AnyCodable.swift` que pode unificar a serialização de `[String: Any]`.
11. ◑ 🟡 **Cobertura de testes parcial.** Já existem testes reais para orchestrator (propagação de erro, versão), `InngageSession` e encoding de `Event`. **Faltam:** serialização de `Subscribe` (inclusive `custom_field`/lat-long), `InngageAnalytics.extractUTMEvent`, `NotificationService`, e um teste de `EventService` com `ApiManager` injetável (hoje `EventService`/`NotificationService` dependem do `ApiManager` concreto — candidatos a ganhar protocolo em `Abstractions`).
12. ✅ 🔵 **Código morto / cosmético.** `InngageInApp.handleDeepLink()` só faz `print`; `#Preview` comentado; docc (`InngageSDK.md`) cortada na seção "Instalação" — completar com exemplos de uso.
13. 🟠 **`InngageSDK.xcodeproj` desatualizado.** Não inclui vários fontes atuais (`DynamicKey`, `SubscriberOrchestrator`, `InngageError`, `InngageVersion`…); `xcodebuild` sem `-workspace` falha. **Decidir:** remover o `.xcodeproj` (o package já é abrível diretamente pelo Xcode) ou convertê-lo para grupo sincronizado com a pasta.
14. 🟡 **Sem `.gitignore`.** `.build/`, `.swiftpm/xcode/xcuserdata/` e `InngageSDK.xcodeproj/xcuserdata/` aparecem no `git status` (o `xcschememanagement.plist` de usuário já está rastreado). **Corrigir:** adicionar `.gitignore` (baseado no do app de exemplo) e remover do índice os artefatos de usuário.
15. 🔵 **Resíduos da rodada 1.** `Services/SubscribeService.swift` é só um tombstone e `_to_delete/SubscribeService.swift` guarda o legado; 2 `print` restantes em `View/InAppView/InAppRichContent.swift` (linhas ~67 e ~162). **Corrigir:** apagar ambos os arquivos e migrar os `print` para `InngageLogger`.
16. 🔵 **Docc desalinhada com a SDK.** `InngageSDK.docc/InngageSDK.md` lista "Firebase Messaging" como requisito (a SDK é agnóstica; o requisito é do app host) e não documenta `NSLocationWhenInUseUsageDescription` para `requestGeolocation`. **Corrigir:** revisar requisitos e adicionar seção de permissões.

## Ao concluir uma alteração

- Rodar o build e os testes com os comandos da seção 2 (ou reportar explicitamente o que não pôde ser executado).
- Se mexeu em API pública: atualizar o app de exemplo `../InngageSwift` e a docc.
- Se corrigiu um item do backlog acima: marcá-lo ✅ e atualizar a nota de rodada.
- Conferir a seção 9 (critérios de conclusão) antes de propor o plano de commits.
