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

    // swiftlint:disable identifier_name
    /// The unique ID of the operation. In categories where operations are persisted for future processing, this id can
    /// be used to identify previously-scheduled work for progress tracking or other functions.
    public let id = UUID()
    // swiftlint:enable identifier_name

    public func subscribe(
        filteringWith filter: @escaping HubFilter,
        onEvent: @escaping HubListener) -> UnsubscribeToken {
//        let idFilteringWrapper: HubFilter = { payload in
//            guard let payload.message?.
//        }
//TODO: Derive channel from category type
let token = Amplify.Hub.listen(to: HubChannel.storage,
                                       filteringWith: filter,
                                       onEvent: onEvent)
        return token
    }

    public func dispatch(event: AsyncEvent<InProcessType, CompletedType, ErrorType>) {

        let payload = HubPayload(event: "event")
        //Amplify.Hub.dispatch(to: .storage, payload: payload)
    }
}

extension AmplifyOperation: Cancellable { }
