//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol APICategoryPlugin: Plugin, APICategoryPluginBehavior, APICategoryClientBehavior { }

public protocol APICategoryPluginBehavior {
    func prepareRequestBody(_ request: APIRequest) throws -> APIRequest
    func authorizeRequest(_ request: APIRequest) throws -> APIRequest
    func invoke(_ request: APIRequest)
    func validateResponse(_ response: APIResponse)
    func serializeResponse(_ response: APIResponse)
}

public struct AnyAPICategoryPlugin: APICategoryPlugin, PluginInitializable {
    public typealias PluginInitializableMarker = CategoryMarker.API

    // Generic plugin behaviors
    public let key: PluginKey
    private let _configure: (Any) throws -> Void
    private let _reset: () -> Void

    // Holder for client-specific behaviors
    private let clientBehavior: APICategoryClientBehavior
    private let pluginBehavior: APICategoryPluginBehavior

    public init<P: Plugin>(instance: P) {
        guard let clientBehavior = instance as? APICategoryClientBehavior else {
            preconditionFailure("Plugin does not conform to APICategoryClientBehavior")
        }
        self.clientBehavior = clientBehavior

        guard let pluginBehavior = instance as? APICategoryPluginBehavior else {
            preconditionFailure("Plugin does not conform to APICategoryPluginBehavior")
        }
        self.pluginBehavior = pluginBehavior

        key = instance.key
        _configure = instance.configure
        _reset = instance.reset
    }

    public func configure(using configuration: Any) throws {
        try _configure(configuration)
    }

    public func reset() {
        _reset()
    }

    // MARK: - Plugin behavior

    public func prepareRequestBody(_ request: APIRequest) throws -> APIRequest {
        return try pluginBehavior.prepareRequestBody(request)
    }

    public func authorizeRequest(_ request: APIRequest) throws -> APIRequest {
        return try pluginBehavior.authorizeRequest(request)
    }

    public func invoke(_ request: APIRequest) {
        pluginBehavior.invoke(request)
    }

    public func validateResponse(_ response: APIResponse) {
        pluginBehavior.validateResponse(response)
    }

    public func serializeResponse(_ response: APIResponse) {
        pluginBehavior.serializeResponse(response)
    }

    // MARK: - Client behavior

    public func delete() {
        clientBehavior.delete()
    }

    public func get() {
        clientBehavior.get()
    }

    public func head() {
        clientBehavior.head()
    }

    public func options() {
        clientBehavior.options()
    }

    public func patch() {
        clientBehavior.patch()
    }

    public func post() {
        clientBehavior.post()
    }

    public func put() {
        clientBehavior.put()
    }

}

public enum HTTPMethod: String {
    case delete = "DELETE"
    case get = "GET"
    case head = "HEAD"
    case options = "OPTIONS"
    case patch = "PATCH"
    case post = "POST"
    case put = "PUT"
}
