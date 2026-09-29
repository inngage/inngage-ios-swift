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
