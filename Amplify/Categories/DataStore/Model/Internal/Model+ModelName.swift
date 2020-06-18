//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension Model {

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public static var modelName: String {
        return String(describing: self)
    }

    /// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
    ///   by host applications. The behavior of this may change without warning.
    public var modelName: String {
        return type(of: self).modelName
    }
}
