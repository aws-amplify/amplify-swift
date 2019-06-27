//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class AmplifyOperation<InProcessType, CompletedType, ErrorType: AmplifyError>: Operation,
    CategoryTypeable {
    public let id = UUID()

    public func listenToOperationEvents(
        filteringWith filter: @escaping HubFilter,
        onEvent: @escaping HubListener) -> UnsubscribeToken {
        let idFilteringWrapper: HubFilter = { payload in
            guard let payload.message?.
        }
        let token = Amplify.Hub.listen(to: nil,
                                       filteringWith: filter,
                                       onEvent: onEvent)
        return token
    }
}

extension AmplifyOperation: Cancellable { }

