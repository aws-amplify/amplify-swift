//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly

// swiftlint:disable file_length
public protocol PollyClientProtocol {
    /// Performs the `DeleteLexicon` operation on the `Parrot_v1` service.
    ///
    /// Deletes the specified pronunciation lexicon stored in an Amazon Web Services Region. A lexicon which has been deleted is not available for speech synthesis, nor is it possible to retrieve it using either the GetLexicon or ListLexicon APIs. For more information, see [Managing Lexicons](https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
    ///
    /// - Parameter DeleteLexiconInput : [no documentation found]
    ///
    /// - Returns: `DeleteLexiconOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `LexiconNotFoundException` : Amazon Polly can't find the specified lexicon. This could be caused by a lexicon that is missing, its name is misspelled or specifying a lexicon that is in a different region. Verify that the lexicon exists, is in the region (see [ListLexicons]) and that you spelled its name is spelled correctly. Then try again.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    func deleteLexicon(input: DeleteLexiconInput) async throws -> DeleteLexiconOutput
    /// Performs the `DescribeVoices` operation on the `Parrot_v1` service.
    ///
    /// Returns the list of voices that are available for use when requesting speech synthesis. Each voice speaks a specified language, is either male or female, and is identified by an ID, which is the ASCII version of the voice name. When synthesizing speech ( SynthesizeSpeech ), you provide the voice ID for the voice you want from the list of voices returned by DescribeVoices. For example, you want your news reader application to read news in a specific language, but giving a user the option to choose the voice. Using the DescribeVoices operation you can provide the user with a list of available voices to select from. You can optionally specify a language code to filter the available voices. For example, if you specify en-US, the operation returns a list of all available US English voices. This operation requires permissions to perform the polly:DescribeVoices action.
    ///
    /// - Parameter DescribeVoicesInput : [no documentation found]
    ///
    /// - Returns: `DescribeVoicesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidNextTokenException` : The NextToken is invalid. Verify that it's spelled correctly, and then try again.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    func describeVoices(input: DescribeVoicesInput) async throws -> DescribeVoicesOutput
    /// Performs the `GetLexicon` operation on the `Parrot_v1` service.
    ///
    /// Returns the content of the specified pronunciation lexicon stored in an Amazon Web Services Region. For more information, see [Managing Lexicons](https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
    ///
    /// - Parameter GetLexiconInput : [no documentation found]
    ///
    /// - Returns: `GetLexiconOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `LexiconNotFoundException` : Amazon Polly can't find the specified lexicon. This could be caused by a lexicon that is missing, its name is misspelled or specifying a lexicon that is in a different region. Verify that the lexicon exists, is in the region (see [ListLexicons]) and that you spelled its name is spelled correctly. Then try again.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    func getLexicon(input: GetLexiconInput) async throws -> GetLexiconOutput
    /// Performs the `GetSpeechSynthesisTask` operation on the `Parrot_v1` service.
    ///
    /// Retrieves a specific SpeechSynthesisTask object based on its TaskID. This object contains information about the given speech synthesis task, including the status of the task, and a link to the S3 bucket containing the output of the task.
    ///
    /// - Parameter GetSpeechSynthesisTaskInput : [no documentation found]
    ///
    /// - Returns: `GetSpeechSynthesisTaskOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidTaskIdException` : The provided Task ID is not valid. Please provide a valid Task ID and try again.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    /// - `SynthesisTaskNotFoundException` : The Speech Synthesis task with requested Task ID cannot be found.
    func getSpeechSynthesisTask(input: GetSpeechSynthesisTaskInput) async throws -> GetSpeechSynthesisTaskOutput
    /// Performs the `ListLexicons` operation on the `Parrot_v1` service.
    ///
    /// Returns a list of pronunciation lexicons stored in an Amazon Web Services Region. For more information, see [Managing Lexicons](https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
    ///
    /// - Parameter ListLexiconsInput : [no documentation found]
    ///
    /// - Returns: `ListLexiconsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidNextTokenException` : The NextToken is invalid. Verify that it's spelled correctly, and then try again.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    func listLexicons(input: ListLexiconsInput) async throws -> ListLexiconsOutput
    /// Performs the `ListSpeechSynthesisTasks` operation on the `Parrot_v1` service.
    ///
    /// Returns a list of SpeechSynthesisTask objects ordered by their creation date. This operation can filter the tasks by their status, for example, allowing users to list only tasks that are completed.
    ///
    /// - Parameter ListSpeechSynthesisTasksInput : [no documentation found]
    ///
    /// - Returns: `ListSpeechSynthesisTasksOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidNextTokenException` : The NextToken is invalid. Verify that it's spelled correctly, and then try again.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    func listSpeechSynthesisTasks(input: ListSpeechSynthesisTasksInput) async throws -> ListSpeechSynthesisTasksOutput
    /// Performs the `PutLexicon` operation on the `Parrot_v1` service.
    ///
    /// Stores a pronunciation lexicon in an Amazon Web Services Region. If a lexicon with the same name already exists in the region, it is overwritten by the new lexicon. Lexicon operations have eventual consistency, therefore, it might take some time before the lexicon is available to the SynthesizeSpeech operation. For more information, see [Managing Lexicons](https://docs.aws.amazon.com/polly/latest/dg/managing-lexicons.html).
    ///
    /// - Parameter PutLexiconInput : [no documentation found]
    ///
    /// - Returns: `PutLexiconOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InvalidLexiconException` : Amazon Polly can't find the specified lexicon. Verify that the lexicon's name is spelled correctly, and then try again.
    /// - `LexiconSizeExceededException` : The maximum size of the specified lexicon would be exceeded by this operation.
    /// - `MaxLexemeLengthExceededException` : The maximum size of the lexeme would be exceeded by this operation.
    /// - `MaxLexiconsNumberExceededException` : The maximum number of lexicons would be exceeded by this operation.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    /// - `UnsupportedPlsAlphabetException` : The alphabet specified by the lexicon is not a supported alphabet. Valid values are x-sampa and ipa.
    /// - `UnsupportedPlsLanguageException` : The language specified in the lexicon is unsupported. For a list of supported languages, see [Lexicon Attributes](https://docs.aws.amazon.com/polly/latest/dg/API_LexiconAttributes.html).
    func putLexicon(input: PutLexiconInput) async throws -> PutLexiconOutput
    /// Performs the `StartSpeechSynthesisTask` operation on the `Parrot_v1` service.
    ///
    /// Allows the creation of an asynchronous synthesis task, by starting a new SpeechSynthesisTask. This operation requires all the standard information needed for speech synthesis, plus the name of an Amazon S3 bucket for the service to store the output of the synthesis task and two optional parameters (OutputS3KeyPrefix and SnsTopicArn). Once the synthesis task is created, this operation will return a SpeechSynthesisTask object, which will include an identifier of this task as well as the current status. The SpeechSynthesisTask object is available for 72 hours after starting the asynchronous synthesis task.
    ///
    /// - Parameter StartSpeechSynthesisTaskInput : [no documentation found]
    ///
    /// - Returns: `StartSpeechSynthesisTaskOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `EngineNotSupportedException` : This engine is not compatible with the voice that you have designated. Choose a new voice that is compatible with the engine or change the engine and restart the operation.
    /// - `InvalidS3BucketException` : The provided Amazon S3 bucket name is invalid. Please check your input with S3 bucket naming requirements and try again.
    /// - `InvalidS3KeyException` : The provided Amazon S3 key prefix is invalid. Please provide a valid S3 object key name.
    /// - `InvalidSampleRateException` : The specified sample rate is not valid.
    /// - `InvalidSnsTopicArnException` : The provided SNS topic ARN is invalid. Please provide a valid SNS topic ARN and try again.
    /// - `InvalidSsmlException` : The SSML you provided is invalid. Verify the SSML syntax, spelling of tags and values, and then try again.
    /// - `LanguageNotSupportedException` : The language specified is not currently supported by Amazon Polly in this capacity.
    /// - `LexiconNotFoundException` : Amazon Polly can't find the specified lexicon. This could be caused by a lexicon that is missing, its name is misspelled or specifying a lexicon that is in a different region. Verify that the lexicon exists, is in the region (see [ListLexicons]) and that you spelled its name is spelled correctly. Then try again.
    /// - `MarksNotSupportedForFormatException` : Speech marks are not supported for the OutputFormat selected. Speech marks are only available for content in json format.
    /// - `ServiceFailureException` : An unknown condition has caused a service failure.
    /// - `SsmlMarksNotSupportedForTextTypeException` : SSML speech marks are not supported for plain text-type input.
    /// - `TextLengthExceededException` : The value of the "Text" parameter is longer than the accepted limits. For the SynthesizeSpeech API, the limit for input text is a maximum of 6000 characters total, of which no more than 3000 can be billed characters. For the StartSpeechSynthesisTask API, the maximum is 200,000 characters, of which no more than 100,000 can be billed characters. SSML tags are not counted as billed characters.
    func startSpeechSynthesisTask(input: StartSpeechSynthesisTaskInput) async throws -> StartSpeechSynthesisTaskOutput
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
