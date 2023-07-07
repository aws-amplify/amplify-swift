//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

struct InformUserDeletedAndSignedOut: Action {

    let identifier = "InformUserDeletedAndSignedOut"

    let result: Result<SignedOutData, AuthError>

    func execute(withDispatcher dispatcher: EventDispatcher, environment: Environment) async {

        logVerbose("\(#fileID) Starting execution", environment: environment)

        let event: DeleteUserEvent
        switch result {
        case .success(let signedOutData):
            event = DeleteUserEvent(eventType: .userSignedOutAndDeleted(signedOutData))
        case .failure(let error):
            event = DeleteUserEvent(eventType: .throwError(error))
        }

        logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
        await dispatcher.send(event)
    }
}

extension InformUserDeletedAndSignedOut: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName)
    }
    
    public var log: Logger {
        Self.log
    }
}

extension InformUserDeletedAndSignedOut: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension InformUserDeletedAndSignedOut: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
