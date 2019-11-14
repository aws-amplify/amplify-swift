//
//  AWSPollyAdapter.swift
//  AWSPredictionsPlugin
//
//  Created by Stone, Nicki on 11/14/19.
//  Copyright © 2019 Amazon Web Services. All rights reserved.
//

import Foundation
import AWSPolly

class AWSPollyAdapter: AWSPollyBehavior {

    let awsPolly: AWSPolly

    init(_ awsPolly: AWSPolly) {
        self.awsPolly = awsPolly
    }

    func synthesizeSpeech(request: AWSPollySynthesizeSpeechInput) -> AWSTask<AWSPollySynthesizeSpeechOutput> {
        awsPolly.synthesizeSpeech(request)
    }

    func getPolly() -> AWSPolly {
        return awsPolly
    }

}
