//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

open class AmplifyOperation<InProcessType, CompletedType, ErrorType: AmplifyError>: Operation,
CategoryTypeable, EventPublishable {
    public init(categoryType: CategoryType) {
        self.categoryType = categoryType
    }
    
    public var categoryType: CategoryType
    
    public let id = UUID()

    public func listenToOperationEvents(
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
    
    open func subscribe(_ onEvent: @escaping (AsyncEvent<InProcessType, CompletedType, ErrorType>) -> Void) -> Unsubscribe {
        return { () -> Void in return }
    }
}

extension AmplifyOperation: Cancellable { }

