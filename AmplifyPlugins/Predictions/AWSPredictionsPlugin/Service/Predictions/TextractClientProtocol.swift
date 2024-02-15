//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTextract

public protocol TextractClientProtocol {
    
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
}

extension TextractClient: TextractClientProtocol { }
