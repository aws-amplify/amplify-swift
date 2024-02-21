//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract

// swiftlint:disable file_length
public protocol TextractClientProtocol {
    /// Performs the `AnalyzeDocument` operation on the `Textract` service.
    ///
    /// Analyzes an input document for relationships between detected items. The types of information returned are as follows:
    ///
    /// * Form data (key-value pairs). The related information is returned in two [Block] objects, each of type KEY_VALUE_SET: a KEY Block object and a VALUE Block object. For example, Name: Ana Silva Carolina contains a key and value. Name: is the key. Ana Silva Carolina is the value.
    ///
    /// * Table and table cell data. A TABLE Block object contains information about a detected table. A CELL Block object is returned for each cell in a table.
    ///
    /// * Lines and words of text. A LINE Block object contains one or more WORD Block objects. All lines and words that are detected in the document are returned (including text that doesn't have a relationship with the value of FeatureTypes).
    ///
    /// * Signatures. A SIGNATURE Block object contains the location information of a signature in a document. If used in conjunction with forms or tables, a signature can be given a Key-Value pairing or be detected in the cell of a table.
    ///
    /// * Query. A QUERY Block object contains the query text, alias and link to the associated Query results block object.
    ///
    /// * Query Result. A QUERY_RESULT Block object contains the answer to the query and an ID that connects it to the query asked. This Block also contains a confidence score.
    ///
    ///
    /// Selection elements such as check boxes and option buttons (radio buttons) can be detected in form data and in tables. A SELECTION_ELEMENT Block object contains information about a selection element, including the selection status. You can choose which type of analysis to perform by specifying the FeatureTypes list. The output is returned in a list of Block objects. AnalyzeDocument is a synchronous operation. To analyze documents asynchronously, use [StartDocumentAnalysis]. For more information, see [Document Text Analysis](https://docs.aws.amazon.com/textract/latest/dg/how-it-works-analyzing.html).
    ///
    /// - Parameter AnalyzeDocumentInput : [no documentation found]
    ///
    /// - Returns: `AnalyzeDocumentOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `HumanLoopQuotaExceededException` : Indicates you have exceeded the maximum number of active human in the loop workflows available
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func analyzeDocument(input: AnalyzeDocumentInput) async throws -> AnalyzeDocumentOutput
    /// Performs the `AnalyzeExpense` operation on the `Textract` service.
    ///
    /// AnalyzeExpense synchronously analyzes an input document for financially related relationships between text. Information is returned as ExpenseDocuments and seperated as follows:
    ///
    /// * LineItemGroups- A data set containing LineItems which store information about the lines of text, such as an item purchased and its price on a receipt.
    ///
    /// * SummaryFields- Contains all other information a receipt, such as header information or the vendors name.
    ///
    /// - Parameter AnalyzeExpenseInput : [no documentation found]
    ///
    /// - Returns: `AnalyzeExpenseOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func analyzeExpense(input: AnalyzeExpenseInput) async throws -> AnalyzeExpenseOutput
    /// Performs the `AnalyzeID` operation on the `Textract` service.
    ///
    /// Analyzes identity documents for relevant information. This information is extracted and returned as IdentityDocumentFields, which records both the normalized field and value of the extracted text. Unlike other Amazon Textract operations, AnalyzeID doesn't return any Geometry data.
    ///
    /// - Parameter AnalyzeIDInput : [no documentation found]
    ///
    /// - Returns: `AnalyzeIDOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func analyzeID(input: AnalyzeIDInput) async throws -> AnalyzeIDOutput
    /// Performs the `CreateAdapter` operation on the `Textract` service.
    ///
    /// Creates an adapter, which can be fine-tuned for enhanced performance on user provided documents. Takes an AdapterName and FeatureType. Currently the only supported feature type is QUERIES. You can also provide a Description, Tags, and a ClientRequestToken. You can choose whether or not the adapter should be AutoUpdated with the AutoUpdate argument. By default, AutoUpdate is set to DISABLED.
    ///
    /// - Parameter CreateAdapterInput : [no documentation found]
    ///
    /// - Returns: `CreateAdapterOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `ConflictException` : Updating or deleting a resource can cause an inconsistent state.
    /// - `IdempotentParameterMismatchException` : A ClientRequestToken input parameter was reused with an operation, but at least one of the other input parameters is different from the previous call to the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `LimitExceededException` : An Amazon Textract service limit was exceeded. For example, if you start too many asynchronous jobs concurrently, calls to start operations (StartDocumentTextDetection, for example) raise a LimitExceededException exception (HTTP status code: 400) until the number of concurrently running jobs is below the Amazon Textract service limit.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ServiceQuotaExceededException` : Returned when a request cannot be completed as it would exceed a maximum service quota.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func createAdapter(input: CreateAdapterInput) async throws -> CreateAdapterOutput
    /// Performs the `CreateAdapterVersion` operation on the `Textract` service.
    ///
    /// Creates a new version of an adapter. Operates on a provided AdapterId and a specified dataset provided via the DatasetConfig argument. Requires that you specify an Amazon S3 bucket with the OutputConfig argument. You can provide an optional KMSKeyId, an optional ClientRequestToken, and optional tags.
    ///
    /// - Parameter CreateAdapterVersionInput : [no documentation found]
    ///
    /// - Returns: `CreateAdapterVersionOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `ConflictException` : Updating or deleting a resource can cause an inconsistent state.
    /// - `IdempotentParameterMismatchException` : A ClientRequestToken input parameter was reused with an operation, but at least one of the other input parameters is different from the previous call to the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `LimitExceededException` : An Amazon Textract service limit was exceeded. For example, if you start too many asynchronous jobs concurrently, calls to start operations (StartDocumentTextDetection, for example) raise a LimitExceededException exception (HTTP status code: 400) until the number of concurrently running jobs is below the Amazon Textract service limit.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ServiceQuotaExceededException` : Returned when a request cannot be completed as it would exceed a maximum service quota.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func createAdapterVersion(input: CreateAdapterVersionInput) async throws -> CreateAdapterVersionOutput
    /// Performs the `DeleteAdapter` operation on the `Textract` service.
    ///
    /// Deletes an Amazon Textract adapter. Takes an AdapterId and deletes the adapter specified by the ID.
    ///
    /// - Parameter DeleteAdapterInput : [no documentation found]
    ///
    /// - Returns: `DeleteAdapterOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `ConflictException` : Updating or deleting a resource can cause an inconsistent state.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func deleteAdapter(input: DeleteAdapterInput) async throws -> DeleteAdapterOutput
    /// Performs the `DeleteAdapterVersion` operation on the `Textract` service.
    ///
    /// Deletes an Amazon Textract adapter version. Requires that you specify both an AdapterId and a AdapterVersion. Deletes the adapter version specified by the AdapterId and the AdapterVersion.
    ///
    /// - Parameter DeleteAdapterVersionInput : [no documentation found]
    ///
    /// - Returns: `DeleteAdapterVersionOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `ConflictException` : Updating or deleting a resource can cause an inconsistent state.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func deleteAdapterVersion(input: DeleteAdapterVersionInput) async throws -> DeleteAdapterVersionOutput
    /// Performs the `DetectDocumentText` operation on the `Textract` service.
    ///
    /// Detects text in the input document. Amazon Textract can detect lines of text and the words that make up a line of text. The input document must be in one of the following image formats: JPEG, PNG, PDF, or TIFF. DetectDocumentText returns the detected text in an array of [Block] objects. Each document page has as an associated Block of type PAGE. Each PAGE Block object is the parent of LINE Block objects that represent the lines of detected text on a page. A LINE Block object is a parent for each word that makes up the line. Words are represented by Block objects of type WORD. DetectDocumentText is a synchronous operation. To analyze documents asynchronously, use [StartDocumentTextDetection]. For more information, see [Document Text Detection](https://docs.aws.amazon.com/textract/latest/dg/how-it-works-detecting.html).
    ///
    /// - Parameter DetectDocumentTextInput : [no documentation found]
    ///
    /// - Returns: `DetectDocumentTextOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func detectDocumentText(input: DetectDocumentTextInput) async throws -> DetectDocumentTextOutput
    /// Performs the `GetAdapter` operation on the `Textract` service.
    ///
    /// Gets configuration information for an adapter specified by an AdapterId, returning information on AdapterName, Description, CreationTime, AutoUpdate status, and FeatureTypes.
    ///
    /// - Parameter GetAdapterInput : [no documentation found]
    ///
    /// - Returns: `GetAdapterOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func getAdapter(input: GetAdapterInput) async throws -> GetAdapterOutput
    /// Performs the `GetAdapterVersion` operation on the `Textract` service.
    ///
    /// Gets configuration information for the specified adapter version, including: AdapterId, AdapterVersion, FeatureTypes, Status, StatusMessage, DatasetConfig, KMSKeyId, OutputConfig, Tags and EvaluationMetrics.
    ///
    /// - Parameter GetAdapterVersionInput : [no documentation found]
    ///
    /// - Returns: `GetAdapterVersionOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func getAdapterVersion(input: GetAdapterVersionInput) async throws -> GetAdapterVersionOutput
    /// Performs the `GetDocumentAnalysis` operation on the `Textract` service.
    ///
    /// Gets the results for an Amazon Textract asynchronous operation that analyzes text in a document. You start asynchronous text analysis by calling [StartDocumentAnalysis], which returns a job identifier (JobId). When the text analysis operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartDocumentAnalysis. To get the results of the text-detection operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetDocumentAnalysis, and pass the job identifier (JobId) from the initial call to StartDocumentAnalysis. GetDocumentAnalysis returns an array of [Block] objects. The following types of information are returned:
    ///
    /// * Form data (key-value pairs). The related information is returned in two [Block] objects, each of type KEY_VALUE_SET: a KEY Block object and a VALUE Block object. For example, Name: Ana Silva Carolina contains a key and value. Name: is the key. Ana Silva Carolina is the value.
    ///
    /// * Table and table cell data. A TABLE Block object contains information about a detected table. A CELL Block object is returned for each cell in a table.
    ///
    /// * Lines and words of text. A LINE Block object contains one or more WORD Block objects. All lines and words that are detected in the document are returned (including text that doesn't have a relationship with the value of the StartDocumentAnalysisFeatureTypes input parameter).
    ///
    /// * Query. A QUERY Block object contains the query text, alias and link to the associated Query results block object.
    ///
    /// * Query Results. A QUERY_RESULT Block object contains the answer to the query and an ID that connects it to the query asked. This Block also contains a confidence score.
    ///
    ///
    /// While processing a document with queries, look out for INVALID_REQUEST_PARAMETERS output. This indicates that either the per page query limit has been exceeded or that the operation is trying to query a page in the document which doesn’t exist. Selection elements such as check boxes and option buttons (radio buttons) can be detected in form data and in tables. A SELECTION_ELEMENT Block object contains information about a selection element, including the selection status. Use the MaxResults parameter to limit the number of blocks that are returned. If there are more results than specified in MaxResults, the value of NextToken in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call GetDocumentAnalysis, and populate the NextToken request parameter with the token value that's returned from the previous call to GetDocumentAnalysis. For more information, see [Document Text Analysis](https://docs.aws.amazon.com/textract/latest/dg/how-it-works-analyzing.html).
    ///
    /// - Parameter GetDocumentAnalysisInput : [no documentation found]
    ///
    /// - Returns: `GetDocumentAnalysisOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidJobIdException` : An invalid job identifier was passed to an asynchronous analysis operation.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    func getDocumentAnalysis(input: GetDocumentAnalysisInput) async throws -> GetDocumentAnalysisOutput
    /// Performs the `GetDocumentTextDetection` operation on the `Textract` service.
    ///
    /// Gets the results for an Amazon Textract asynchronous operation that detects text in a document. Amazon Textract can detect lines of text and the words that make up a line of text. You start asynchronous text detection by calling [StartDocumentTextDetection], which returns a job identifier (JobId). When the text detection operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartDocumentTextDetection. To get the results of the text-detection operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetDocumentTextDetection, and pass the job identifier (JobId) from the initial call to StartDocumentTextDetection. GetDocumentTextDetection returns an array of [Block] objects. Each document page has as an associated Block of type PAGE. Each PAGE Block object is the parent of LINE Block objects that represent the lines of detected text on a page. A LINE Block object is a parent for each word that makes up the line. Words are represented by Block objects of type WORD. Use the MaxResults parameter to limit the number of blocks that are returned. If there are more results than specified in MaxResults, the value of NextToken in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call GetDocumentTextDetection, and populate the NextToken request parameter with the token value that's returned from the previous call to GetDocumentTextDetection. For more information, see [Document Text Detection](https://docs.aws.amazon.com/textract/latest/dg/how-it-works-detecting.html).
    ///
    /// - Parameter GetDocumentTextDetectionInput : [no documentation found]
    ///
    /// - Returns: `GetDocumentTextDetectionOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidJobIdException` : An invalid job identifier was passed to an asynchronous analysis operation.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    func getDocumentTextDetection(input: GetDocumentTextDetectionInput) async throws -> GetDocumentTextDetectionOutput
    /// Performs the `GetExpenseAnalysis` operation on the `Textract` service.
    ///
    /// Gets the results for an Amazon Textract asynchronous operation that analyzes invoices and receipts. Amazon Textract finds contact information, items purchased, and vendor name, from input invoices and receipts. You start asynchronous invoice/receipt analysis by calling [StartExpenseAnalysis], which returns a job identifier (JobId). Upon completion of the invoice/receipt analysis, Amazon Textract publishes the completion status to the Amazon Simple Notification Service (Amazon SNS) topic. This topic must be registered in the initial call to StartExpenseAnalysis. To get the results of the invoice/receipt analysis operation, first ensure that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetExpenseAnalysis, and pass the job identifier (JobId) from the initial call to StartExpenseAnalysis. Use the MaxResults parameter to limit the number of blocks that are returned. If there are more results than specified in MaxResults, the value of NextToken in the operation response contains a pagination token for getting the next set of results. To get the next page of results, call GetExpenseAnalysis, and populate the NextToken request parameter with the token value that's returned from the previous call to GetExpenseAnalysis. For more information, see [Analyzing Invoices and Receipts](https://docs.aws.amazon.com/textract/latest/dg/invoices-receipts.html).
    ///
    /// - Parameter GetExpenseAnalysisInput : [no documentation found]
    ///
    /// - Returns: `GetExpenseAnalysisOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidJobIdException` : An invalid job identifier was passed to an asynchronous analysis operation.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    func getExpenseAnalysis(input: GetExpenseAnalysisInput) async throws -> GetExpenseAnalysisOutput
    /// Performs the `GetLendingAnalysis` operation on the `Textract` service.
    ///
    /// Gets the results for an Amazon Textract asynchronous operation that analyzes text in a lending document. You start asynchronous text analysis by calling StartLendingAnalysis, which returns a job identifier (JobId). When the text analysis operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartLendingAnalysis. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetLendingAnalysis, and pass the job identifier (JobId) from the initial call to StartLendingAnalysis.
    ///
    /// - Parameter GetLendingAnalysisInput : [no documentation found]
    ///
    /// - Returns: `GetLendingAnalysisOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidJobIdException` : An invalid job identifier was passed to an asynchronous analysis operation.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    func getLendingAnalysis(input: GetLendingAnalysisInput) async throws -> GetLendingAnalysisOutput
    /// Performs the `GetLendingAnalysisSummary` operation on the `Textract` service.
    ///
    /// Gets summarized results for the StartLendingAnalysis operation, which analyzes text in a lending document. The returned summary consists of information about documents grouped together by a common document type. Information like detected signatures, page numbers, and split documents is returned with respect to the type of grouped document. You start asynchronous text analysis by calling StartLendingAnalysis, which returns a job identifier (JobId). When the text analysis operation finishes, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that's registered in the initial call to StartLendingAnalysis. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call GetLendingAnalysisSummary, and pass the job identifier (JobId) from the initial call to StartLendingAnalysis.
    ///
    /// - Parameter GetLendingAnalysisSummaryInput : [no documentation found]
    ///
    /// - Returns: `GetLendingAnalysisSummaryOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidJobIdException` : An invalid job identifier was passed to an asynchronous analysis operation.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    func getLendingAnalysisSummary(input: GetLendingAnalysisSummaryInput) async throws -> GetLendingAnalysisSummaryOutput
    /// Performs the `ListAdapters` operation on the `Textract` service.
    ///
    /// Lists all adapters that match the specified filtration criteria.
    ///
    /// - Parameter ListAdaptersInput : [no documentation found]
    ///
    /// - Returns: `ListAdaptersOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func listAdapters(input: ListAdaptersInput) async throws -> ListAdaptersOutput
    /// Performs the `ListAdapterVersions` operation on the `Textract` service.
    ///
    /// List all version of an adapter that meet the specified filtration criteria.
    ///
    /// - Parameter ListAdapterVersionsInput : [no documentation found]
    ///
    /// - Returns: `ListAdapterVersionsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func listAdapterVersions(input: ListAdapterVersionsInput) async throws -> ListAdapterVersionsOutput
    /// Performs the `ListTagsForResource` operation on the `Textract` service.
    ///
    /// Lists all tags for an Amazon Textract resource.
    ///
    /// - Parameter ListTagsForResourceInput : [no documentation found]
    ///
    /// - Returns: `ListTagsForResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func listTagsForResource(input: ListTagsForResourceInput) async throws -> ListTagsForResourceOutput
    /// Performs the `StartDocumentAnalysis` operation on the `Textract` service.
    ///
    /// Starts the asynchronous analysis of an input document for relationships between detected items such as key-value pairs, tables, and selection elements. StartDocumentAnalysis can analyze text in documents that are in JPEG, PNG, TIFF, and PDF format. The documents are stored in an Amazon S3 bucket. Use [DocumentLocation] to specify the bucket name and file name of the document. StartDocumentAnalysis returns a job identifier (JobId) that you use to get the results of the operation. When text analysis is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you specify in NotificationChannel. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call [GetDocumentAnalysis], and pass the job identifier (JobId) from the initial call to StartDocumentAnalysis. For more information, see [Document Text Analysis](https://docs.aws.amazon.com/textract/latest/dg/how-it-works-analyzing.html).
    ///
    /// - Parameter StartDocumentAnalysisInput : [no documentation found]
    ///
    /// - Returns: `StartDocumentAnalysisOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `IdempotentParameterMismatchException` : A ClientRequestToken input parameter was reused with an operation, but at least one of the other input parameters is different from the previous call to the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `LimitExceededException` : An Amazon Textract service limit was exceeded. For example, if you start too many asynchronous jobs concurrently, calls to start operations (StartDocumentTextDetection, for example) raise a LimitExceededException exception (HTTP status code: 400) until the number of concurrently running jobs is below the Amazon Textract service limit.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func startDocumentAnalysis(input: StartDocumentAnalysisInput) async throws -> StartDocumentAnalysisOutput
    /// Performs the `StartDocumentTextDetection` operation on the `Textract` service.
    ///
    /// Starts the asynchronous detection of text in a document. Amazon Textract can detect lines of text and the words that make up a line of text. StartDocumentTextDetection can analyze text in documents that are in JPEG, PNG, TIFF, and PDF format. The documents are stored in an Amazon S3 bucket. Use [DocumentLocation] to specify the bucket name and file name of the document. StartTextDetection returns a job identifier (JobId) that you use to get the results of the operation. When text detection is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you specify in NotificationChannel. To get the results of the text detection operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call [GetDocumentTextDetection], and pass the job identifier (JobId) from the initial call to StartDocumentTextDetection. For more information, see [Document Text Detection](https://docs.aws.amazon.com/textract/latest/dg/how-it-works-detecting.html).
    ///
    /// - Parameter StartDocumentTextDetectionInput : [no documentation found]
    ///
    /// - Returns: `StartDocumentTextDetectionOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `IdempotentParameterMismatchException` : A ClientRequestToken input parameter was reused with an operation, but at least one of the other input parameters is different from the previous call to the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `LimitExceededException` : An Amazon Textract service limit was exceeded. For example, if you start too many asynchronous jobs concurrently, calls to start operations (StartDocumentTextDetection, for example) raise a LimitExceededException exception (HTTP status code: 400) until the number of concurrently running jobs is below the Amazon Textract service limit.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func startDocumentTextDetection(input: StartDocumentTextDetectionInput) async throws -> StartDocumentTextDetectionOutput
    /// Performs the `StartExpenseAnalysis` operation on the `Textract` service.
    ///
    /// Starts the asynchronous analysis of invoices or receipts for data like contact information, items purchased, and vendor names. StartExpenseAnalysis can analyze text in documents that are in JPEG, PNG, and PDF format. The documents must be stored in an Amazon S3 bucket. Use the [DocumentLocation] parameter to specify the name of your S3 bucket and the name of the document in that bucket. StartExpenseAnalysis returns a job identifier (JobId) that you will provide to GetExpenseAnalysis to retrieve the results of the operation. When the analysis of the input invoices/receipts is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you provide to the NotificationChannel. To obtain the results of the invoice and receipt analysis operation, ensure that the status value published to the Amazon SNS topic is SUCCEEDED. If so, call [GetExpenseAnalysis], and pass the job identifier (JobId) that was returned by your call to StartExpenseAnalysis. For more information, see [Analyzing Invoices and Receipts](https://docs.aws.amazon.com/textract/latest/dg/invoice-receipts.html).
    ///
    /// - Parameter StartExpenseAnalysisInput : [no documentation found]
    ///
    /// - Returns: `StartExpenseAnalysisOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `IdempotentParameterMismatchException` : A ClientRequestToken input parameter was reused with an operation, but at least one of the other input parameters is different from the previous call to the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `LimitExceededException` : An Amazon Textract service limit was exceeded. For example, if you start too many asynchronous jobs concurrently, calls to start operations (StartDocumentTextDetection, for example) raise a LimitExceededException exception (HTTP status code: 400) until the number of concurrently running jobs is below the Amazon Textract service limit.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func startExpenseAnalysis(input: StartExpenseAnalysisInput) async throws -> StartExpenseAnalysisOutput
    /// Performs the `StartLendingAnalysis` operation on the `Textract` service.
    ///
    /// Starts the classification and analysis of an input document. StartLendingAnalysis initiates the classification and analysis of a packet of lending documents. StartLendingAnalysis operates on a document file located in an Amazon S3 bucket. StartLendingAnalysis can analyze text in documents that are in one of the following formats: JPEG, PNG, TIFF, PDF. Use DocumentLocation to specify the bucket name and the file name of the document. StartLendingAnalysis returns a job identifier (JobId) that you use to get the results of the operation. When the text analysis is finished, Amazon Textract publishes a completion status to the Amazon Simple Notification Service (Amazon SNS) topic that you specify in NotificationChannel. To get the results of the text analysis operation, first check that the status value published to the Amazon SNS topic is SUCCEEDED. If the status is SUCCEEDED you can call either GetLendingAnalysis or GetLendingAnalysisSummary and provide the JobId to obtain the results of the analysis. If using OutputConfig to specify an Amazon S3 bucket, the output will be contained within the specified prefix in a directory labeled with the job-id. In the directory there are 3 sub-directories:
    ///
    /// * detailedResponse (contains the GetLendingAnalysis response)
    ///
    /// * summaryResponse (for the GetLendingAnalysisSummary response)
    ///
    /// * splitDocuments (documents split across logical boundaries)
    ///
    /// - Parameter StartLendingAnalysisInput : [no documentation found]
    ///
    /// - Returns: `StartLendingAnalysisOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `BadDocumentException` : Amazon Textract isn't able to read the document. For more information on the document limits in Amazon Textract, see [limits].
    /// - `DocumentTooLargeException` : The document can't be processed because it's too large. The maximum document size for synchronous operations 10 MB. The maximum document size for asynchronous operations is 500 MB for PDF files.
    /// - `IdempotentParameterMismatchException` : A ClientRequestToken input parameter was reused with an operation, but at least one of the other input parameters is different from the previous call to the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidKMSKeyException` : Indicates you do not have decrypt permissions with the KMS key entered, or the KMS key was entered incorrectly.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Textract is unable to access the S3 object that's specified in the request. for more information, [Configure Access to Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/s3-access-control.html) For troubleshooting information, see [Troubleshooting Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/troubleshooting.html)
    /// - `LimitExceededException` : An Amazon Textract service limit was exceeded. For example, if you start too many asynchronous jobs concurrently, calls to start operations (StartDocumentTextDetection, for example) raise a LimitExceededException exception (HTTP status code: 400) until the number of concurrently running jobs is below the Amazon Textract service limit.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `UnsupportedDocumentException` : The format of the input document isn't supported. Documents for operations can be in PNG, JPEG, PDF, or TIFF format.
    func startLendingAnalysis(input: StartLendingAnalysisInput) async throws -> StartLendingAnalysisOutput
    /// Performs the `TagResource` operation on the `Textract` service.
    ///
    /// Adds one or more tags to the specified resource.
    ///
    /// - Parameter TagResourceInput : [no documentation found]
    ///
    /// - Returns: `TagResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ServiceQuotaExceededException` : Returned when a request cannot be completed as it would exceed a maximum service quota.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func tagResource(input: TagResourceInput) async throws -> TagResourceOutput
    /// Performs the `UntagResource` operation on the `Textract` service.
    ///
    /// Removes any tags with the specified keys from the specified resource.
    ///
    /// - Parameter UntagResourceInput : [no documentation found]
    ///
    /// - Returns: `UntagResourceOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func untagResource(input: UntagResourceInput) async throws -> UntagResourceOutput
    /// Performs the `UpdateAdapter` operation on the `Textract` service.
    ///
    /// Update the configuration for an adapter. FeatureTypes configurations cannot be updated. At least one new parameter must be specified as an argument.
    ///
    /// - Parameter UpdateAdapterInput : [no documentation found]
    ///
    /// - Returns: `UpdateAdapterOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You aren't authorized to perform the action. Use the Amazon Resource Name (ARN) of an authorized user or IAM role to perform the operation.
    /// - `ConflictException` : Updating or deleting a resource can cause an inconsistent state.
    /// - `InternalServerError` : Amazon Textract experienced a service issue. Try your call again.
    /// - `InvalidParameterException` : An input parameter violated a constraint. For example, in synchronous operations, an InvalidParameterException exception occurs when neither of the S3Object or Bytes values are supplied in the Document request parameter. Validate your parameter before calling the API operation again.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Textract.
    /// - `ResourceNotFoundException` : Returned when an operation tried to access a nonexistent resource.
    /// - `ThrottlingException` : Amazon Textract is temporarily unable to process the request. Try your call again.
    /// - `ValidationException` : Indicates that a request was not valid. Check request for proper formatting.
    func updateAdapter(input: UpdateAdapterInput) async throws -> UpdateAdapterOutput
}
extension TextractClient: TextractClientProtocol { }
