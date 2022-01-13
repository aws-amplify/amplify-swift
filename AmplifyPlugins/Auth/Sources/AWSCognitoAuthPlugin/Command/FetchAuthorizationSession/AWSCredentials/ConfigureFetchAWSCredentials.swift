//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation


struct ConfigureFetchAWSCredentials: Command {

    let identifier = "ConfigureFetchAWSCredentials"

    func execute(withDispatcher dispatcher: EventDispatcher,
                        environment: Environment)
    {
        let timer = LoggingTimer(identifier).start("### Starting execution")

        //TODO: Implementation


        // Refresh the session
        let fetchIdentity = FetchAWSCredentialEvent(eventType: .fetch)
        timer.stop("### sending \(fetchIdentity.type)")
        dispatcher.send(fetchIdentity)
    }
}

extension ConfigureFetchAWSCredentials: DefaultLogger { }

extension ConfigureFetchAWSCredentials: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier
        ]
    }
}

extension ConfigureFetchAWSCredentials: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
