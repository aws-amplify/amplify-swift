//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

protocol MultiServiceBehavior: AnyObject {

    associatedtype ServiceResult

    /// Fetch the result from the offline service
    /// - Parameter callback: Result is send back to the caller
    func fetchOfflineResult() async throws -> ServiceResult

    /// Fetch the result from the online service
    /// - Parameter callback: Result is send back to the caller
    func fetchOnlineResult() async throws -> ServiceResult

    /// Fetch the result with multi service.
    /// - Parameter callback: Result is send back to the caller
    func fetchMultiServiceResult() async throws -> ServiceResult

    /// Merge the offline and online result to return a single result.
    /// - Parameter offlineResult:Offline result
    /// - Parameter onlineResult: Online result
    /// - Parameter callback: Callback invoked after successful merge
    func mergeResults(
        offlineResult: ServiceResult?,
        onlineResult: ServiceResult?
    ) async throws -> ServiceResult
}

extension MultiServiceBehavior {

    func fetchMultiServiceResult() async throws -> ServiceResult {
        let multi = try await invokeMultiServiceCalls()
        return try await mergeResults(
            offlineResult: multi.offlineResult,
            onlineResult: multi.onlineResult
        )
    }

    /// Method that fetch result from offline and online service
    func invokeMultiServiceCalls() async throws -> MultiServiceResponse<ServiceResult> {
//        async let onlineTask = try fetchOnlineResult()
//        async let offlineTask = try fetchOfflineResult()
//
//        let (online, offline) = try await (onlineTask, offlineTask)
        let online = try await fetchOnlineResult()
        let offline = try await fetchOfflineResult()

        return MultiServiceResponse(onlineResult: online, offlineResult: offline)
    }

//        let dispatchGroup = DispatchGroup()
//
//        var offlineResult: ServiceResult?
//        var offlineError: PredictionsError?
//        var onlineResult: ServiceResult?
//        var onlineError: PredictionsError?

//        dispatchGroup.enter()
//        fetchOfflineResult { event in
//            switch event {
//            case .completed(let result):
//                offlineResult = result
//            case .failed(let error):
//                offlineError = error
//            }
//            dispatchGroup.leave()
//        }
//
//        dispatchGroup.enter()
//        fetchOnlineResult { event in
//            switch event {
//            case .completed(let result):
//                onlineResult = result
//            case .failed(let error):
//                onlineError = error
//            }
//            dispatchGroup.leave()
//        }
//        dispatchGroup.wait()
//
//        if offlineError != nil && onlineError != nil {
//            callback(.failure(onlineError!))
//        }
//        let multiResponse = MultiServiceResponse(onlineResult: onlineResult, offlineResult: offlineResult)
//        callback(.success(multiResponse))


}

struct MultiServiceResponse<ServiceResult> {
    let onlineResult: ServiceResult?
    let offlineResult: ServiceResult?
}
