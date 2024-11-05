//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct TestError: Error {
    let description: String

    init(_ description: String) { self.description = description }
}
