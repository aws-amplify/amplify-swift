//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias Unsubscribe = () -> Void

public protocol EventPublishable {
    associatedtype InProcessType
    associatedtype CompletedType
    associatedtype ErrorType: AmplifyError
    func subscribe(filteringWith filter: @escaping HubFilter, onEvent: @escaping HubListener) -> UnsubscribeToken
    func dispatch(event: AsyncEvent<InProcessType, CompletedType, ErrorType>)
}
