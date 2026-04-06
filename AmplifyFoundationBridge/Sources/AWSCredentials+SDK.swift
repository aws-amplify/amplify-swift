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

public extension AWSCredentials {

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

public extension AwsCommonRuntimeKit.Credentials {

    func toAWSCredentials() throws -> AWSCredentials {
        guard let accessKeyId = getAccessKey(), let secretAccessKey = getSecret() else {
            throw FoundationBridgeError.unknown("CRT Credentials do not contain accessKeyId or secretAccessKey.")
        }

        guard let sessionToken = getSessionToken(), let expiration = getExpiration() else {
            return FoundationBridgeStaticCredentials(
                accessKeyId: accessKeyId,
                secretAccessKey: secretAccessKey
            )
        }

        return FoundationBridgeTemporaryCredentials(
            sessionToken: sessionToken,
            expiration: expiration,
            accessKeyId: accessKeyId,
            secretAccessKey: secretAccessKey
        )
    }
}

public extension SmithyIdentity.AWSCredentialIdentity {
    func toAWSCredentials() throws -> AWSCredentials {

        guard let sessionToken,
              let expiration  else {
            return FoundationBridgeStaticCredentials(
                accessKeyId: accessKey,
                secretAccessKey: secret
            )
        }

        return FoundationBridgeTemporaryCredentials(
            sessionToken: sessionToken,
            expiration: expiration,
            accessKeyId: accessKey,
            secretAccessKey: secret)
    }
}

struct FoundationBridgeStaticCredentials: AWSCredentials {
    var accessKeyId: String
    var secretAccessKey: String
}

struct FoundationBridgeTemporaryCredentials: AWSTemporaryCredentials {
    var sessionToken: String
    var expiration: Date
    var accessKeyId: String
    var secretAccessKey: String
}
