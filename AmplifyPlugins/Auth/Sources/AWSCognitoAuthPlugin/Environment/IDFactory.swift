//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

typealias EventIDFactory = () -> String

enum UUIDFactory {
    static let factory: EventIDFactory = { UUID().uuidString }
}
