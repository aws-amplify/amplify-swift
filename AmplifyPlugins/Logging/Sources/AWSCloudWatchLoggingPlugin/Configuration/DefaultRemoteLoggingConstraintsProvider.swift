//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import InternalAmplifyCredentials
import AWSClientRuntime
import ClientRuntime

public class DefaultRemoteLoggingConstraintsProvider: RemoteLoggingConstraintsProvider {
    public let refreshIntervalInSeconds: Int
    private let endpoint: URL
    private let credentialProvider: CredentialsProviding?
    private let region: String
    private let loggingConstraintsLocalStore: LoggingConstraintsLocalStore = UserDefaults.standard

    private var loggingConstraint: LoggingConstraints? {
        return loggingConstraintsLocalStore.getLocalLoggingConstraints()
    }

    private var refreshTimer: DispatchSourceTimer? {
        willSet {
            refreshTimer?.cancel()
        }
    }

    public init(
         endpoint: URL,
         region: String,
         credentialProvider: CredentialsProviding? = nil,
         refreshIntervalInSeconds: Int = 1200
    ) {
        self.endpoint = endpoint
        if credentialProvider == nil {
            self.credentialProvider = AWSAuthService().getCredentialsProvider()
        } else {
            self.credentialProvider = credentialProvider
        }
        self.region = region
        self.refreshIntervalInSeconds = refreshIntervalInSeconds
        self.setupAutomaticRefreshInterval()
    }

    public func fetchLoggingConstraints() async throws -> LoggingConstraints {
        var url = URLRequest(url: endpoint)
        if let etag = loggingConstraintsLocalStore.getLocalLoggingConstraintsEtag() {
            url.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        let signedRequest = try await sigV4Sign(url, region: region)
        let (data, response) = try await URLSession.shared.data(for: signedRequest)
        if (response as? HTTPURLResponse)?.statusCode == 304, let cachedValue = self.loggingConstraint {
            return cachedValue
        }
        let loggingConstraint = try JSONDecoder().decode(LoggingConstraints.self, from: data)
        loggingConstraintsLocalStore.setLocalLoggingConstraints(loggingConstraints: loggingConstraint)

        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/If-None-Match
        // https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag
        // the response header should only use the ETag header field in accordance with Http protocol spec
        // but we need to also look at `If-None-Match` due to the initial/old lambda documentation recommending to
        // `If-None-Match` to return the ETag
        if let etag = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "ETag") {
            loggingConstraintsLocalStore.setLocalLoggingConstraintsEtag(etag: etag)
        } else if let etag = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "If-None-Match") {
            loggingConstraintsLocalStore.setLocalLoggingConstraintsEtag(etag: etag)
        }
        return loggingConstraint
    }

    func sigV4Sign(_ request: URLRequest, region: String) async throws -> URLRequest {
        var request = request
        guard let url = request.url else {
            throw APIError.unknown("Could not get url from mutable request", "")
        }
        guard let host = url.host else {
            throw APIError.unknown("Could not get host from mutable request", "")
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "host")

        let httpMethod = (request.httpMethod?.uppercased())
            .flatMap(HttpMethodType.init(rawValue:)) ?? .get

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .map { ClientRuntime.SDKURLQueryItem(name: $0.name, value: $0.value) } ?? []

        let requestBuilder = SdkHttpRequestBuilder()
            .withHost(host)
            .withPath(url.path)
            .withQueryItems(queryItems)
            .withMethod(httpMethod)
            .withPort(443)
            .withProtocol(.https)
            .withHeaders(.init(request.allHTTPHeaderFields ?? [:]))
            .withBody(.data(request.httpBody))

        guard let credentialProvider = self.credentialProvider else {
            return request
        }

        guard let urlRequest = try await AmplifyAWSSignatureV4Signer().sigV4SignedRequest(
            requestBuilder: requestBuilder,
            credentialsProvider: credentialProvider,
            signingName: "execute-api",
            signingRegion: region,
            date: Date()
        ) else {
            throw APIError.unknown("Unable to sign request", "")
        }

        for header in urlRequest.headers.headers {
            request.setValue(header.value.joined(separator: ","), forHTTPHeaderField: header.name)
        }

        return request
    }

    func refresh() {
        Task {
            do {
                _ = try await self.fetchLoggingConstraints()
            } catch {
                Amplify.Logging.warn("Error fetching remote logging constraints: \(error)")
            }
        }
    }

    func setupAutomaticRefreshInterval() {
        guard refreshIntervalInSeconds != .zero else {
            refreshTimer = nil
            return
        }

        refreshTimer = Self.createRepeatingTimer(
            timeInterval: TimeInterval(self.refreshIntervalInSeconds),
            eventHandler: { [weak self] in
                guard let self = self else { return }
                self.refresh()
        })
        refreshTimer?.resume()
    }

    static func createRepeatingTimer(timeInterval: TimeInterval,
                                     eventHandler: @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + timeInterval, repeating: timeInterval)
        timer.setEventHandler(handler: eventHandler)
        return timer
    }
}
