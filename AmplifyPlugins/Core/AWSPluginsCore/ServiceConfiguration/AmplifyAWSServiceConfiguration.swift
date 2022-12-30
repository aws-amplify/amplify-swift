//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

public class AmplifyAWSServiceConfiguration: AWSServiceConfiguration {
    static let version = "1.28.4"

    override public class func baseUserAgent() -> String! {
        let platformInfo = AmplifyAWSServiceConfiguration.platformInformation()
        let systemName = UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
        let systemVersion = UIDevice.current.systemVersion
        let localeIdentifier = Locale.current.identifier
        return "\(platformInfo) \(systemName)/\(systemVersion) \(localeIdentifier)"
    }

    override public var userAgent: String {
        return AmplifyAWSServiceConfiguration.baseUserAgent()
    }

    override public func copy(with zone: NSZone? = nil) -> Any {
        return super.copy(with: zone)
    }

    override init() {
        super.init(region: .Unknown, credentialsProvider: nil)
    }

    override public init(region regionType: AWSRegionType,
                         credentialsProvider: AWSCredentialsProvider) {
        super.init(region: regionType, credentialsProvider: credentialsProvider)
    }

    public init(region regionType: AWSRegionType) {
        super.init(region: regionType, credentialsProvider: nil)
    }

    public init(region regionType: AWSRegionType, endpoint: AWSEndpoint) {
        super.init(region: regionType, endpoint: endpoint, credentialsProvider: nil)
    }

    override public init(region regionType: AWSRegionType,
                         endpoint: AWSEndpoint,
                         credentialsProvider: AWSCredentialsProvider,
                         localTestingEnabled: Bool) {
        super.init(region: regionType,
                   endpoint: endpoint,
                   credentialsProvider: credentialsProvider,
                   localTestingEnabled: localTestingEnabled)
    }
}
