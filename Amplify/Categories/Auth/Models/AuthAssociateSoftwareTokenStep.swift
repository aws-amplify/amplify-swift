//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias SecretCode = String
public typealias Session = String

public enum AuthAssociateSoftwareTokenStep {

    case verifySoftwareToken(SecretCode, Session?)

    case done
}
