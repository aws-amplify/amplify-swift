//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

class MockAPICategoryPlugin: MessageReporter, APICategoryPlugin {
    var key: String {
        return "MockAPICategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func delete() {
        notify()
    }

    func get() {
        notify()
    }

    func head() {
        notify()
    }

    func options() {
        notify()
    }

    func patch() {
        notify()
    }

    func post() {
        notify()
    }

    func put() {
        notify()
    }

    func reset() {
        notify()
    }

    func prepareRequestBody(_ request: APIRequest) throws -> APIRequest {
        notify()
        return BasicAPIRequest(
            apiName: "test",
            resourcePath: "test",
            options: [:],
            method: HTTPMethod.get,
            rawRequest: nil
        )
    }

    func authorizeRequest(_ request: APIRequest) throws -> APIRequest {
        notify()
        return BasicAPIRequest(
            apiName: "test",
            resourcePath: "test",
            options: [:],
            method: HTTPMethod.get,
            rawRequest: nil
        )
    }

    func invoke(_ request: APIRequest) {
        notify()
    }

    func validateResponse(_ response: APIResponse) {
        notify()
    }

    func serializeResponse(_ response: APIResponse) {
        notify()
    }

}

class MockSecondAPICategoryPlugin: MockAPICategoryPlugin {
    override var key: String {
        return "MockSecondAPICategoryPlugin"
    }
}

final class MockAPICategoryPluginSelector: MessageReporter, APIPluginSelector {
    var selectedPluginKey: PluginKey? = "MockAPICategoryPlugin"

    func delete() {
        notify()
    }

    func get() {
        notify()
    }

    func head() {
        notify()
    }

    func options() {
        notify()
    }

    func patch() {
        notify()
    }

    func post() {
        notify()
    }

    func put() {
        notify()
    }

}

class MockAPIPluginSelectorFactory: MessageReporter, PluginSelectorFactory {
    var categoryType = CategoryType.api

    func makeSelector() -> PluginSelector {
        notify()
        return MockAPICategoryPluginSelector()
    }

    func add(plugin: Plugin) {
        notify()
    }

    func removePlugin(for key: PluginKey) {
        notify()
    }

}
