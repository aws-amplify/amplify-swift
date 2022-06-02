//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum FetchAuthSessionState: State {

    case notStarted

    case fetchingIdentityID(LoginsMapProvider)

    case fetchingAWSCredentials(String, LoginsMapProvider)

    case waitingToStore(AmplifyCredentials)

    case fetched(AmplifyCredentials)
}

extension FetchAuthSessionState: Equatable {

    static func == (lhs: FetchAuthSessionState, rhs: FetchAuthSessionState) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted),
            (.fetchingIdentityID, .fetchingIdentityID),
            (.fetchingAWSCredentials, .fetchingAWSCredentials),
            (.waitingToStore, .waitingToStore),
            (.fetched, .fetched):
            return true

        default:
            return false
        }
    }

    var type: String {
        switch self {
        case .notStarted:
            return "FetchSessionState.notStarted"
        case .fetchingIdentityID:
            return "FetchSessionState.fetchingIdentityID"
        case .fetchingAWSCredentials:
            return "FetchSessionState.fetchingAWSCredentials"
        case .waitingToStore:
            return "FetchSessionState.waitingToStore"
        case .fetched:
            return "FetchSessionState.fetched"
        }
    }
}
