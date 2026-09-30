//
//  InngageSDKTests.swift
//  InngageSDKTests
//
//  Created by Saulo Moura on 07/08/24.
//

import XCTest
@testable import InngageSDK

final class InngageSDKTests: XCTestCase {

    // MARK: - Doubles

    /// APIClient que sempre lança — para verificar propagação de erro (item 2).
    private struct FailingAPIClient: APIClient {
        struct Boom: Error {}
        func postSubscription(_ payload: Subscribe) async throws { throw Boom() }
    }

    /// APIClient que sucede e captura o payload enviado (itens 4/10).
    private final class CapturingAPIClient: APIClient {
        var captured: Subscribe?
        func postSubscription(_ payload: Subscribe) async throws { captured = payload }
    }

    // MARK: - Tests

    /// Item 2: uma falha na API deve propagar para quem chamou (não ser engolida).
    func testRegisterPropagatesError() async {
        let sut = SubscriberOrchestrator(api: FailingAPIClient())
        let input = SubscribeInput(
            appToken: "t", identifier: "u", email: nil, phone: nil,
            customFields: nil, requestGeolocation: false, registrationToken: "fcm"
        )
        do {
            try await sut.register(input: input)
            XCTFail("register deveria propagar o erro da API")
        } catch {
            // esperado
        }
    }

    /// Item 4: o payload deve carregar a versão única da SDK.
    func testRegisterUsesCurrentSDKVersion() async throws {
        let api = CapturingAPIClient()
        let sut = SubscriberOrchestrator(api: api)
        let input = SubscribeInput(
            appToken: "t", identifier: "u", email: nil, phone: nil,
            customFields: nil, requestGeolocation: false, registrationToken: "fcm"
        )
        try await sut.register(input: input)
        XCTAssertEqual(api.captured?.sdk, InngageVersion.current)
    }

    // MARK: - InngageSession (item 8 / item 1)

