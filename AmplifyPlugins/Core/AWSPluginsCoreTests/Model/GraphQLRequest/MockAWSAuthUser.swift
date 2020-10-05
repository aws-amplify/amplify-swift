//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
public struct MockAWSAuthUser: AuthUser {

    /// The username for the logged in user
    public var username: String

    /// User Id for the logged in user
    public var userId: String

}
