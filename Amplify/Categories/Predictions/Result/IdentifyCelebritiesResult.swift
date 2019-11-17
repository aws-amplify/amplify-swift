//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct IdentifyCelebritiesResult: IdentifyResult {
    public let celebrities: [Celebrity]

    public init(celebrities: [Celebrity]) {
        self.celebrities = celebrities
    }
}


