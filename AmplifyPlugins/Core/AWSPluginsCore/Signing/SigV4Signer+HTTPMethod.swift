//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct HTTPMethod {
    public let verb: String

    public init(verb: String) {
        self.verb = verb
    }

    public static let get = Self(verb: "GET")
    public static let post = Self(verb: "POST")
    public static let put = Self(verb: "PUT")
    public static let delete = Self(verb: "DELETE")
    public static let head = Self(verb: "HEAD")
}
