//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(InternalAWSPinpoint)
public struct ProvisioningProfile {
    enum APSEnvironment: String {
        case development
        case production
    }

    var apsEnvironment: APSEnvironment?
}

@_spi(InternalAWSPinpoint)
public protocol ProvisioningProfileReader {
    func profile() -> ProvisioningProfile?
}

@_spi(InternalAWSPinpoint)
public extension ProvisioningProfileReader where Self == DefaultProvisioningProfileReader {
    static var `default`: ProvisioningProfileReader {
        DefaultProvisioningProfileReader()
    }
}

@_spi(InternalAWSPinpoint)
public struct DefaultProvisioningProfileReader: ProvisioningProfileReader {
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

    public func profile() -> ProvisioningProfile? {
        guard let contents = contents,
              let provisioning = try? PropertyListSerialization.propertyList(
                  from: contents,
                  format: nil
              ) as? [String: Any] else {
            return nil
        }

        var profile = ProvisioningProfile()
        if let entitlements = provisioning[Keys.entitlements] as? [String: Any],
           let apnsEnvironment = entitlements[Keys.apsEnvironment] as? String {
            profile.apsEnvironment = ProvisioningProfile.APSEnvironment(rawValue: apnsEnvironment)
        }

        return profile
    }
}
