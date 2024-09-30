//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct InternalMetadata {

    public init() {}
 }

extension InternalMetadata: CustomStringConvertible {

    var description: String {
        return "md/internal"
    }
}
