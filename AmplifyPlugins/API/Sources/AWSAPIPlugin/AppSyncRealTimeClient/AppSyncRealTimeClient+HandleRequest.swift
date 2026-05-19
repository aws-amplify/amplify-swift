//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Amplify
import Combine
@preconcurrency import Combine
import Foundation

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
        // Perform auth token decoration before starting the response timeout.
        // Auth token retrieval can take a variable amount of time, especially
        // under contention with multiple concurrent subscriptions. The timeout
        // should only measure the server round-trip after the write, not local
        // preparation work.
        let decoratedRequest = await self.requestInterceptor.interceptRequest(
            event: request,
            url: self.endpoint
        )

        var responseSubscriptions = Set<AnyCancellable>()
        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<Void, Swift.Error>) in
            guard let self else {
                Self.log.debug("[AppSyncRealTimeClient] client has already been disposed")
                continuation.resume(returning: ())
                return
            }

            // listen to response — timeout starts now, after auth decoration
            subject
                .setFailureType(to: AppSyncRealTimeRequest.Error.self)
                .flatMap { Self.filterResponse(request: request, result: $0) }
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

            // send the already-decorated request
            Task {
                do {
                    let requestJSON = try String(data: Self.jsonEncoder.encode(decoratedRequest), encoding: .utf8)
                    try await self.webSocketClient.write(message: requestJSON!)
                } catch {
                    Self.log.debug("[AppSyncRealTimeClient] Failed to send AppSync request \(request), error: \(error)")
                    subject.send(.failure(error))
                }
            }
        }
    }

    private static func filterResponse(
        request: AppSyncRealTimeRequest,
        result: Result<AppSyncRealTimeResponse, Error>
    ) -> AnyPublisher<AppSyncRealTimeResponse, AppSyncRealTimeRequest.Error> {

        switch result {
        case .success(let response):
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

        case .failure:
            return Fail(
                outputType: AppSyncRealTimeResponse.self,
                failure: .timeout
            ).eraseToAnyPublisher()
        }


    }
}
