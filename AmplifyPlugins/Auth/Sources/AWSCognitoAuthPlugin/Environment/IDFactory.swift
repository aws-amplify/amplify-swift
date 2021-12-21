//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias EventIDFactory = () -> String

public enum UUIDFactory {
    public static let factory: EventIDFactory = { UUID().uuidString }
}
