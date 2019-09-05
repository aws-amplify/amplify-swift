//
//  EventPublishable.swift
//  S3TransferUtilitySampleSwift
//
//  Created by Law, Michael on 8/13/19.
//  Copyright © 2019 Amazon. All rights reserved.
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
