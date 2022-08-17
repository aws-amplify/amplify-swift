//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

#if swift(<5.6)
extension AsyncStream: @unchecked Sendable where Element: Sendable { }
extension AsyncThrowingStream: @unchecked Sendable where Element: Sendable { }
extension Progress: @unchecked Sendable {}
#endif
