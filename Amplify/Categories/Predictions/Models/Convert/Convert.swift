//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Predictions {
    public enum Convert {
        public struct Request<Input, Options, Output> {
            public let input: Input
            @_spi(PredictionsConvertRequestKind)
            public let kind: Kind
        }
    }
}

extension Predictions.Convert.Request {
    @_spi(PredictionsConvertRequestKind)
    public enum Kind {
        public typealias BidirectionalLift<T, U> = ((T) -> U, (U) -> T)

        case textToSpeech(
            Lift<
            String, Input,
            PredictionsTextToSpeechRequest.Options?, Options?,
            TextToSpeechResult, Output
            >
        )

        case speechToText(
            Lift<
            URL, Input,
            PredictionsSpeechToTextRequest.Options?, Options?,
            AsyncThrowingStream<SpeechToTextResult, Error>, Output
            >
        )

        case textToTranslate(
            Lift<
            (String, LanguageType?, LanguageType?), Input,
            PredictionsTranslateTextRequest.Options?, Options?,
            TranslateTextResult, Output
            >
        )
    }
}

extension Predictions.Convert.Request.Kind {
    public struct Lift<
        SpecificInput,
        GenericInput,
        SpecificOptions,
        GenericOptions,
        SpecificOutput,
        GenericOutput
    > {
        public let inputSpecificToGeneric: (SpecificInput) -> GenericInput
        public let inputGenericToSpecific: (GenericInput) -> SpecificInput
        public let optionsSpecificToGeneric: (SpecificOptions) -> GenericOptions
        public let optionsGenericToSpecific: (GenericOptions) -> SpecificOptions
        public let outputSpecificToGeneric: (SpecificOutput) -> GenericOutput
        public let outputGenericToSpecific: (GenericOutput) -> SpecificOutput
    }
}

extension Predictions.Convert.Request.Kind.Lift where
GenericInput == SpecificInput,
GenericOptions == SpecificOptions,
GenericOutput == SpecificOutput {
    static var lift: Self {
        .init(
            inputSpecificToGeneric: { $0 },
            inputGenericToSpecific: { $0 },
            optionsSpecificToGeneric: { $0 },
            optionsGenericToSpecific: { $0 },
            outputSpecificToGeneric: { $0 },
            outputGenericToSpecific: { $0 }
        )
    }
}


extension Predictions.Convert.Request where
Input == URL,
Options == PredictionsSpeechToTextRequest.Options,
Output == AsyncThrowingStream<SpeechToTextResult, Error> {

    public static func speechToText(url: URL) -> Self {
        .init(
            input: url,
            kind: .speechToText(.lift)
        )
    }
}

extension Predictions.Convert.Request where
Input == (String, LanguageType?, LanguageType?),
Options == PredictionsTranslateTextRequest.Options,
Output == TranslateTextResult {

    public static func textToTranslate(
        _ text: String,
        from: LanguageType? = nil,
        to: LanguageType? = nil
    ) -> Self {
        .init(
            input: (text, from, to),
            kind: .textToTranslate(.lift)
        )
    }
}

extension Predictions.Convert.Request where
Input == String,
Options == PredictionsTextToSpeechRequest.Options,
Output == TextToSpeechResult {

    public static func textToSpeech(_ text: String) -> Self {
        .init(
            input: text,
            kind: .textToSpeech(.lift)
        )
    }
}


