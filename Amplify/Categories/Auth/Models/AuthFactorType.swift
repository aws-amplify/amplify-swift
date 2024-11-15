//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum AuthFactorType: String {

    /// An auth factor that uses password
    case password

    /// An auth factor that uses SRP protocol
    case passwordSRP

    /// An auth factor that uses SMS OTP
    case smsOTP

    /// An auth factor that uses Email OTP
    case emailOTP

#if os(iOS) || os(macOS) || os(visionOS)
    /// An auth factor that uses WebAuthn
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    case webAuthn
#endif
}
