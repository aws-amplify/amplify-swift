//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// Conversions between the public `AuthFlowType` and the engine's `EngineAuthFlowType`.
// Case to case, never through `rawValue`: `.custom` and `.customWithSRP` share a raw value, and the
// bijection must keep them apart. The factor goes through `AuthFactorType+Engine.swift`.

extension EngineAuthFlowType {

    init(_ flow: AuthFlowType) {
        self = caseTable.engine(flow)
    }
}

extension AuthFlowType {

    init(_ flow: EngineAuthFlowType) {
        self = caseTable.public(flow)
    }
}

/// The case tables. `AuthFlowType.custom` is deprecated but still part of the bijection, so the tables
/// are declared deprecated, which keeps the references to it warning-free, and are reached through a
/// protocol, which keeps the two initializers above warning-free for their callers.
private var caseTable: any AuthFlowTypeCaseTable.Type { AuthFlowTypeBridge.self }

private protocol AuthFlowTypeCaseTable {
    static func engine(_ flow: AuthFlowType) -> EngineAuthFlowType
    static func `public`(_ flow: EngineAuthFlowType) -> AuthFlowType
}

private enum AuthFlowTypeBridge: AuthFlowTypeCaseTable {

    @available(*, deprecated, message: "Maps the deprecated AuthFlowType.custom, on purpose")
    static func engine(_ flow: AuthFlowType) -> EngineAuthFlowType {
        switch flow {
        case .userSRP: return .userSRP
        case .custom: return .custom
        case .customWithSRP: return .customWithSRP
        case .customWithoutSRP: return .customWithoutSRP
        case .userPassword: return .userPassword
        case .userAuth(let factor): return .userAuth(preferredFirstFactor: factor.map { EngineAuthFactorType($0) })
        }
    }

    @available(*, deprecated, message: "Maps to the deprecated AuthFlowType.custom, on purpose")
    static func `public`(_ flow: EngineAuthFlowType) -> AuthFlowType {
        switch flow {
        case .userSRP: return .userSRP
        case .custom: return .custom
        case .customWithSRP: return .customWithSRP
        case .customWithoutSRP: return .customWithoutSRP
        case .userPassword: return .userPassword
        case .userAuth(let factor): return .userAuth(preferredFirstFactor: factor.map { AuthFactorType($0) })
        }
    }
}
