//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate

// swiftlint:disable file_length
public protocol TranslateClientProtocol {
    /// Performs the `CreateParallelData` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Creates a parallel data resource in Amazon Translate by importing an input file from Amazon S3. Parallel data files contain examples that show how you want segments of text to be translated. By adding parallel data, you can influence the style, tone, and word choice in your translation output.
    ///
    /// - Parameter CreateParallelDataInput : [no documentation found]
    ///
    /// - Returns: `CreateParallelDataOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Another modification is being made. That modification must complete before you can make your change.
    /// - `ConflictException` : There was a conflict processing the request. Try your request again.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `InvalidRequestException` : The request that you made is not valid. Check your request to determine why it's not valid and then retry the request.
    /// - `LimitExceededException` : The specified limit has been exceeded. Review your request and retry it with a quantity below the stated limit.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    /// - `TooManyTagsException` : You have added too many tags to this resource. The maximum is 50 tags.
    func createParallelData(input: CreateParallelDataInput) async throws -> CreateParallelDataOutput
    /// Performs the `DeleteParallelData` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Deletes a parallel data resource in Amazon Translate.
    ///
    /// - Parameter DeleteParallelDataInput : [no documentation found]
    ///
    /// - Returns: `DeleteParallelDataOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Another modification is being made. That modification must complete before you can make your change.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func deleteParallelData(input: DeleteParallelDataInput) async throws -> DeleteParallelDataOutput
    /// Performs the `DeleteTerminology` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// A synchronous action that deletes a custom terminology.
    ///
    /// - Parameter DeleteTerminologyInput : [no documentation found]
    ///
    /// - Returns: `DeleteTerminologyOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func deleteTerminology(input: DeleteTerminologyInput) async throws -> DeleteTerminologyOutput
    /// Performs the `DescribeTextTranslationJob` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Gets the properties associated with an asynchronous batch translation job including name, ID, status, source and target languages, input/output S3 buckets, and so on.
    ///
    /// - Parameter DescribeTextTranslationJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeTextTranslationJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func describeTextTranslationJob(input: DescribeTextTranslationJobInput) async throws -> DescribeTextTranslationJobOutput
    /// Performs the `GetParallelData` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Provides information about a parallel data resource.
    ///
    /// - Parameter GetParallelDataInput : [no documentation found]
    ///
    /// - Returns: `GetParallelDataOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func getParallelData(input: GetParallelDataInput) async throws -> GetParallelDataOutput
    /// Performs the `GetTerminology` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Retrieves a custom terminology.
    ///
    /// - Parameter GetTerminologyInput : [no documentation found]
    ///
    /// - Returns: `GetTerminologyOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func getTerminology(input: GetTerminologyInput) async throws -> GetTerminologyOutput
    /// Performs the `ImportTerminology` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Creates or updates a custom terminology, depending on whether one already exists for the given terminology name. Importing a terminology with the same name as an existing one will merge the terminologies based on the chosen merge strategy. The only supported merge strategy is OVERWRITE, where the imported terminology overwrites the existing terminology of the same name. If you import a terminology that overwrites an existing one, the new terminology takes up to 10 minutes to fully propagate. After that, translations have access to the new terminology.
    ///
    /// - Parameter ImportTerminologyInput : [no documentation found]
    ///
    /// - Returns: `ImportTerminologyOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Another modification is being made. That modification must complete before you can make your change.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `LimitExceededException` : The specified limit has been exceeded. Review your request and retry it with a quantity below the stated limit.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    /// - `TooManyTagsException` : You have added too many tags to this resource. The maximum is 50 tags.
    func importTerminology(input: ImportTerminologyInput) async throws -> ImportTerminologyOutput
    /// Performs the `ListLanguages` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Provides a list of languages (RFC-5646 codes and names) that Amazon Translate supports.
    ///
    /// - Parameter ListLanguagesInput : [no documentation found]
    ///
    /// - Returns: `ListLanguagesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    /// - `UnsupportedDisplayLanguageCodeException` : Requested display language code is not supported.
    func listLanguages(input: ListLanguagesInput) async throws -> ListLanguagesOutput
    /// Performs the `ListParallelData` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Provides a list of your parallel data resources in Amazon Translate.
    ///
    /// - Parameter ListParallelDataInput : [no documentation found]
    ///
    /// - Returns: `ListParallelDataOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func listParallelData(input: ListParallelDataInput) async throws -> ListParallelDataOutput
    /// Performs the `ListTagsForResource` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Lists all tags associated with a given Amazon Translate resource. For more information, see [ Tagging your resources](https://docs.aws.amazon.com/translate/latest/dg/tagging.html).
    ///
    /// - Parameter ListTagsForResourceInput : [no documentation found]
    ///
    /// - Returns: `ListTagsForResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    func listTagsForResource(input: ListTagsForResourceInput) async throws -> ListTagsForResourceOutput
    /// Performs the `ListTerminologies` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Provides a list of custom terminologies associated with your account.
    ///
    /// - Parameter ListTerminologiesInput : [no documentation found]
    ///
    /// - Returns: `ListTerminologiesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func listTerminologies(input: ListTerminologiesInput) async throws -> ListTerminologiesOutput
    /// Performs the `ListTextTranslationJobs` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Gets a list of the batch translation jobs that you have submitted.
    ///
    /// - Parameter ListTextTranslationJobsInput : [no documentation found]
    ///
    /// - Returns: `ListTextTranslationJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is not valid. Specify a different filter.
    /// - `InvalidRequestException` : The request that you made is not valid. Check your request to determine why it's not valid and then retry the request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func listTextTranslationJobs(input: ListTextTranslationJobsInput) async throws -> ListTextTranslationJobsOutput
    /// Performs the `StartTextTranslationJob` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Starts an asynchronous batch translation job. Use batch translation jobs to translate large volumes of text across multiple documents at once. For batch translation, you can input documents with different source languages (specify auto as the source language). You can specify one or more target languages. Batch translation translates each input document into each of the target languages. For more information, see [Asynchronous batch processing](https://docs.aws.amazon.com/translate/latest/dg/async.html). Batch translation jobs can be described with the [DescribeTextTranslationJob] operation, listed with the [ListTextTranslationJobs] operation, and stopped with the [StopTextTranslationJob] operation.
    ///
    /// - Parameter StartTextTranslationJobInput : [no documentation found]
    ///
    /// - Returns: `StartTextTranslationJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `InvalidRequestException` : The request that you made is not valid. Check your request to determine why it's not valid and then retry the request.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    /// - `UnsupportedLanguagePairException` : Amazon Translate does not support translation from the language of the source text into the requested target language. For more information, see [Supported languages](https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html).
    func startTextTranslationJob(input: StartTextTranslationJobInput) async throws -> StartTextTranslationJobOutput
    /// Performs the `StopTextTranslationJob` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Stops an asynchronous batch translation job that is in progress. If the job's state is IN_PROGRESS, the job will be marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state. Otherwise, the job is put into the STOPPED state. Asynchronous batch translation jobs are started with the [StartTextTranslationJob] operation. You can use the [DescribeTextTranslationJob] or [ListTextTranslationJobs] operations to get a batch translation job's JobId.
    ///
    /// - Parameter StopTextTranslationJobInput : [no documentation found]
    ///
    /// - Returns: `StopTextTranslationJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func stopTextTranslationJob(input: StopTextTranslationJobInput) async throws -> StopTextTranslationJobOutput
    /// Performs the `TagResource` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Associates a specific tag with a resource. A tag is a key-value pair that adds as a metadata to a resource. For more information, see [ Tagging your resources](https://docs.aws.amazon.com/translate/latest/dg/tagging.html).
    ///
    /// - Parameter TagResourceInput : [no documentation found]
    ///
    /// - Returns: `TagResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Another modification is being made. That modification must complete before you can make your change.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyTagsException` : You have added too many tags to this resource. The maximum is 50 tags.
    func tagResource(input: TagResourceInput) async throws -> TagResourceOutput
    /// Performs the `TranslateDocument` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Translates the input document from the source language to the target language. This synchronous operation supports text, HTML, or Word documents as the input document. TranslateDocument supports translations from English to any supported language, and from any supported language to English. Therefore, specify either the source language code or the target language code as “en” (English). If you set the Formality parameter, the request will fail if the target language does not support formality. For a list of target languages that support formality, see [Setting formality](https://docs.aws.amazon.com/translate/latest/dg/customizing-translations-formality.html).
    ///
    /// - Parameter TranslateDocumentInput : [no documentation found]
    ///
    /// - Returns: `TranslateDocumentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request that you made is not valid. Check your request to determine why it's not valid and then retry the request.
    /// - `LimitExceededException` : The specified limit has been exceeded. Review your request and retry it with a quantity below the stated limit.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `ServiceUnavailableException` : The Amazon Translate service is temporarily unavailable. Wait a bit and then retry your request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    /// - `UnsupportedLanguagePairException` : Amazon Translate does not support translation from the language of the source text into the requested target language. For more information, see [Supported languages](https://docs.aws.amazon.com/translate/latest/dg/what-is-languages.html).
    func translateDocument(input: TranslateDocumentInput) async throws -> TranslateDocumentOutput
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
    /// Performs the `UntagResource` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Removes a specific tag associated with an Amazon Translate resource. For more information, see [ Tagging your resources](https://docs.aws.amazon.com/translate/latest/dg/tagging.html).
    ///
    /// - Parameter UntagResourceInput : [no documentation found]
    ///
    /// - Returns: `UntagResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Another modification is being made. That modification must complete before you can make your change.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    func untagResource(input: UntagResourceInput) async throws -> UntagResourceOutput
    /// Performs the `UpdateParallelData` operation on the `AWSShineFrontendService_20170701` service.
    ///
    /// Updates a previously created parallel data resource by importing a new input file from Amazon S3.
    ///
    /// - Parameter UpdateParallelDataInput : [no documentation found]
    ///
    /// - Returns: `UpdateParallelDataOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Another modification is being made. That modification must complete before you can make your change.
    /// - `ConflictException` : There was a conflict processing the request. Try your request again.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidParameterValueException` : The value of the parameter is not valid. Review the value of the parameter you are using to correct it, and then retry your operation.
    /// - `InvalidRequestException` : The request that you made is not valid. Check your request to determine why it's not valid and then retry the request.
    /// - `LimitExceededException` : The specified limit has been exceeded. Review your request and retry it with a quantity below the stated limit.
    /// - `ResourceNotFoundException` : The resource you are looking for has not been found. Review the resource you're looking for and see if a different resource will accomplish your needs before retrying the revised request.
    /// - `TooManyRequestsException` : You have made too many requests within a short period of time. Wait for a short time and then try your request again.
    func updateParallelData(input: UpdateParallelDataInput) async throws -> UpdateParallelDataOutput
}
extension TranslateClient: TranslateClientProtocol { }
