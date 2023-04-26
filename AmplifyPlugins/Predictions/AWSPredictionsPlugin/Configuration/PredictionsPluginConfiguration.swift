//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//import AWSCore

public struct PredictionsPluginConfiguration {
    public let defaultRegion: String
    public var identify: IdentifyConfiguration
    public var interpret: InterpretConfiguration
    public var convert: ConvertConfiguration
}

extension PredictionsPluginConfiguration: Decodable {
    enum CodingKeys: String, CodingKey {
        case identify
        case interpret
        case convert
        case defaultRegion
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let regionString = try values.decode(String.self, forKey: .defaultRegion)
        self.defaultRegion = regionString

        if let configuration = try values.decodeIfPresent(
            IdentifyConfiguration.self, forKey: .identify
        ) {
            self.identify = configuration
        } else {
            self.identify = IdentifyConfiguration(defaultRegion)
        }

        if let configuration = try values.decodeIfPresent(
            InterpretConfiguration.self, forKey: .interpret
        ) {
            self.interpret = configuration
        } else {
            self.interpret = InterpretConfiguration(defaultRegion)
        }

        if let configuration = try values.decodeIfPresent(
            ConvertConfiguration.self, forKey: .convert
        ) {
            self.convert = configuration
        } else {
            self.convert = ConvertConfiguration(defaultRegion)
        }
    }
}
