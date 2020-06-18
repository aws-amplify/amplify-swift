//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Note that although this is public, it is intended for internal use and not consumed directly by host applications.
extension Model {
    public static var modelName: String {
        return String(describing: self)
    }

    public var modelName: String {
        return type(of: self).modelName
    }
}
