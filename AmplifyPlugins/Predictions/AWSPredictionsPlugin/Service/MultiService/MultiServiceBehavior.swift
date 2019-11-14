//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

protocol MultiServiceBehavior: class {

    associatedtype ServiceResult

    /// Fetch the result from the offline service
    /// - Parameter callback: Result is send back to the caller
    func fetchOfflineResult(callback: @escaping (PredictionsEvent<ServiceResult, PredictionsError>) -> Void)

    /// Fetch the result from the online service
    /// - Parameter callback: Result is send back to the caller
    func fetchOnlineResult(callback: @escaping (PredictionsEvent<ServiceResult, PredictionsError>) -> Void)

    /// Fetch the result with multi service.
    /// - Parameter callback: Result is send back to the caller
    func fetchMultiServiceResult(callback: @escaping (PredictionsEvent<ServiceResult, PredictionsError>) -> Void)

}

extension MultiServiceBehavior {

    /// Method that fetch result from offline and online service
    func invokeMultiInterpretText(callback: (MultiServiceEvent<ServiceResult>) -> Void) {

        // Use dispatch group to synchronize two parallel calls for offline and online service
        let dispatchGroup = DispatchGroup()

        var offlineResult: ServiceResult?
        var offlineError: PredictionsError?
        var onlineResult: ServiceResult?
        var onlineError: PredictionsError?

        dispatchGroup.enter()
        fetchOfflineResult { event in
            switch event {
            case .completed(let result):
                offlineResult = result
            case .failed(let error):
                offlineError = error
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        fetchOnlineResult { event in
            switch event {
            case .completed(let result):
                onlineResult = result
            case .failed(let error):
                onlineError = error
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()

        //TODO: Define what error to send back if both service returned an error
        if offlineError != nil && onlineError != nil {
            callback(.failed(onlineError!))
        }
        callback(.completed(offlineResult, onlineResult))
    }

}
