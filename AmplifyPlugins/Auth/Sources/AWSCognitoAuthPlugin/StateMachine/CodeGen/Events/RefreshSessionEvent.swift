//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct RefreshSessionEvent: StateMachineEvent {
    enum EventType {

        case refreshUnAuthAWSCredentials(IdentityID)

        case refreshAWSCredentialsWithUserPool(IdentityID, SignedInData, LoginsMapProvider)

        case refreshCognitoUserPool(SignedInData)

        case refreshCognitoUserPoolWithIdentityId(SignedInData, IdentityID)

        case refreshedCognitoUserPool(SignedInData)

        case refreshIdentityInfo(SignedInData, LoginsMapProvider)

        case refreshed(AmplifyCredentials)

        case throwError(FetchSessionError)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {

        case .refreshUnAuthAWSCredentials:
            return "RefreshSessionEvent.refreshUnAuthAWSCredentials"
        case .refreshAWSCredentialsWithUserPool:
            return "RefreshSessionEvent.refreshAWSCredentialsWithUserPool"
        case .refreshCognitoUserPool:
            return "RefreshSessionEvent.refreshCognitoUserPool"
        case .refreshCognitoUserPoolWithIdentityId:
            return "RefreshSessionEvent.refreshCognitoUserPoolWithIdentityId"
        case .refreshedCognitoUserPool:
            return "RefreshSessionEvent.refreshedCognitoUserPool"
        case .refreshIdentityInfo:
            return "RefreshSessionEvent.refreshIdentityInfo"
        case .refreshed:
            return "RefreshSessionEvent.refreshed"
        case .throwError:
            return "RefreshSessionEvent.throwError"
        }
    }

    init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

extension RefreshSessionEvent.EventType: Equatable {
    static func == (lhs: RefreshSessionEvent.EventType, rhs: RefreshSessionEvent.EventType) -> Bool {
        switch (lhs, rhs) {
        case (.refreshUnAuthAWSCredentials, .refreshUnAuthAWSCredentials),
            (.refreshAWSCredentialsWithUserPool, .refreshAWSCredentialsWithUserPool),
            (.refreshCognitoUserPool, .refreshCognitoUserPool),
            (.refreshCognitoUserPoolWithIdentityId, .refreshCognitoUserPoolWithIdentityId),
            (.refreshedCognitoUserPool, .refreshedCognitoUserPool),
            (.refreshIdentityInfo, .refreshIdentityInfo),
            (.refreshed, .refreshed):
            return true
        case (.throwError(let lhserror), .throwError(let rhsError)):
            return lhserror == rhsError
        default: return false
        }
    }
}
