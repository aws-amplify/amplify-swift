//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A convenience typealias that disambiguates a method used to unsubscribe from an EventPublishable instance
public typealias Unsubscribe = () -> Void

/// The conforming type publishes AsyncEvents. Interested callers may `subscribe` to the event, and invoke the returned
/// method to unsubscribe from the event publisher when they are no longer interested in receiving status updates
public protocol EventPublishable {
    associatedtype InProcessType
    associatedtype CompletedType
    associatedtype ErrorType: AmplifyError
    func subscribe(_ onEvent: @escaping (AsyncEvent<InProcessType, CompletedType, ErrorType>) -> Void) -> Unsubscribe
}
