//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

open class AmplifyOperation<InProcessType, CompletedType, ErrorType: AmplifyError>: AsynchronousOperation,
CategoryTypeable, EventPublishable {
    public init(categoryType: CategoryType) {
        self.categoryType = categoryType
    }

    public var categoryType: CategoryType

    public let id = UUID()

    public func subscribe(
        filteringWith filter: @escaping HubFilter,
        onEvent: @escaping HubListener) -> UnsubscribeToken {
//        let idFilteringWrapper: HubFilter = { payload in
//            guard let payload.message?.
//        }
        let token = Amplify.Hub.listen(to: nil,
                                       filteringWith: filter,
                                       onEvent: onEvent)
        return token
    }

    public func dispatch(event: AsyncEvent<InProcessType, CompletedType, ErrorType>) {

        let payload = HubPayload(event: "event")
        Amplify.Hub.dispatch(to: .storage, payload: payload)
    }
}

extension AmplifyOperation: Cancellable { }
