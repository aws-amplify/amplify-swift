//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import NaturalLanguage

public class CoreMLInterpretOperation: AmplifyOperation<
    PredictionsInterpretRequest,
    Void,
    InterpretResult,
    PredictionsError>,
PredictionsInterpretOperation {

    override public func cancel() {
        super.cancel()
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        let text = ""
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NLTag] = [.personalName, .placeName, .organizationName]
        tagger.enumerateTags(in: text.startIndex ..< text.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, tokenRange in

            if let tag = tag, tags.contains(tag) {
                print("\(text[tokenRange]): \(tag.rawValue)")
            }
            return true
        }
    }

    private func onServiceEvent(event: CoreMLPredictionsEvent<InterpretResult, PredictionsError>) {
        switch event {
        case .completed(let result):
            dispatch(result)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }
    private func dispatch(_ result: InterpretResult) {
        let asyncEvent = AsyncEvent<Void, InterpretResult, PredictionsError>.completed(result)
        dispatch(event: asyncEvent)

    }

    private func dispatch(_ error: PredictionsError) {
        let asyncEvent = AsyncEvent<Void, InterpretResult, PredictionsError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
