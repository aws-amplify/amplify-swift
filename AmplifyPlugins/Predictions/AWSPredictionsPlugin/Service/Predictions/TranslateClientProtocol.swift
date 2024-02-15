//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate

public protocol TranslateClientProtocol {

    /// Performs the `TranslateText` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Translates input text from the source language to the target language. For a list of available languages and language codes, see [Supported languages](https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html).
    ///
    /// - Parameter TranslateTextInput : [no documentation found]
    ///
    /// - Returns: `TranslateTextOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `DetectedLanguageLowConfidenceException` : The confidence that Amazon Comprehend accurately detected the source language is low. If a low confidence level is acceptable for your application, you can use the language in the exception to call Amazon Translate again. For more information, see the [DetectDominantLanguage](https://docs.aws.amazon.com/comprehend/latest/dg/API_DetectDominantLanguage.html) operation in the Amazon Comprehend Developer Guide.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request that you made is not valid. Check your request to determine why it's not valid and then retry the request.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `ServiceUnavailableException` : The Amazon Translate service is temporarily unavailable. Wait a bit and then retry your request.
    /// - `TextSizeLimitExceededException` : The size of the text you submitted exceeds the size limit. Reduce the size of the text or use a smaller document and then retry your request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    /// - `UnsupportedLanguagePairException` : Amazon Translate does not support translation from the language of the source text into the requested target language. For more information, see [Supported languages](https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html).
    func translateText(input: TranslateTextInput) async throws -> TranslateTextOutput
}

extension TranslateClient: TranslateClientProtocol { }
