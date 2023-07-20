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
        async let onlineTask = try fetchOnlineResult()
    #if os(iOS) || os(macOS)
        async let offlineTask = try fetchOfflineResult()
    #else
        async let offlineTask: ServiceResult? = nil
    #endif
        let (online, offline) = try await (onlineTask, offlineTask)
        return MultiServiceResponse(onlineResult: online, offlineResult: offline)
    }
}

struct MultiServiceResponse<ServiceResult> {
    let onlineResult: ServiceResult?
    let offlineResult: ServiceResult?
}
