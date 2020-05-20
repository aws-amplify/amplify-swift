//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public struct AWSAuthConfirmSignInOptions {

    public let userAttributes: [AuthUserAttribute]?

    public let metadata: [String: String]?
}
