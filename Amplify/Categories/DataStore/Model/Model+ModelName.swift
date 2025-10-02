//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension Model {

    static var modelName: String {
        return String(describing: self)
    }

    var modelName: String {
        return type(of: self).modelName
    }
}
