//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly

public protocol PollyClientProtocol {

    /// Performs the `SynthesizeSpeech` operation on the `Parrot_v1` service.
    ///
    /// Synthesizes UTF-8 input, plain text or SSML, to a stream of bytes. SSML input must be valid, well-formed SSML. Some alphabets might not be available with all the voices (for example, Cyrillic might not be read at all by English voices) unless phoneme mapping is used. For more information, see [How it Works](https://docs.aws.amazon.com/polly/latest/dg/how-text-to-speech-works.html).
    ///
    /// - Parameter SynthesizeSpeechInput : [no documentation found]
    ///
    /// - Returns: `SynthesizeSpeechOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `EngineNotSupportedException` : This engine is not compatible with the voice that you have designated. Choose a new voice that is compatible with the engine or change the engine and restart the operation.
    /// - `InvalidSampleRateException` : The specified sample rate is not valid.
    /// - `InvalidSsmlException` : The SSML you provided is invalid. Verify the SSML syntax, spelling of tags and values, and then try again.
    /// - `LanguageNotSupportedException` : The language specified is not currently supported by Amazon Polly in this capacity.
    /// - `LexiconNotFoundException` : Amazon Polly can't find the specified lexicon. This could be caused by a lexicon that is missing, its name is misspelled or specifying a lexicon that is in a different region. Verify that the lexicon exists, is in the region (see [ListLexicons]) and that you spelled its name is spelled correctly. Then try again.
    /// - `MarksNotSupportedForFormatException` : Speech marks are not supported for the OutputFormat selected. Speech marks are only available for content in json format.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    /// - `SsmlMarksNotSupportedForTextTypeException` : SSML speech marks are not supported for plain text-type input.
    /// - `TextLengthExceededException` : The value of the "Text" parameter is longer than the accepted limits. For the SynthesizeSpeech API, the limit for input text is a maximum of 6000 characters total, of which no more than 3000 can be billed characters. For the StartSpeechSynthesisTask API, the maximum is 200,000 characters, of which no more than 100,000 can be billed characters. SSML tags are not counted as billed characters.
    func synthesizeSpeech(input: SynthesizeSpeechInput) async throws -> SynthesizeSpeechOutput
}

extension PollyClient: PollyClientProtocol { }
