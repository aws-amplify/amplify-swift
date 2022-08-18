//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AWSS3SigningOperation {
    case getObject
    case putObject
    case uploadPart(partNumber: Int, uploadId: String)
}
