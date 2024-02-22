//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSComprehend

// swiftlint:disable file_length
public protocol ComprehendClientProtocol {
    /// Performs the `BatchDetectDominantLanguage` operation on the `Comprehend_20171127` service.
    ///
    /// Determines the dominant language of the input text for a batch of documents. For a list of languages that Amazon Comprehend can detect, see [Amazon Comprehend Supported Languages](https://docs.aws.amazon.com/comprehend/latest/dg/how-languages.html).
    ///
    /// - Parameter BatchDetectDominantLanguageInput : [no documentation found]
    ///
    /// - Returns: `BatchDetectDominantLanguageOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BatchSizeLimitExceededException` : The number of documents in the request exceeds the limit of 25. Try your request again with fewer documents.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    func batchDetectDominantLanguage(input: BatchDetectDominantLanguageInput) async throws -> BatchDetectDominantLanguageOutput
    /// Performs the `BatchDetectEntities` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects the text of a batch of documents for named entities and returns information about them. For more information about named entities, see [Entities](https://docs.aws.amazon.com/comprehend/latest/dg/how-entities.html) in the Comprehend Developer Guide.
    ///
    /// - Parameter BatchDetectEntitiesInput : [no documentation found]
    ///
    /// - Returns: `BatchDetectEntitiesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BatchSizeLimitExceededException` : The number of documents in the request exceeds the limit of 25. Try your request again with fewer documents.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func batchDetectEntities(input: BatchDetectEntitiesInput) async throws -> BatchDetectEntitiesOutput
    /// Performs the `BatchDetectKeyPhrases` operation on the `Comprehend_20171127` service.
    ///
    /// Detects the key noun phrases found in a batch of documents.
    ///
    /// - Parameter BatchDetectKeyPhrasesInput : [no documentation found]
    ///
    /// - Returns: `BatchDetectKeyPhrasesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BatchSizeLimitExceededException` : The number of documents in the request exceeds the limit of 25. Try your request again with fewer documents.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func batchDetectKeyPhrases(input: BatchDetectKeyPhrasesInput) async throws -> BatchDetectKeyPhrasesOutput
    /// Performs the `BatchDetectSentiment` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects a batch of documents and returns an inference of the prevailing sentiment, POSITIVE, NEUTRAL, MIXED, or NEGATIVE, in each one.
    ///
    /// - Parameter BatchDetectSentimentInput : [no documentation found]
    ///
    /// - Returns: `BatchDetectSentimentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BatchSizeLimitExceededException` : The number of documents in the request exceeds the limit of 25. Try your request again with fewer documents.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func batchDetectSentiment(input: BatchDetectSentimentInput) async throws -> BatchDetectSentimentOutput
    /// Performs the `BatchDetectSyntax` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects the text of a batch of documents for the syntax and part of speech of the words in the document and returns information about them. For more information, see [Syntax](https://docs.aws.amazon.com/comprehend/latest/dg/how-syntax.html) in the Comprehend Developer Guide.
    ///
    /// - Parameter BatchDetectSyntaxInput : [no documentation found]
    ///
    /// - Returns: `BatchDetectSyntaxOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BatchSizeLimitExceededException` : The number of documents in the request exceeds the limit of 25. Try your request again with fewer documents.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func batchDetectSyntax(input: BatchDetectSyntaxInput) async throws -> BatchDetectSyntaxOutput
    /// Performs the `BatchDetectTargetedSentiment` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects a batch of documents and returns a sentiment analysis for each entity identified in the documents. For more information about targeted sentiment, see [Targeted sentiment](https://docs.aws.amazon.com/comprehend/latest/dg/how-targeted-sentiment.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter BatchDetectTargetedSentimentInput : [no documentation found]
    ///
    /// - Returns: `BatchDetectTargetedSentimentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `BatchSizeLimitExceededException` : The number of documents in the request exceeds the limit of 25. Try your request again with fewer documents.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func batchDetectTargetedSentiment(input: BatchDetectTargetedSentimentInput) async throws -> BatchDetectTargetedSentimentOutput
    /// Performs the `ClassifyDocument` operation on the `Comprehend_20171127` service.
    ///
    /// Creates a classification request to analyze a single document in real-time. ClassifyDocument supports the following model types:
    ///
    /// * Custom classifier - a custom model that you have created and trained. For input, you can provide plain text, a single-page document (PDF, Word, or image), or Amazon Textract API output. For more information, see [Custom classification](https://docs.aws.amazon.com/comprehend/latest/dg/how-document-classification.html) in the Amazon Comprehend Developer Guide.
    ///
    /// * Prompt safety classifier - Amazon Comprehend provides a pre-trained model for classifying input prompts for generative AI applications. For input, you provide English plain text input. For prompt safety classification, the response includes only the Classes field. For more information about prompt safety classifiers, see [Prompt safety classification](https://docs.aws.amazon.com/comprehend/latest/dg/trust-safety.html#prompt-classification) in the Amazon Comprehend Developer Guide.
    ///
    ///
    /// If the system detects errors while processing a page in the input document, the API response includes an Errors field that describes the errors. If the system detects a document-level error in your input document, the API returns an InvalidRequestException error response. For details about this exception, see [ Errors in semi-structured documents](https://docs.aws.amazon.com/comprehend/latest/dg/idp-inputs-sync-err.html) in the Comprehend Developer Guide.
    ///
    /// - Parameter ClassifyDocumentInput : [no documentation found]
    ///
    /// - Returns: `ClassifyDocumentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    func classifyDocument(input: ClassifyDocumentInput) async throws -> ClassifyDocumentOutput
    /// Performs the `ContainsPiiEntities` operation on the `Comprehend_20171127` service.
    ///
    /// Analyzes input text for the presence of personally identifiable information (PII) and returns the labels of identified PII entity types such as name, address, bank account number, or phone number.
    ///
    /// - Parameter ContainsPiiEntitiesInput : [no documentation found]
    ///
    /// - Returns: `ContainsPiiEntitiesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func containsPiiEntities(input: ContainsPiiEntitiesInput) async throws -> ContainsPiiEntitiesOutput
    /// Performs the `CreateDataset` operation on the `Comprehend_20171127` service.
    ///
    /// Creates a dataset to upload training or test data for a model associated with a flywheel. For more information about datasets, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter CreateDatasetInput : [no documentation found]
    ///
    /// - Returns: `CreateDatasetOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceLimitExceededException` : The maximum number of resources per account has been exceeded. Review the resources, and then try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func createDataset(input: CreateDatasetInput) async throws -> CreateDatasetOutput
    /// Performs the `CreateDocumentClassifier` operation on the `Comprehend_20171127` service.
    ///
    /// Creates a new document classifier that you can use to categorize documents. To create a classifier, you provide a set of training documents that are labeled with the categories that you want to use. For more information, see [Training classifier models](https://docs.aws.amazon.com/comprehend/latest/dg/training-classifier-model.html) in the Comprehend Developer Guide.
    ///
    /// - Parameter CreateDocumentClassifierInput : [no documentation found]
    ///
    /// - Returns: `CreateDocumentClassifierOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceLimitExceededException` : The maximum number of resources per account has been exceeded. Review the resources, and then try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func createDocumentClassifier(input: CreateDocumentClassifierInput) async throws -> CreateDocumentClassifierOutput
    /// Performs the `CreateEndpoint` operation on the `Comprehend_20171127` service.
    ///
    /// Creates a model-specific endpoint for synchronous inference for a previously trained custom model For information about endpoints, see [Managing endpoints](https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
    ///
    /// - Parameter CreateEndpointInput : [no documentation found]
    ///
    /// - Returns: `CreateEndpointOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceLimitExceededException` : The maximum number of resources per account has been exceeded. Review the resources, and then try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func createEndpoint(input: CreateEndpointInput) async throws -> CreateEndpointOutput
    /// Performs the `CreateEntityRecognizer` operation on the `Comprehend_20171127` service.
    ///
    /// Creates an entity recognizer using submitted files. After your CreateEntityRecognizer request is submitted, you can check job status using the DescribeEntityRecognizer API.
    ///
    /// - Parameter CreateEntityRecognizerInput : [no documentation found]
    ///
    /// - Returns: `CreateEntityRecognizerOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceLimitExceededException` : The maximum number of resources per account has been exceeded. Review the resources, and then try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func createEntityRecognizer(input: CreateEntityRecognizerInput) async throws -> CreateEntityRecognizerOutput
    /// Performs the `CreateFlywheel` operation on the `Comprehend_20171127` service.
    ///
    /// A flywheel is an Amazon Web Services resource that orchestrates the ongoing training of a model for custom classification or custom entity recognition. You can create a flywheel to start with an existing trained model, or Comprehend can create and train a new model. When you create the flywheel, Comprehend creates a data lake in your account. The data lake holds the training data and test data for all versions of the model. To use a flywheel with an existing trained model, you specify the active model version. Comprehend copies the model's training data and test data into the flywheel's data lake. To use the flywheel with a new model, you need to provide a dataset for training data (and optional test data) when you create the flywheel. For more information about flywheels, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter CreateFlywheelInput : [no documentation found]
    ///
    /// - Returns: `CreateFlywheelOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceLimitExceededException` : The maximum number of resources per account has been exceeded. Review the resources, and then try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func createFlywheel(input: CreateFlywheelInput) async throws -> CreateFlywheelOutput
    /// Performs the `DeleteDocumentClassifier` operation on the `Comprehend_20171127` service.
    ///
    /// Deletes a previously created document classifier Only those classifiers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a ResourceInUseException will be returned. This is an asynchronous action that puts the classifier into a DELETING state, and it is then removed by a background job. Once removed, the classifier disappears from your account and is no longer available for use.
    ///
    /// - Parameter DeleteDocumentClassifierInput : [no documentation found]
    ///
    /// - Returns: `DeleteDocumentClassifierOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func deleteDocumentClassifier(input: DeleteDocumentClassifierInput) async throws -> DeleteDocumentClassifierOutput
    /// Performs the `DeleteEndpoint` operation on the `Comprehend_20171127` service.
    ///
    /// Deletes a model-specific endpoint for a previously-trained custom model. All endpoints must be deleted in order for the model to be deleted. For information about endpoints, see [Managing endpoints](https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
    ///
    /// - Parameter DeleteEndpointInput : [no documentation found]
    ///
    /// - Returns: `DeleteEndpointOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func deleteEndpoint(input: DeleteEndpointInput) async throws -> DeleteEndpointOutput
    /// Performs the `DeleteEntityRecognizer` operation on the `Comprehend_20171127` service.
    ///
    /// Deletes an entity recognizer. Only those recognizers that are in terminated states (IN_ERROR, TRAINED) will be deleted. If an active inference job is using the model, a ResourceInUseException will be returned. This is an asynchronous action that puts the recognizer into a DELETING state, and it is then removed by a background job. Once removed, the recognizer disappears from your account and is no longer available for use.
    ///
    /// - Parameter DeleteEntityRecognizerInput : [no documentation found]
    ///
    /// - Returns: `DeleteEntityRecognizerOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func deleteEntityRecognizer(input: DeleteEntityRecognizerInput) async throws -> DeleteEntityRecognizerOutput
    /// Performs the `DeleteFlywheel` operation on the `Comprehend_20171127` service.
    ///
    /// Deletes a flywheel. When you delete the flywheel, Amazon Comprehend does not delete the data lake or the model associated with the flywheel. For more information about flywheels, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter DeleteFlywheelInput : [no documentation found]
    ///
    /// - Returns: `DeleteFlywheelOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func deleteFlywheel(input: DeleteFlywheelInput) async throws -> DeleteFlywheelOutput
    /// Performs the `DeleteResourcePolicy` operation on the `Comprehend_20171127` service.
    ///
    /// Deletes a resource-based policy that is attached to a custom model.
    ///
    /// - Parameter DeleteResourcePolicyInput : [no documentation found]
    ///
    /// - Returns: `DeleteResourcePolicyOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    func deleteResourcePolicy(input: DeleteResourcePolicyInput) async throws -> DeleteResourcePolicyOutput
    /// Performs the `DescribeDataset` operation on the `Comprehend_20171127` service.
    ///
    /// Returns information about the dataset that you specify. For more information about datasets, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter DescribeDatasetInput : [no documentation found]
    ///
    /// - Returns: `DescribeDatasetOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeDataset(input: DescribeDatasetInput) async throws -> DescribeDatasetOutput
    /// Performs the `DescribeDocumentClassificationJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a document classification job. Use this operation to get the status of a classification job.
    ///
    /// - Parameter DescribeDocumentClassificationJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeDocumentClassificationJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeDocumentClassificationJob(input: DescribeDocumentClassificationJobInput) async throws -> DescribeDocumentClassificationJobOutput
    /// Performs the `DescribeDocumentClassifier` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a document classifier.
    ///
    /// - Parameter DescribeDocumentClassifierInput : [no documentation found]
    ///
    /// - Returns: `DescribeDocumentClassifierOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeDocumentClassifier(input: DescribeDocumentClassifierInput) async throws -> DescribeDocumentClassifierOutput
    /// Performs the `DescribeDominantLanguageDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a dominant language detection job. Use this operation to get the status of a detection job.
    ///
    /// - Parameter DescribeDominantLanguageDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeDominantLanguageDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeDominantLanguageDetectionJob(input: DescribeDominantLanguageDetectionJobInput) async throws -> DescribeDominantLanguageDetectionJobOutput
    /// Performs the `DescribeEndpoint` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a specific endpoint. Use this operation to get the status of an endpoint. For information about endpoints, see [Managing endpoints](https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
    ///
    /// - Parameter DescribeEndpointInput : [no documentation found]
    ///
    /// - Returns: `DescribeEndpointOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeEndpoint(input: DescribeEndpointInput) async throws -> DescribeEndpointOutput
    /// Performs the `DescribeEntitiesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with an entities detection job. Use this operation to get the status of a detection job.
    ///
    /// - Parameter DescribeEntitiesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeEntitiesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeEntitiesDetectionJob(input: DescribeEntitiesDetectionJobInput) async throws -> DescribeEntitiesDetectionJobOutput
    /// Performs the `DescribeEntityRecognizer` operation on the `Comprehend_20171127` service.
    ///
    /// Provides details about an entity recognizer including status, S3 buckets containing training data, recognizer metadata, metrics, and so on.
    ///
    /// - Parameter DescribeEntityRecognizerInput : [no documentation found]
    ///
    /// - Returns: `DescribeEntityRecognizerOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeEntityRecognizer(input: DescribeEntityRecognizerInput) async throws -> DescribeEntityRecognizerOutput
    /// Performs the `DescribeEventsDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the status and details of an events detection job.
    ///
    /// - Parameter DescribeEventsDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeEventsDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeEventsDetectionJob(input: DescribeEventsDetectionJobInput) async throws -> DescribeEventsDetectionJobOutput
    /// Performs the `DescribeFlywheel` operation on the `Comprehend_20171127` service.
    ///
    /// Provides configuration information about the flywheel. For more information about flywheels, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter DescribeFlywheelInput : [no documentation found]
    ///
    /// - Returns: `DescribeFlywheelOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeFlywheel(input: DescribeFlywheelInput) async throws -> DescribeFlywheelOutput
    /// Performs the `DescribeFlywheelIteration` operation on the `Comprehend_20171127` service.
    ///
    /// Retrieve the configuration properties of a flywheel iteration. For more information about flywheels, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter DescribeFlywheelIterationInput : [no documentation found]
    ///
    /// - Returns: `DescribeFlywheelIterationOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeFlywheelIteration(input: DescribeFlywheelIterationInput) async throws -> DescribeFlywheelIterationOutput
    /// Performs the `DescribeKeyPhrasesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a key phrases detection job. Use this operation to get the status of a detection job.
    ///
    /// - Parameter DescribeKeyPhrasesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeKeyPhrasesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeKeyPhrasesDetectionJob(input: DescribeKeyPhrasesDetectionJobInput) async throws -> DescribeKeyPhrasesDetectionJobOutput
    /// Performs the `DescribePiiEntitiesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a PII entities detection job. For example, you can use this operation to get the job status.
    ///
    /// - Parameter DescribePiiEntitiesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribePiiEntitiesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describePiiEntitiesDetectionJob(input: DescribePiiEntitiesDetectionJobInput) async throws -> DescribePiiEntitiesDetectionJobOutput
    /// Performs the `DescribeResourcePolicy` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the details of a resource-based policy that is attached to a custom model, including the JSON body of the policy.
    ///
    /// - Parameter DescribeResourcePolicyInput : [no documentation found]
    ///
    /// - Returns: `DescribeResourcePolicyOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    func describeResourcePolicy(input: DescribeResourcePolicyInput) async throws -> DescribeResourcePolicyOutput
    /// Performs the `DescribeSentimentDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a sentiment detection job. Use this operation to get the status of a detection job.
    ///
    /// - Parameter DescribeSentimentDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeSentimentDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeSentimentDetectionJob(input: DescribeSentimentDetectionJobInput) async throws -> DescribeSentimentDetectionJobOutput
    /// Performs the `DescribeTargetedSentimentDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a targeted sentiment detection job. Use this operation to get the status of the job.
    ///
    /// - Parameter DescribeTargetedSentimentDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeTargetedSentimentDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeTargetedSentimentDetectionJob(input: DescribeTargetedSentimentDetectionJobInput) async throws -> DescribeTargetedSentimentDetectionJobOutput
    /// Performs the `DescribeTopicsDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Gets the properties associated with a topic detection job. Use this operation to get the status of a detection job.
    ///
    /// - Parameter DescribeTopicsDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `DescribeTopicsDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func describeTopicsDetectionJob(input: DescribeTopicsDetectionJobInput) async throws -> DescribeTopicsDetectionJobOutput
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
    /// Performs the `DetectKeyPhrases` operation on the `Comprehend_20171127` service.
    ///
    /// Detects the key noun phrases found in the text.
    ///
    /// - Parameter DetectKeyPhrasesInput : [no documentation found]
    ///
    /// - Returns: `DetectKeyPhrasesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectKeyPhrases(input: DetectKeyPhrasesInput) async throws -> DetectKeyPhrasesOutput
    /// Performs the `DetectPiiEntities` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects the input text for entities that contain personally identifiable information (PII) and returns information about them.
    ///
    /// - Parameter DetectPiiEntitiesInput : [no documentation found]
    ///
    /// - Returns: `DetectPiiEntitiesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectPiiEntities(input: DetectPiiEntitiesInput) async throws -> DetectPiiEntitiesOutput
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
    /// Performs the `DetectTargetedSentiment` operation on the `Comprehend_20171127` service.
    ///
    /// Inspects the input text and returns a sentiment analysis for each entity identified in the text. For more information about targeted sentiment, see [Targeted sentiment](https://docs.aws.amazon.com/comprehend/latest/dg/how-targeted-sentiment.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter DetectTargetedSentimentInput : [no documentation found]
    ///
    /// - Returns: `DetectTargetedSentimentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectTargetedSentiment(input: DetectTargetedSentimentInput) async throws -> DetectTargetedSentimentOutput
    /// Performs the `DetectToxicContent` operation on the `Comprehend_20171127` service.
    ///
    /// Performs toxicity analysis on the list of text strings that you provide as input. The API response contains a results list that matches the size of the input list. For more information about toxicity detection, see [Toxicity detection](https://docs.aws.amazon.com/comprehend/latest/dg/toxicity-detection.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter DetectToxicContentInput : [no documentation found]
    ///
    /// - Returns: `DetectToxicContentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TextSizeLimitExceededException` : The size of the input text exceeds the limit. Use a smaller document.
    /// - `UnsupportedLanguageException` : Amazon Comprehend can't process the language of the input text. For a list of supported languages, [Supported languages](https://docs.aws.amazon.com/comprehend/latest/dg/supported-languages.html) in the Comprehend Developer Guide.
    func detectToxicContent(input: DetectToxicContentInput) async throws -> DetectToxicContentOutput
    /// Performs the `ImportModel` operation on the `Comprehend_20171127` service.
    ///
    /// Creates a new custom model that replicates a source custom model that you import. The source model can be in your Amazon Web Services account or another one. If the source model is in another Amazon Web Services account, then it must have a resource-based policy that authorizes you to import it. The source model must be in the same Amazon Web Services Region that you're using when you import. You can't import a model that's in a different Region.
    ///
    /// - Parameter ImportModelInput : [no documentation found]
    ///
    /// - Returns: `ImportModelOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceLimitExceededException` : The maximum number of resources per account has been exceeded. Review the resources, and then try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func importModel(input: ImportModelInput) async throws -> ImportModelOutput
    /// Performs the `ListDatasets` operation on the `Comprehend_20171127` service.
    ///
    /// List the datasets that you have configured in this Region. For more information about datasets, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter ListDatasetsInput : [no documentation found]
    ///
    /// - Returns: `ListDatasetsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listDatasets(input: ListDatasetsInput) async throws -> ListDatasetsOutput
    /// Performs the `ListDocumentClassificationJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the documentation classification jobs that you have submitted.
    ///
    /// - Parameter ListDocumentClassificationJobsInput : [no documentation found]
    ///
    /// - Returns: `ListDocumentClassificationJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listDocumentClassificationJobs(input: ListDocumentClassificationJobsInput) async throws -> ListDocumentClassificationJobsOutput
    /// Performs the `ListDocumentClassifiers` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the document classifiers that you have created.
    ///
    /// - Parameter ListDocumentClassifiersInput : [no documentation found]
    ///
    /// - Returns: `ListDocumentClassifiersOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listDocumentClassifiers(input: ListDocumentClassifiersInput) async throws -> ListDocumentClassifiersOutput
    /// Performs the `ListDocumentClassifierSummaries` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of summaries of the document classifiers that you have created
    ///
    /// - Parameter ListDocumentClassifierSummariesInput : [no documentation found]
    ///
    /// - Returns: `ListDocumentClassifierSummariesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listDocumentClassifierSummaries(input: ListDocumentClassifierSummariesInput) async throws -> ListDocumentClassifierSummariesOutput
    /// Performs the `ListDominantLanguageDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the dominant language detection jobs that you have submitted.
    ///
    /// - Parameter ListDominantLanguageDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListDominantLanguageDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listDominantLanguageDetectionJobs(input: ListDominantLanguageDetectionJobsInput) async throws -> ListDominantLanguageDetectionJobsOutput
    /// Performs the `ListEndpoints` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of all existing endpoints that you've created. For information about endpoints, see [Managing endpoints](https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
    ///
    /// - Parameter ListEndpointsInput : [no documentation found]
    ///
    /// - Returns: `ListEndpointsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listEndpoints(input: ListEndpointsInput) async throws -> ListEndpointsOutput
    /// Performs the `ListEntitiesDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the entity detection jobs that you have submitted.
    ///
    /// - Parameter ListEntitiesDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListEntitiesDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listEntitiesDetectionJobs(input: ListEntitiesDetectionJobsInput) async throws -> ListEntitiesDetectionJobsOutput
    /// Performs the `ListEntityRecognizers` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the properties of all entity recognizers that you created, including recognizers currently in training. Allows you to filter the list of recognizers based on criteria such as status and submission time. This call returns up to 500 entity recognizers in the list, with a default number of 100 recognizers in the list. The results of this list are not in any particular order. Please get the list and sort locally if needed.
    ///
    /// - Parameter ListEntityRecognizersInput : [no documentation found]
    ///
    /// - Returns: `ListEntityRecognizersOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listEntityRecognizers(input: ListEntityRecognizersInput) async throws -> ListEntityRecognizersOutput
    /// Performs the `ListEntityRecognizerSummaries` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of summaries for the entity recognizers that you have created.
    ///
    /// - Parameter ListEntityRecognizerSummariesInput : [no documentation found]
    ///
    /// - Returns: `ListEntityRecognizerSummariesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listEntityRecognizerSummaries(input: ListEntityRecognizerSummariesInput) async throws -> ListEntityRecognizerSummariesOutput
    /// Performs the `ListEventsDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the events detection jobs that you have submitted.
    ///
    /// - Parameter ListEventsDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListEventsDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listEventsDetectionJobs(input: ListEventsDetectionJobsInput) async throws -> ListEventsDetectionJobsOutput
    /// Performs the `ListFlywheelIterationHistory` operation on the `Comprehend_20171127` service.
    ///
    /// Information about the history of a flywheel iteration. For more information about flywheels, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter ListFlywheelIterationHistoryInput : [no documentation found]
    ///
    /// - Returns: `ListFlywheelIterationHistoryOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listFlywheelIterationHistory(input: ListFlywheelIterationHistoryInput) async throws -> ListFlywheelIterationHistoryOutput
    /// Performs the `ListFlywheels` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the flywheels that you have created.
    ///
    /// - Parameter ListFlywheelsInput : [no documentation found]
    ///
    /// - Returns: `ListFlywheelsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listFlywheels(input: ListFlywheelsInput) async throws -> ListFlywheelsOutput
    /// Performs the `ListKeyPhrasesDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Get a list of key phrase detection jobs that you have submitted.
    ///
    /// - Parameter ListKeyPhrasesDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListKeyPhrasesDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listKeyPhrasesDetectionJobs(input: ListKeyPhrasesDetectionJobsInput) async throws -> ListKeyPhrasesDetectionJobsOutput
    /// Performs the `ListPiiEntitiesDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the PII entity detection jobs that you have submitted.
    ///
    /// - Parameter ListPiiEntitiesDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListPiiEntitiesDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listPiiEntitiesDetectionJobs(input: ListPiiEntitiesDetectionJobsInput) async throws -> ListPiiEntitiesDetectionJobsOutput
    /// Performs the `ListSentimentDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of sentiment detection jobs that you have submitted.
    ///
    /// - Parameter ListSentimentDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListSentimentDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listSentimentDetectionJobs(input: ListSentimentDetectionJobsInput) async throws -> ListSentimentDetectionJobsOutput
    /// Performs the `ListTagsForResource` operation on the `Comprehend_20171127` service.
    ///
    /// Lists all tags associated with a given Amazon Comprehend resource.
    ///
    /// - Parameter ListTagsForResourceInput : [no documentation found]
    ///
    /// - Returns: `ListTagsForResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    func listTagsForResource(input: ListTagsForResourceInput) async throws -> ListTagsForResourceOutput
    /// Performs the `ListTargetedSentimentDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of targeted sentiment detection jobs that you have submitted.
    ///
    /// - Parameter ListTargetedSentimentDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListTargetedSentimentDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listTargetedSentimentDetectionJobs(input: ListTargetedSentimentDetectionJobsInput) async throws -> ListTargetedSentimentDetectionJobsOutput
    /// Performs the `ListTopicsDetectionJobs` operation on the `Comprehend_20171127` service.
    ///
    /// Gets a list of the topic detection jobs that you have submitted.
    ///
    /// - Parameter ListTopicsDetectionJobsInput : [no documentation found]
    ///
    /// - Returns: `ListTopicsDetectionJobsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidFilterException` : The filter specified for the operation is invalid. Specify a different filter.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func listTopicsDetectionJobs(input: ListTopicsDetectionJobsInput) async throws -> ListTopicsDetectionJobsOutput
    /// Performs the `PutResourcePolicy` operation on the `Comprehend_20171127` service.
    ///
    /// Attaches a resource-based policy to a custom model. You can use this policy to authorize an entity in another Amazon Web Services account to import the custom model, which replicates it in Amazon Comprehend in their account.
    ///
    /// - Parameter PutResourcePolicyInput : [no documentation found]
    ///
    /// - Returns: `PutResourcePolicyOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    func putResourcePolicy(input: PutResourcePolicyInput) async throws -> PutResourcePolicyOutput
    /// Performs the `StartDocumentClassificationJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous document classification job using a custom classification model. Use the DescribeDocumentClassificationJob operation to track the progress of the job.
    ///
    /// - Parameter StartDocumentClassificationJobInput : [no documentation found]
    ///
    /// - Returns: `StartDocumentClassificationJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startDocumentClassificationJob(input: StartDocumentClassificationJobInput) async throws -> StartDocumentClassificationJobOutput
    /// Performs the `StartDominantLanguageDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous dominant language detection job for a collection of documents. Use the operation to track the status of a job.
    ///
    /// - Parameter StartDominantLanguageDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartDominantLanguageDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startDominantLanguageDetectionJob(input: StartDominantLanguageDetectionJobInput) async throws -> StartDominantLanguageDetectionJobOutput
    /// Performs the `StartEntitiesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous entity detection job for a collection of documents. Use the operation to track the status of a job. This API can be used for either standard entity detection or custom entity recognition. In order to be used for custom entity recognition, the optional EntityRecognizerArn must be used in order to provide access to the recognizer being used to detect the custom entity.
    ///
    /// - Parameter StartEntitiesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartEntitiesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startEntitiesDetectionJob(input: StartEntitiesDetectionJobInput) async throws -> StartEntitiesDetectionJobOutput
    /// Performs the `StartEventsDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous event detection job for a collection of documents.
    ///
    /// - Parameter StartEventsDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartEventsDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startEventsDetectionJob(input: StartEventsDetectionJobInput) async throws -> StartEventsDetectionJobOutput
    /// Performs the `StartFlywheelIteration` operation on the `Comprehend_20171127` service.
    ///
    /// Start the flywheel iteration.This operation uses any new datasets to train a new model version. For more information about flywheels, see [ Flywheel overview](https://docs.aws.amazon.com/comprehend/latest/dg/flywheels-about.html) in the Amazon Comprehend Developer Guide.
    ///
    /// - Parameter StartFlywheelIterationInput : [no documentation found]
    ///
    /// - Returns: `StartFlywheelIterationOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func startFlywheelIteration(input: StartFlywheelIterationInput) async throws -> StartFlywheelIterationOutput
    /// Performs the `StartKeyPhrasesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous key phrase detection job for a collection of documents. Use the operation to track the status of a job.
    ///
    /// - Parameter StartKeyPhrasesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartKeyPhrasesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startKeyPhrasesDetectionJob(input: StartKeyPhrasesDetectionJobInput) async throws -> StartKeyPhrasesDetectionJobOutput
    /// Performs the `StartPiiEntitiesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous PII entity detection job for a collection of documents.
    ///
    /// - Parameter StartPiiEntitiesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartPiiEntitiesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startPiiEntitiesDetectionJob(input: StartPiiEntitiesDetectionJobInput) async throws -> StartPiiEntitiesDetectionJobOutput
    /// Performs the `StartSentimentDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous sentiment detection job for a collection of documents. Use the operation to track the status of a job.
    ///
    /// - Parameter StartSentimentDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartSentimentDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startSentimentDetectionJob(input: StartSentimentDetectionJobInput) async throws -> StartSentimentDetectionJobOutput
    /// Performs the `StartTargetedSentimentDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous targeted sentiment detection job for a collection of documents. Use the DescribeTargetedSentimentDetectionJob operation to track the status of a job.
    ///
    /// - Parameter StartTargetedSentimentDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartTargetedSentimentDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startTargetedSentimentDetectionJob(input: StartTargetedSentimentDetectionJobInput) async throws -> StartTargetedSentimentDetectionJobOutput
    /// Performs the `StartTopicsDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Starts an asynchronous topic detection job. Use the DescribeTopicDetectionJob operation to track the status of a job.
    ///
    /// - Parameter StartTopicsDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StartTopicsDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func startTopicsDetectionJob(input: StartTopicsDetectionJobInput) async throws -> StartTopicsDetectionJobOutput
    /// Performs the `StopDominantLanguageDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Stops a dominant language detection job in progress. If the job state is IN_PROGRESS the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
    ///
    /// - Parameter StopDominantLanguageDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StopDominantLanguageDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    func stopDominantLanguageDetectionJob(input: StopDominantLanguageDetectionJobInput) async throws -> StopDominantLanguageDetectionJobOutput
    /// Performs the `StopEntitiesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Stops an entities detection job in progress. If the job state is IN_PROGRESS the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
    ///
    /// - Parameter StopEntitiesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StopEntitiesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    func stopEntitiesDetectionJob(input: StopEntitiesDetectionJobInput) async throws -> StopEntitiesDetectionJobOutput
    /// Performs the `StopEventsDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Stops an events detection job in progress.
    ///
    /// - Parameter StopEventsDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StopEventsDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    func stopEventsDetectionJob(input: StopEventsDetectionJobInput) async throws -> StopEventsDetectionJobOutput
    /// Performs the `StopKeyPhrasesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Stops a key phrases detection job in progress. If the job state is IN_PROGRESS the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
    ///
    /// - Parameter StopKeyPhrasesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StopKeyPhrasesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    func stopKeyPhrasesDetectionJob(input: StopKeyPhrasesDetectionJobInput) async throws -> StopKeyPhrasesDetectionJobOutput
    /// Performs the `StopPiiEntitiesDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Stops a PII entities detection job in progress.
    ///
    /// - Parameter StopPiiEntitiesDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StopPiiEntitiesDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    func stopPiiEntitiesDetectionJob(input: StopPiiEntitiesDetectionJobInput) async throws -> StopPiiEntitiesDetectionJobOutput
    /// Performs the `StopSentimentDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Stops a sentiment detection job in progress. If the job state is IN_PROGRESS, the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is be stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
    ///
    /// - Parameter StopSentimentDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StopSentimentDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    func stopSentimentDetectionJob(input: StopSentimentDetectionJobInput) async throws -> StopSentimentDetectionJobOutput
    /// Performs the `StopTargetedSentimentDetectionJob` operation on the `Comprehend_20171127` service.
    ///
    /// Stops a targeted sentiment detection job in progress. If the job state is IN_PROGRESS, the job is marked for termination and put into the STOP_REQUESTED state. If the job completes before it can be stopped, it is put into the COMPLETED state; otherwise the job is be stopped and put into the STOPPED state. If the job is in the COMPLETED or FAILED state when you call the StopDominantLanguageDetectionJob operation, the operation returns a 400 Internal Request Exception. When a job is stopped, any documents already processed are written to the output location.
    ///
    /// - Parameter StopTargetedSentimentDetectionJobInput : [no documentation found]
    ///
    /// - Returns: `StopTargetedSentimentDetectionJobOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `JobNotFoundException` : The specified job was not found. Check the job ID and try again.
    func stopTargetedSentimentDetectionJob(input: StopTargetedSentimentDetectionJobInput) async throws -> StopTargetedSentimentDetectionJobOutput
    /// Performs the `StopTrainingDocumentClassifier` operation on the `Comprehend_20171127` service.
    ///
    /// Stops a document classifier training job while in progress. If the training job state is TRAINING, the job is marked for termination and put into the STOP_REQUESTED state. If the training job completes before it can be stopped, it is put into the TRAINED; otherwise the training job is stopped and put into the STOPPED state and the service sends back an HTTP 200 response with an empty HTTP body.
    ///
    /// - Parameter StopTrainingDocumentClassifierInput : [no documentation found]
    ///
    /// - Returns: `StopTrainingDocumentClassifierOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func stopTrainingDocumentClassifier(input: StopTrainingDocumentClassifierInput) async throws -> StopTrainingDocumentClassifierOutput
    /// Performs the `StopTrainingEntityRecognizer` operation on the `Comprehend_20171127` service.
    ///
    /// Stops an entity recognizer training job while in progress. If the training job state is TRAINING, the job is marked for termination and put into the STOP_REQUESTED state. If the training job completes before it can be stopped, it is put into the TRAINED; otherwise the training job is stopped and putted into the STOPPED state and the service sends back an HTTP 200 response with an empty HTTP body.
    ///
    /// - Parameter StopTrainingEntityRecognizerInput : [no documentation found]
    ///
    /// - Returns: `StopTrainingEntityRecognizerOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func stopTrainingEntityRecognizer(input: StopTrainingEntityRecognizerInput) async throws -> StopTrainingEntityRecognizerOutput
    /// Performs the `TagResource` operation on the `Comprehend_20171127` service.
    ///
    /// Associates a specific tag with an Amazon Comprehend resource. A tag is a key-value pair that adds as a metadata to a resource used by Amazon Comprehend. For example, a tag with "Sales" as the key might be added to a resource to indicate its use by the sales department.
    ///
    /// - Parameter TagResourceInput : [no documentation found]
    ///
    /// - Returns: `TagResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Concurrent modification of the tags associated with an Amazon Comprehend resource is not supported.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyTagsException` : The request contains more tags than can be associated with a resource (50 tags per resource). The maximum number of tags includes both existing tags and those included in your current request.
    func tagResource(input: TagResourceInput) async throws -> TagResourceOutput
    /// Performs the `UntagResource` operation on the `Comprehend_20171127` service.
    ///
    /// Removes a specific tag associated with an Amazon Comprehend resource.
    ///
    /// - Parameter UntagResourceInput : [no documentation found]
    ///
    /// - Returns: `UntagResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `ConcurrentModificationException` : Concurrent modification of the tags associated with an Amazon Comprehend resource is not supported.
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyTagKeysException` : The request contains more tag keys than can be associated with a resource (50 tag keys per resource).
    func untagResource(input: UntagResourceInput) async throws -> UntagResourceOutput
    /// Performs the `UpdateEndpoint` operation on the `Comprehend_20171127` service.
    ///
    /// Updates information about the specified endpoint. For information about endpoints, see [Managing endpoints](https://docs.aws.amazon.com/comprehend/latest/dg/manage-endpoints.html).
    ///
    /// - Parameter UpdateEndpointInput : [no documentation found]
    ///
    /// - Returns: `UpdateEndpointOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `ResourceInUseException` : The specified resource name is already in use. Use a different name and try your request again.
    /// - `ResourceLimitExceededException` : The maximum number of resources per account has been exceeded. Review the resources, and then try your request again.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `ResourceUnavailableException` : The specified resource is not available. Check the resource and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func updateEndpoint(input: UpdateEndpointInput) async throws -> UpdateEndpointOutput
    /// Performs the `UpdateFlywheel` operation on the `Comprehend_20171127` service.
    ///
    /// Update the configuration information for an existing flywheel.
    ///
    /// - Parameter UpdateFlywheelInput : [no documentation found]
    ///
    /// - Returns: `UpdateFlywheelOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `InternalServerException` : An internal server error occurred. Retry your request.
    /// - `InvalidRequestException` : The request is invalid.
    /// - `KmsKeyValidationException` : The KMS customer managed key (CMK) entered cannot be validated. Verify the key and re-enter it.
    /// - `ResourceNotFoundException` : The specified resource ARN was not found. Check the ARN and try your request again.
    /// - `TooManyRequestsException` : The number of requests exceeds the limit. Resubmit your request later.
    func updateFlywheel(input: UpdateFlywheelInput) async throws -> UpdateFlywheelOutput
}
extension ComprehendClient: ComprehendClientProtocol { }
