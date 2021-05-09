//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// <#Description#>
public struct IdentifyCelebritiesResult: IdentifyResult {

    /// <#Description#>
    public let celebrities: [Celebrity]

    /// <#Description#>
    /// - Parameter celebrities: <#celebrities description#>
    public init(celebrities: [Celebrity]) {
        self.celebrities = celebrities
    }
}
