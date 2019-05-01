//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MockAPICategoryPlugin: MessageReporter, APICategoryPlugin {
    var key: String {
        return "MockAPICategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset() {
        notify()
    }

    func prepareRequestBody(_ request: APIRequest) throws -> APIRequest {
        notify()
        return request
    }

    func authorizeRequest(_ request: APIRequest) throws -> APIRequest {
        notify()
        return request
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

class MockSecondAPICategoryPlugin: MockAPICategoryPlugin {
    override var key: String {
        return "MockSecondAPICategoryPlugin"
    }
}
