//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AwsCommonRuntimeKit
import Foundation
import SmithyIdentity

extension AWSCredentials {

    func toAWSSDKCredentials() throws -> AwsCommonRuntimeKit.Credentials {
        if let tempCredentials = self as? AWSTemporaryCredentials {
            return try AwsCommonRuntimeKit.Credentials(
                accessKey: tempCredentials.accessKeyId,
                secret: tempCredentials.secretAccessKey,
                sessionToken: tempCredentials.sessionToken,
                expiration: tempCredentials.expiration
            )
        } else {
            return try AwsCommonRuntimeKit.Credentials(
                accessKey: accessKeyId,
                secret: secretAccessKey
            )
        }
    }

    func toAWSCredentialIdentity() throws -> SmithyIdentity.AWSCredentialIdentity {
        return SmithyIdentity.AWSCredentialIdentity(
            accessKey: accessKeyId,
            secret: secretAccessKey,
            expiration: (self as? AWSTemporaryCredentials)?.expiration,
            sessionToken: (self as? AWSTemporaryCredentials)?.sessionToken
        )
    }
}
