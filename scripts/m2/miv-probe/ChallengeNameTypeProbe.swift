//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// A G1(c) client-compile probe for the one retroactive conformance the plugin's clients get from the
// engine: `CognitoIdentityProviderClientTypes.ChallengeNameType: Codable`, declared in
// InternalAWSCognitoAuth's Models/AuthChallengeType.swift. A client
// sees it only because AWSCognitoAuthPlugin imports the engine with a plain (public) import; an
// `internal import` or `@_implementationOnly import` of InternalAWSCognitoAuth in the plugin makes this
// file stop type-checking. Without `import AWSCognitoAuthPlugin` it fails with three "requires that
// 'ChallengeNameType' conform to" errors, so the probe is not vacuous.
// Run it with `scripts/m2/run_miv_probe.sh scripts/m2/miv-probe/ChallengeNameTypeProbe.swift`. Never linked.

import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider
import Foundation

func probeChallengeNameTypeCodable(
    _ challenge: CognitoIdentityProviderClientTypes.ChallengeNameType
) throws -> CognitoIdentityProviderClientTypes.ChallengeNameType {
    try JSONDecoder().decode(
        CognitoIdentityProviderClientTypes.ChallengeNameType.self,
        from: JSONEncoder().encode(challenge)
    )
}

func probeChallengeNameTypeArray(_ challenges: [CognitoIdentityProviderClientTypes.ChallengeNameType]) throws -> Data {
    try JSONEncoder().encode(challenges)
}
