//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Amplify

public struct AWSAuthUser: AuthUser {

    /// The username for the logged in user
    ///
    /// Value maps to the username of a user in AWS Cognito User Pool. This value is set by AWS Cognito and not by the
    /// user and does not always map with the username used to signIn.
    public var username: String

    /// User Id for the logged in user
    ///
    /// UserId value maps to the sub value of a user in AWS Cognito User Pool. This value will be unique for a user.
    public var userId: String

}
