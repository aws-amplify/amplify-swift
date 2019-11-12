//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public enum AuthProvider {
    case apiKey(APIKeyProvider)
    case tokenProvider(AuthTokenProvider)
    case iamCredentialsProvider(IAMCredentialsProvider)
}