    /// Cria um `UserDefaults` isolado para não vazar estado entre testes.
    private func makeIsolatedDefaults(_ suite: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    /// O identifier anônimo é gerado uma vez e permanece estável entre chamadas.
    func testAnonymousIdentifierIsStable() async {
        let defaults = makeIsolatedDefaults("inngage.tests.anon")
        let session = InngageSession(defaults: defaults)
        let first = await session.anonymousIdentifier()
        let second = await session.anonymousIdentifier()
        XCTAssertFalse(first.isEmpty)
        XCTAssertEqual(first, second)
    }

    /// `resolvedIdentifier` usa o valor do app quando presente e recorre ao
    /// anônimo quando vazio/nil (subscribe nunca vai com identifier vazio).
    func testResolvedIdentifierFallsBackToAnonymous() async {
        let defaults = makeIsolatedDefaults("inngage.tests.resolve")
        let session = InngageSession(defaults: defaults)

        let provided = await session.resolvedIdentifier("user@example.com")
        XCTAssertEqual(provided, "user@example.com")

        let anon = await session.anonymousIdentifier()
        let resolvedNil = await session.resolvedIdentifier(nil)
        let resolvedEmpty = await session.resolvedIdentifier("")
        let resolvedBlank = await session.resolvedIdentifier("   ")
        XCTAssertEqual(resolvedNil, anon)
        XCTAssertEqual(resolvedEmpty, anon)
        XCTAssertEqual(resolvedBlank, anon)
    }

    /// O estado persiste: uma nova instância sobre o mesmo `UserDefaults`
    /// relê os valores (prova o fix de cold start — item 1).
    func testSessionPersistsAcrossInstances() async {
        let suite = "inngage.tests.persist"
        let defaults = makeIsolatedDefaults(suite)
        let session = InngageSession(defaults: defaults)
        await session.update(appToken: "app", identifier: "u", registration: "fcm")

        let reloaded = InngageSession(defaults: defaults)
        let appToken = await reloaded.appToken
        let identifier = await reloaded.identifier
        let registration = await reloaded.registration
        XCTAssertEqual(appToken, "app")
        XCTAssertEqual(identifier, "u")
        XCTAssertEqual(registration, "fcm")
    }

    // MARK: - blockDeepLink (sessão)

    /// Sessão nova (chave ausente no `UserDefaults`) ⇒ bloqueio desligado.
    func testBlockDeepLinkDefaultsToFalse() async {
        let defaults = makeIsolatedDefaults("inngage.tests.block.default")
        let session = InngageSession(defaults: defaults)
        let blocked = await session.blockDeepLink
        XCTAssertFalse(blocked)
    }

    /// `update(..., blockDeepLink: true)` persiste: nova instância sobre o mesmo
    /// `UserDefaults` relê `true` (cold start). Um `update` posterior com `false`
    /// reverte — a flag reflete sempre o último subscribe.
    func testBlockDeepLinkPersistsAndCanBeReverted() async {
        let defaults = makeIsolatedDefaults("inngage.tests.block.persist")
        let session = InngageSession(defaults: defaults)

        await session.update(appToken: "app", identifier: "u", registration: "fcm", blockDeepLink: true)
        let reloadedBlocked = await InngageSession(defaults: defaults).blockDeepLink
        XCTAssertTrue(reloadedBlocked)

        await session.update(appToken: "app", identifier: "u", registration: "fcm", blockDeepLink: false)
        let reloadedUnblocked = await InngageSession(defaults: defaults).blockDeepLink
        XCTAssertFalse(reloadedUnblocked)
    }

    // MARK: - NotificationLinkResolver

    /// Com a flag ligada, `deep` e `inapp` ⇒ `.blocked`: nenhum dos dois abre.
    func testLinkResolverBlocksDeepAndInAppWhenFlagIsSet() {
        let url = "https://example.com/promo"
        XCTAssertEqual(
            NotificationLinkResolver.resolve(type: "deep", urlString: url, blockDeepLink: true),
            .blocked
        )
        XCTAssertEqual(
            NotificationLinkResolver.resolve(type: "inapp", urlString: url, blockDeepLink: true),
            .blocked
        )
    }

    /// Flag desligada preserva o roteamento atual: `deep` ⇒ externo, `inapp` ⇒
    /// webview interna; tipo desconhecido, URL ausente ou vazia ⇒ `.none`.
    /// (Usa string vazia, e não "texto com espaços": desde o iOS 17 `URL(string:)`
    /// percent-encoda entradas antes inválidas, o que tornaria o teste frágil.)
    func testLinkResolverRoutesWhenNotBlocked() throws {
        let urlString = "https://example.com/promo"
        let url = try XCTUnwrap(URL(string: urlString))

        XCTAssertEqual(
            NotificationLinkResolver.resolve(type: "deep", urlString: urlString, blockDeepLink: false),
            .openExternal(url)
        )
        XCTAssertEqual(
            NotificationLinkResolver.resolve(type: "inapp", urlString: urlString, blockDeepLink: false),
            .openInApp(url)
        )
        XCTAssertEqual(
            NotificationLinkResolver.resolve(type: "unknown", urlString: urlString, blockDeepLink: false),
            .none
        )
        XCTAssertEqual(
            NotificationLinkResolver.resolve(type: "deep", urlString: nil, blockDeepLink: false),
            .none
        )
        XCTAssertEqual(
            NotificationLinkResolver.resolve(type: "deep", urlString: "", blockDeepLink: false),
            .none
        )
    }

    /// Item 10: encoding de custom values continua correto após extrair o DynamicKey.
    func testEventEncodesCustomValues() throws {
        let event = Event(
            app_token: "t", identifier: "u", registration: "r",
            event_name: "e", event_values: ["k": "v", "n": 3],
            conversion_event: false, conversion_value: 0, conversion_notid: ""
        )
        let data = try JSONEncoder().encode(event)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let values = json?["event_values"] as? [String: Any]
        XCTAssertEqual(values?["k"] as? String, "v")
        XCTAssertEqual(values?["n"] as? Int, 3)
    }
}
