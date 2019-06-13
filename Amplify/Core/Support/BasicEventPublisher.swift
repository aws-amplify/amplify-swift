//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

final class BasicEventPublisher<InProcessType, CompletedType, ErrorType: AmplifyError>: EventPublishable {
    private var eventSubscribers = [UUID: (AsyncEvent<InProcessType, CompletedType, ErrorType>) -> Void]()

    public func subscribe(
        _ onEvent: @escaping (AsyncEvent<InProcessType, CompletedType, ErrorType>) -> Void) -> Unsubscribe {
        let uuid = UUID()
        eventSubscribers[uuid] = onEvent
        let unsubscribe = { [weak self] in
            self?.eventSubscribers.removeValue(forKey: uuid)
            return
        }
        return unsubscribe
    }
}
