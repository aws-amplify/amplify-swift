////
//// Copyright 2018-2019 Amazon.com,
//// Inc. or its affiliates. All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import Foundation
//
//class HubDispatchDestination {
//    let filter: HubFilter?
//    let queue: DispatchQueue
//    let listener: HubListener
//
//    init(listener: @escaping HubListener, queue: DispatchQueue, filter: HubFilter?) {
//        self.listener = listener
//        self.queue = queue
//        self.filter = filter
//    }
//
//    func receive(_ payload: HubPayload) {
//        if let filter = filter {
//            guard filter(payload) else {
//                return
//            }
//        }
//
//        queue.async {
//            // Do something
//        }
//    }
//}
