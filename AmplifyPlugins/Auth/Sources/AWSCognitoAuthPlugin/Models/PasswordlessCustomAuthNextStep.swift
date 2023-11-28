//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum PasswordlessCustomAuthNextStep: String {

    case provideAuthParameters = "PROVIDE_AUTH_PARAMETERS"

    case provideChallengeResponse = "PROVIDE_CHALLENGE_RESPONSE"
}
