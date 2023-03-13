//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct InterpretConfiguration {
    public var region: AWSRegionType

    public init(_ region: AWSRegionType) {
        self.region = region
    }
}

extension InterpretConfiguration: Decodable {

    enum CodingKeys: String, CodingKey {
        case interpretText
    }

    enum InterpretTextKeys: String, CodingKey {
        case region
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let additionalInfo = try values.nestedContainer(keyedBy: InterpretTextKeys.self, forKey: .interpretText)
        let regionString = try additionalInfo.decode(String.self, forKey: .region) as NSString
        self.region = regionString.aws_regionTypeValue()
    }
}
