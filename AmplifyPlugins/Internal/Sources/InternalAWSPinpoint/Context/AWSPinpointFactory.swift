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

        var isDebug: Bool
        /// Check for the APS Environment entitlement in a provisioning profile first
        if let apsEnvironment = ProvisioningProfileReader().apsEnvironment() {
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

private struct ProvisioningProfileReader {
    enum APSEnvironment: String {
        case development
        case production
    }

    private struct Keys {
        static let entitlements = "Entitlements"
        static var apsEnvironment: String {
        #if os(macOS)
            return "com.apple.developer.aps-environment"
        #else
            return "aps-environment"
        #endif
        }
    }

    private let fileName = "embedded"
    private var fileExtension: String = {
    #if os(macOS)
        return "provisionprofile"
    #else
        return "mobileprovision"
    #endif
    }()

    private var url: URL? {
#if os(macOS)
        if let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) {
            return url
        }

        guard let enumerator =  FileManager.default.enumerator(
            at: Bundle.main.bundleURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return nil
        }

        let provisioningFile = "\(fileName).\(fileExtension)"
        for case let url as URL in enumerator where provisioningFile == url.lastPathComponent {
            return url
        }

        return nil
#else
        return Bundle.main.url(forResource: fileName, withExtension: fileExtension)
#endif
    }

    private var contents: Data? {
        guard let url = url,
              let contents =  try? String(contentsOf: url, encoding: .isoLatin1) else {
            return nil
        }

        let scanner = Scanner(string: contents)
        guard scanner.scanUpToString("<plist") != nil,
              let plist = scanner.scanUpToString("</plist>") else {
            return nil
        }

        return "\(plist)</plist>".data(using: .isoLatin1)
    }

    func apsEnvironment() -> APSEnvironment? {
        if let contents = contents,
           let provisioning = try? PropertyListSerialization.propertyList(from: contents,
                                                                          format: nil) as? [String: Any],
           let entitlements = provisioning[Keys.entitlements] as? [String: Any],
           let apnsEnvironment = entitlements[Keys.apsEnvironment] as? String {
            return APSEnvironment(rawValue: apnsEnvironment)
        }

        return nil
    }
}
