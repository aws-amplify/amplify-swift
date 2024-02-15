//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend

public protocol ComprehendClientProtocol {

    /// Performs the `DetectDominantLanguage` operation on the `Comprehend_20171127` service.
    ///
    /// Determines the dominant language of the input text. For a list of languages that Amazon Comprehend can detect, see [Amazon Comprehend Supported Languages](https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html).
    ///
    /// - Parameter DetectDominantLanguageInput : [no documentation found]
    ///
    /// - Returns: `DetectDominantLanguageOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    func detectDominantLanguage(input: DetectDominantLanguageInput) async throws -> DetectDominantLanguageOutput

    /// Performs the `DetectSyntax` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects text for syntax and the part of speech of words in the document. For more information, see [Syntax](https://docs.aws.amazon.com/comprehend/latest/dg/how-syntax.html) in the Comprehend Developer Guide.
    ///
    /// - Parameter DetectSyntaxInput : [no documentation found]
    ///
    /// - Returns: `DetectSyntaxOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectSyntax(input: DetectSyntaxInput) async throws -> DetectSyntaxOutput

    /// Performs the `DetectSyntax` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects text for syntax and the part of speech of words in the document. For more information, see [Syntax](https://docs.aws.amazon.com/comprehend/latest/dg/how-syntax.html) in the Comprehend Developer Guide.
    ///
    /// - Parameter DetectSyntaxInput : [no documentation found]
    ///
    /// - Returns: `DetectSyntaxOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectKeyPhrases(input: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutput

    /// Performs the `DetectSentiment` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects text and returns an inference of the prevailing sentiment (POSITIVE, NEUTRAL, MIXED, or NEGATIVE).
    ///
    /// - Parameter DetectSentimentInput : [no documentation found]
    ///
    /// - Returns: `DetectSentimentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectSentiment(input: DetectSentimentInput) async throws -> DetectSentimentOutput

    /// Performs the `DetectEntities` operation on the `Comprehend_20171127` service.
    ///
    /// Detects named entities in input text when you use the pre-trained model. Detects custom entities if you have a custom entity recognition model. When detecting named entities using the pre-trained model, use plain text as the input. For more information about named entities, see [Entities](https://docs.aws.amazon.com/comprehend/latest/dg/how-entities.html) in the Comprehend Developer Guide. When you use a custom entity recognition model, you can input plain text or you can upload a single-page input document (text, PDF, Word, or image). If the system detects errors while processing a page in the input document, the API response includes an entry in Errors for each error. If the system detects a document-level error in your input document, the API returns an InvalidRequestException error response. For details about this exception, see [ Errors in semi-structured documents](https://docs.aws.amazon.com/comprehend/latest/dg/idp-inputs-sync-err.html) in the Comprehend Developer Guide.
    ///
    /// - Parameter DetectEntitiesInput : [no documentation found]
    ///
    /// - Returns: `DetectEntitiesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectEntities(input: DetectEntitiesInput) async throws -> DetectEntitiesOutput
}

extension ComprehendClient: ComprehendClientProtocol { }
