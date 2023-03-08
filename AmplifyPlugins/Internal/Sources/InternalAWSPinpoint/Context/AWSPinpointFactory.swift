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
    
    public static func sharedPinpoint(appId: String,
                                      region: String) throws -> AWSPinpointBehavior {
        let key = PinpointContextKey(appId: appId, region: region)
        if let existingContext = instances[key] {
            return existingContext
        }

        var isDebug = false
        #if DEBUG
            isDebug = true
        #endif
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
