//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public extension Result where Success == Void {
    static var successfulVoid: Result<Void, Failure> { .success(()) }
}
