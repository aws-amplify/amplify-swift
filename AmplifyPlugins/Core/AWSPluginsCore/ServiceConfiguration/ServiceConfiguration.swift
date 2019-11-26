//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore

public class ServiceConfiguration: AWSServiceConfiguration {

    static let baseUserAgent: String = {
        let version = "0.0.1"
        let sdkName = "aws-amplify-iOS"
        let systemName = UIDevice.current.systemName.replacingOccurrences(of: " ", with: "-")
        let systemVersion = UIDevice.current.systemVersion
        let localeIdentifier = Locale.current.identifier
        return "\(sdkName)/\(version) \(systemName)/\(systemVersion) \(localeIdentifier)"
    }()

    override public var userAgent: String {
        return ServiceConfiguration.baseUserAgent
    }

    override public func copy(with zone: NSZone? = nil) -> Any {
        return super.copy(with: zone)
    }

    override init() {
        super.init(region: .Unknown, credentialsProvider: nil)
    }

    override public init(region regionType: AWSRegionType,
                         credentialsProvider: AWSCredentialsProvider!) {
        super.init(region: regionType, credentialsProvider: credentialsProvider)
    }
}
