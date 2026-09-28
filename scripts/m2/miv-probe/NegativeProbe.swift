//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Self-test input for scripts/m2/run_miv_probe.sh: reads a member declared in AWSPluginsCore without
// importing it. It must type-check with MemberImportVisibility off and fail with it on, which proves the
// runner really enables the feature.

import AWSCognitoAuthPlugin

func negativeProbe(_ result: FederateToIdentityPoolResult) -> String {
    result.credentials.accessKeyId
}
