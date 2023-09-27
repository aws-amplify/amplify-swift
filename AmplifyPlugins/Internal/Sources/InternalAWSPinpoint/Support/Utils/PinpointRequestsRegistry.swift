//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPinpoint
import ClientRuntime

@globalActor actor PinpointRequestsRegistry {
    static let shared = PinpointRequestsRegistry()
    private var pendingRequests: [API: Set<AWSPinpointSource>] = [:]

    private init() {}

    func registerSource(_ source: AWSPinpointSource, for api: API) {
        pendingRequests[api, default: []].insert(source)
    }

    nonisolated func setCustomHttpEngine(on configuration: PinpointClient.PinpointClientConfiguration) {
        let oldHttpClientEngine = configuration.httpClientEngine
        configuration.httpClientEngine = CustomPinpointHttpClientEngine(
            httpClientEngine: oldHttpClientEngine
        )
    }

    fileprivate func sources(for api: API) -> Set<AWSPinpointSource> {
        return pendingRequests[api, default: []]
    }

    fileprivate func unregisterSources(for api: API) {
        pendingRequests[api] = nil
    }

    enum API: String {
        case recordEvent = "events"
        case updateEndpoint = "endpoints"

        init?(from url: URL) {
            for path in url.pathComponents {
                guard let api = API(rawValue: path) else { continue }
                self = api
                return
            }

            return nil
        }
    }
}

private struct CustomPinpointHttpClientEngine: HttpClientEngine {
    private let userAgentHeader = "User-Agent"
    private let httpClientEngine: HttpClientEngine

    init(httpClientEngine: HttpClientEngine) {
        self.httpClientEngine = httpClientEngine
    }

    func execute(request: ClientRuntime.SdkHttpRequest) async throws -> ClientRuntime.HttpResponse {
        guard let url = request.endpoint.url,
              let pinpointApi = PinpointRequestsRegistry.API(from: url),
              let userAgentSuffix = await userAgent(for: pinpointApi) else {
            return try await httpClientEngine.execute(request: request)
        }

        let currentUserAgent = request.headers.value(for: userAgentHeader) ?? ""
        request.withHeader(name: userAgentHeader, value: "\(currentUserAgent)\(userAgentSuffix)")

        await PinpointRequestsRegistry.shared.unregisterSources(for: pinpointApi)
        return try await httpClientEngine.execute(request: request)
    }

    private func userAgent(for api: PinpointRequestsRegistry.API) async -> String? {
        let sources = await PinpointRequestsRegistry.shared.sources(for: api)
        if sources.isEmpty {
            return nil
        }

        var userAgent = ""
        for source in sources {
            userAgent.append(" ft/\(source.rawValue)")
        }
        return userAgent
    }
}
