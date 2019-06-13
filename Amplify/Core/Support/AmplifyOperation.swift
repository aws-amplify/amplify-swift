//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class AmplifyOperation<InProcessType, CompletedType, ErrorType: AmplifyError>: Operation {
    private var eventPublisher = BasicEventPublisher<InProcessType, CompletedType, ErrorType>()
}

extension AmplifyOperation: Cancellable { }

extension AmplifyOperation: EventPublishable {
    public func subscribe(
        _ onEvent: @escaping (AsyncEvent<InProcessType, CompletedType, ErrorType>) -> Void) -> Unsubscribe {
        return eventPublisher.subscribe(onEvent)
    }
}
