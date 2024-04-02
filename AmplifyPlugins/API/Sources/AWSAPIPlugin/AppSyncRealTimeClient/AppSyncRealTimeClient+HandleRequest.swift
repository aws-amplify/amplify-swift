//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Combine
import Amplify

extension AppSyncRealTimeClient {
    /**
     Submit an AppSync request to real-time server.
     - Returns:
        Void indicates request is finished successfully
     - Throws:
        Error is throwed when request is failed
     */
    func sendRequest(
        _ request: AppSyncRealTimeRequest,
        timeout: TimeInterval = 5
    ) async throws {
        var responseSubscriptions = Set<AnyCancellable>()
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Swift.Error>) in
            guard let self else {
                Self.log.debug("[AppSyncRealTimeClient] client has already been disposed")
                continuation.resume(returning: ())
                return
            }

            // listen to response
            self.subject
                .setFailureType(to: AppSyncRealTimeRequest.Error.self)
                .flatMap { Self.filterResponse(request: request, response: $0) }
                .timeout(.seconds(timeout), scheduler: DispatchQueue.global(qos: .userInitiated), customError: { .timeout })
                .first()
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: ())
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { _ in })
                .store(in: &responseSubscriptions)

            // sending request; error is discarded and will be classified as timeout
            Task {
                do {
                    let decoratedRequest = await self.requestInterceptor.interceptRequest(
                        event: request,
                        url: self.endpoint
                    )
                    let requestJSON = String(data: try Self.jsonEncoder.encode(decoratedRequest), encoding: .utf8)

                    try await self.webSocketClient.write(message: requestJSON!)
                } catch {
                    Self.log.debug("[AppSyncRealTimeClient]Failed to send AppSync request \(request), error: \(error)")
                }
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
                && response.payload?.errors != nil:
            let errorsJson: JSONValue = (response.payload?.errors)!
            let errors = errorsJson.asArray ?? [errorsJson]
            let reqeustErrors = errors.compactMap(AppSyncRealTimeRequest.parseResponseError(error:))
            if reqeustErrors.isEmpty {
                return Empty(
                    outputType: AppSyncRealTimeResponse.self,
                    failureType: AppSyncRealTimeRequest.Error.self
                ).eraseToAnyPublisher()
            } else {
                return Fail(
                    outputType: AppSyncRealTimeResponse.self,
                    failure: reqeustErrors.first!
                ).eraseToAnyPublisher()
            }

        default:
            return Empty(
                outputType: AppSyncRealTimeResponse.self,
                failureType: AppSyncRealTimeRequest.Error.self
            ).eraseToAnyPublisher()

        }
    }
}
