//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

extension AWSCredentials {

    func toAmplifyAWSCredentials() -> AuthAWSCognitoCredentials {
        // Credentials are fetched through Cognito Identity Pool and thus these are temporary credentials
        // so sessionKey and expiration date will not be nil.
        let credentials = AuthAWSCognitoCredentials(accessKey: accessKey,
                                                    secretKey: secretKey,
                                                    sessionKey: sessionKey!,
                                                    expiration: expiration!)
        return credentials
    }
}
