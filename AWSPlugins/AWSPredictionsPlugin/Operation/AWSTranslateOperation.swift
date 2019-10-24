//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AWSTranslateOperation: AmplifyOperation<PredictionsConvertRequest, Void, Void, PredictionsError>,
PredictionsConvertOperation {

    let translateService: AWSTranslateService

    init(_ request: PredictionsConvertRequest,
         translateService: AWSTranslateService) {
        self.translateService = translateService
        super.init(categoryType: .predictions,
                   eventName: HubPayload.EventName.Storage.downloadFile,
                   request: request)
    }

    override public func cancel() {
        super.cancel()
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }


        translateService.translateText(text: request.textToTranslate) { [weak self] event in
            self?.onServiceEvent(event: event)

        }
    }

    private func onServiceEvent(event: PredictionsEvent<String, PredictionsError>) {
        switch event {
        case .completed(let result):

            finish()
        case .failed(let error):

            finish()
        default:
            break
        }
    }

}
