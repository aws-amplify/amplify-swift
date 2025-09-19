//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ClientChallenge: Codable {
    let type: ChallengeType

    init(clientChallengeType: ChallengeType) {
        self.type = clientChallengeType
    }

    enum CodingKeys: String, CodingKey {
        case faceMovementAndLightChallenge = "FaceMovementAndLightChallenge"
        case faceMovementChallenge = "FaceMovementChallenge"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch type {
        case .faceMovementChallenge(let faceMovementServerChallenge):
            try container.encode(faceMovementServerChallenge, forKey: .faceMovementChallenge)
        case .faceMovementAndLightChallenge(let faceMovementAndLightServerChallenge):
            try container.encode(faceMovementAndLightServerChallenge, forKey: .faceMovementAndLightChallenge)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(FaceMovementClientChallenge.self, forKey: .faceMovementChallenge) {
            self.type = .faceMovementChallenge(challenge: value)
        } else if let value = try? container.decode(FaceMovementAndLightClientChallenge.self, forKey: .faceMovementAndLightChallenge) {
            self.type = .faceMovementAndLightChallenge(challenge: value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unexpected data format"
                )
            )
        }
    }
}

extension ClientChallenge {
    enum ChallengeType: Codable {
        case faceMovementChallenge(challenge: FaceMovementClientChallenge)
        case faceMovementAndLightChallenge(challenge: FaceMovementAndLightClientChallenge)
    }
}
