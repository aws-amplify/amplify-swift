//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Foundation

@_spi(InternalAWSPinpoint)
public class AWSPinpointFactory {
    private struct PinpointContextKey: Hashable {
        let appId: String
        let region: String
    }
    
    private static var instances: AtomicDictionary<PinpointContextKey, PinpointContext> = [:]
    
    private init() {}
    
    static var credentialsProvider = AWSAuthService().getCredentialsProvider()

    static var provisioningProfileReader: ProvisioningProfileReader = .default
    
    public static func sharedPinpoint(appId: String,
                                      region: String) throws -> AWSPinpointBehavior {
        let key = PinpointContextKey(appId: appId, region: region)
        if let existingContext = instances[key] {
            return existingContext
        }

        var isDebug: Bool
        /// Check for the APS Environment entitlement in a provisioning profile first
        if let apsEnvironment = provisioningProfileReader.profile()?.apsEnvironment {
            isDebug = apsEnvironment == .development
        } else {
        /// Fallback to the DEBUG flag
        #if DEBUG
            isDebug = true
        #else
            isDebug = false
        #endif
        }
        let configuration = PinpointContextConfiguration(
            appId: appId,
            region: region,
            credentialsProvider: credentialsProvider,
            isDebug: isDebug
        )
        
        let pinpointContext = try PinpointContext(with: configuration)
        instances[key] = pinpointContext
        return pinpointContext
    }
}

