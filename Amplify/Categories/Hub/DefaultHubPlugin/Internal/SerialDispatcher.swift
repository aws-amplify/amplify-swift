//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A Dispatcher that processes the list of listeners serially, although the work fo filter and actually invoke the
/// listener is on a background queue
struct SerialDispatcher: Dispatcher {
    let channel: HubChannel
    let payload: HubPayload

    var isCancelled: Bool

    init(channel: HubChannel, payload: HubPayload) {
        self.channel = channel
        self.payload = payload
        self.isCancelled = false
    }

    func dispatch(to listeners: [FilteredListener]) {
        for listener in listeners {
            guard !isCancelled else {
                return
            }

            guard channel == listener.channel else {
                continue
            }

            DispatchQueue.global().async {
                guard !self.isCancelled else {
                    return
                }

                if let filter = listener.filter {
                    guard filter(self.payload) else {
                        return
                    }
                }

                listener.onEvent(self.payload)
            }
        }
    }
}
