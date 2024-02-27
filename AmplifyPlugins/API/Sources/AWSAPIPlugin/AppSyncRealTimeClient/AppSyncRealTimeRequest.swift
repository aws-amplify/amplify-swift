//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Combine
import Amplify

public enum AppSyncRealTimeRequest {
    case connectionInit
    case start(StartRequest)
    case stop(String)

    public struct StartRequest {
        let id: String
        let data: String
        let auth: AppSyncRealTimeRequestAuth?
    }

    var id: String? {
        switch self {
        case let .start(request): return request.id
        case let .stop(id): return id
        default: return nil
        }
    }
}

extension AppSyncRealTimeRequest: Encodable {
    enum CodingKeys: CodingKey {
        case type
        case payload
        case id
    }

    enum PayloadCodingKeys: CodingKey {
        case data
        case extensions
    }

    enum ExtensionsCodingKeys: CodingKey {
        case authorization
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .connectionInit:
            try container.encode("connection_init", forKey: .type)
        case .start(let startRequest):
            try container.encode("start", forKey: .type)
            try container.encode(startRequest.id, forKey: .id)

            let payloadEncoder = container.superEncoder(forKey: .payload)
            var payloadContainer = payloadEncoder.container(keyedBy: PayloadCodingKeys.self)
            try payloadContainer.encode(startRequest.data, forKey: .data)

            let extensionEncoder = payloadContainer.superEncoder(forKey: .extensions)
            var extensionContainer = extensionEncoder.container(keyedBy: ExtensionsCodingKeys.self)
            try extensionContainer.encodeIfPresent(startRequest.auth, forKey: .authorization)
        case .stop(let id):
            try container.encode("stop", forKey: .type)
            try container.encode(id, forKey: .id)
        }
    }
}


extension AppSyncRealTimeRequest {
    enum Error: Swift.Error {
        case timeout
        case limitExceeded
        case maxSubscriptionsReached
        case abort
        case unknown
    }

    static func sendRequest(
        request: AppSyncRealTimeRequest,
        responseStream: AnyPublisher<AppSyncRealTimeResponse, Never>,
        timeout: TimeInterval = 5,
        fireRequest: @escaping (AppSyncRealTimeRequest) async throws -> Void
    ) async throws {
        var cancellables = Set<AnyCancellable>()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
            responseStream
                .setFailureType(to: AppSyncRealTimeRequest.Error.self)
                .flatMap { filterResponse(request: request, response: $0) }
                .timeout(.seconds(timeout), scheduler: DispatchQueue.global(qos: .userInitiated), customError: { .timeout })
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(throwing: Error.abort)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { _ in
                    continuation.resume(returning: ())
                })
                .store(in: &cancellables)

            Task {
                try await fireRequest(request)
            }
        }
    }

    private static func filterResponse(
        request: AppSyncRealTimeRequest,
        response: AppSyncRealTimeResponse
    ) -> AnyPublisher<AppSyncRealTimeResponse, AppSyncRealTimeRequest.Error> {
        let justTheResponse = Just(response)
            .setFailureType(to: AppSyncRealTimeRequest.Error.self)
            .eraseToAnyPublisher()

        switch (request, response.type) {
        case (.connectionInit, .connectionAck):
            return justTheResponse

        case (.start(let startRequest), .startAck) where startRequest.id == response.id:
            return justTheResponse

        case (.stop(let id), .stopAck) where id == response.id:
            return justTheResponse

        case (_, .error)
            where request.id != nil
                && request.id == response.id
                && response.payload?.errors?.asArray != nil:
            return parseResponseError(errors: (response.payload?.errors?.asArray)!)

        default:
            return Empty(
                outputType: AppSyncRealTimeResponse.self,
                failureType: AppSyncRealTimeRequest.Error.self
            ).eraseToAnyPublisher()

        }
    }

    private static func parseResponseError(
        errors: [JSONValue]
    ) -> AnyPublisher<AppSyncRealTimeResponse, AppSyncRealTimeRequest.Error> {
        let limitExceededErrorString = "LimitExceededError"
        let maxSubscriptionsReachedErrorString = "MaxSubscriptionsReachedError"

        let errorTypes = errors.map { $0.errorType?.stringValue }.compactMap { $0 }
        if errorTypes.contains(where: { $0.contains(limitExceededErrorString) }) {
            return Fail(
                outputType: AppSyncRealTimeResponse.self,
                failure: AppSyncRealTimeRequest.Error.limitExceeded
            ).eraseToAnyPublisher()
        } else if errorTypes.contains(where: { $0.contains(maxSubscriptionsReachedErrorString) }) {
            return Fail(
                outputType: AppSyncRealTimeResponse.self,
                failure: AppSyncRealTimeRequest.Error.maxSubscriptionsReached
            ).eraseToAnyPublisher()
        } else {
            return Fail(
                outputType: AppSyncRealTimeResponse.self,
                failure: AppSyncRealTimeRequest.Error.unknown
            ).eraseToAnyPublisher()
        }
    }
}
