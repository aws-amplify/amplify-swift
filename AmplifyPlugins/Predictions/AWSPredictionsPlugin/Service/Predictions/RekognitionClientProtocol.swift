//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSRekognition

public protocol RekognitionClientProtocol {

    /// Performs the `RecognizeCelebrities` operation on the `RekognitionService` service.
    ///
    /// Returns an array of celebrities recognized in the input image. For more information, see Recognizing celebrities in the Amazon Rekognition Developer Guide. RecognizeCelebrities returns the 64 largest faces in the image. It lists the recognized celebrities in the CelebrityFaces array and any unrecognized faces in the UnrecognizedFaces array. RecognizeCelebrities doesn't return celebrities whose faces aren't among the largest 64 faces in the image. For each celebrity recognized, RecognizeCelebrities returns a Celebrity object. The Celebrity object contains the celebrity name, ID, URL links to additional information, match confidence, and a ComparedFace object that you can use to locate the celebrity's face on the image. Amazon Rekognition doesn't retain information about which images a celebrity has been recognized in. Your application must store this information and use the Celebrity ID property as a unique identifier for the celebrity. If you don't store the celebrity name or additional information URLs returned by RecognizeCelebrities, you will need the ID to identify the celebrity in a call to the [GetCelebrityInfo] operation. You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. For an example, see Recognizing celebrities in an image in the Amazon Rekognition Developer Guide. This operation requires permissions to perform the rekognition:RecognizeCelebrities operation.
    ///
    /// - Parameter RecognizeCelebritiesInput : [no documentation found]
    ///
    /// - Returns: `RecognizeCelebritiesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You are not authorized to perform the action.
    /// - `ImageTooLargeException` : The input image size exceeds the allowed limit. If you are calling DetectProtectiveEquipment, the image size or resolution exceeds the allowed limit. For more information, see Guidelines and quotas in Amazon Rekognition in the Amazon Rekognition Developer Guide.
    /// - `InternalServerError` : Amazon Rekognition experienced a service issue. Try your call again.
    /// - `InvalidImageFormatException` : The provided image format is not supported.
    /// - `InvalidParameterException` : Input parameter violated a constraint. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Rekognition is unable to access the S3 object specified in the request.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Rekognition.
    /// - `ThrottlingException` : Amazon Rekognition is temporarily unable to process the request. Try your call again.
    func recognizeCelebrities(input: RecognizeCelebritiesInput) async throws -> RecognizeCelebritiesOutput

    /// Performs the `SearchFacesByImage` operation on the `RekognitionService` service.
    ///
    /// For a given input image, first detects the largest face in the image, and then searches the specified collection for matching faces. The operation compares the features of the input face with faces in the specified collection. To search for all faces in an input image, you might first call the [IndexFaces] operation, and then use the face IDs returned in subsequent calls to the [SearchFaces] operation. You can also call the DetectFaces operation and use the bounding boxes in the response to make face crops, which then you can pass in to the SearchFacesByImage operation. You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. The response returns an array of faces that match, ordered by similarity score with the highest similarity first. More specifically, it is an array of metadata for each face match found. Along with the metadata, the response also includes a similarity indicating how similar the face is to the input face. In the response, the operation also returns the bounding box (and a confidence level that the bounding box contains a face) of the face that Amazon Rekognition used for the input image. If no faces are detected in the input image, SearchFacesByImage returns an InvalidParameterException error. For an example, Searching for a Face Using an Image in the Amazon Rekognition Developer Guide. The QualityFilter input parameter allows you to filter out detected faces that don’t meet a required quality bar. The quality bar is based on a variety of common use cases. Use QualityFilter to set the quality bar for filtering by specifying LOW, MEDIUM, or HIGH. If you do not want to filter detected faces, specify NONE. The default value is NONE. To use quality filtering, you need a collection associated with version 3 of the face model or higher. To get the version of the face model associated with a collection, call [DescribeCollection]. This operation requires permissions to perform the rekognition:SearchFacesByImage action.
    ///
    /// - Parameter SearchFacesByImageInput : [no documentation found]
    ///
    /// - Returns: `SearchFacesByImageOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You are not authorized to perform the action.
    /// - `ImageTooLargeException` : The input image size exceeds the allowed limit. If you are calling DetectProtectiveEquipment, the image size or resolution exceeds the allowed limit. For more information, see Guidelines and quotas in Amazon Rekognition in the Amazon Rekognition Developer Guide.
    /// - `InternalServerError` : Amazon Rekognition experienced a service issue. Try your call again.
    /// - `InvalidImageFormatException` : The provided image format is not supported.
    /// - `InvalidParameterException` : Input parameter violated a constraint. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Rekognition is unable to access the S3 object specified in the request.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Rekognition.
    /// - `ResourceNotFoundException` : The resource specified in the request cannot be found.
    /// - `ThrottlingException` : Amazon Rekognition is temporarily unable to process the request. Try your call again.
    func searchFacesByImage(input: SearchFacesByImageInput) async throws -> SearchFacesByImageOutput

    /// Performs the `DetectFaces` operation on the `RekognitionService` service.
    ///
    /// Detects faces within an image that is provided as input. DetectFaces detects the 100 largest faces in the image. For each face detected, the operation returns face details. These details include a bounding box of the face, a confidence value (that the bounding box contains a face), and a fixed set of attributes such as facial landmarks (for example, coordinates of eye and mouth), pose, presence of facial occlusion, and so on. The face-detection algorithm is most effective on frontal faces. For non-frontal or obscured faces, the algorithm might not detect the faces or might detect faces with lower confidence. You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. This is a stateless API operation. That is, the operation does not persist any data. This operation requires permissions to perform the rekognition:DetectFaces action.
    ///
    /// - Parameter DetectFacesInput : [no documentation found]
    ///
    /// - Returns: `DetectFacesOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You are not authorized to perform the action.
    /// - `ImageTooLargeException` : The input image size exceeds the allowed limit. If you are calling DetectProtectiveEquipment, the image size or resolution exceeds the allowed limit. For more information, see Guidelines and quotas in Amazon Rekognition in the Amazon Rekognition Developer Guide.
    /// - `InternalServerError` : Amazon Rekognition experienced a service issue. Try your call again.
    /// - `InvalidImageFormatException` : The provided image format is not supported.
    /// - `InvalidParameterException` : Input parameter violated a constraint. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Rekognition is unable to access the S3 object specified in the request.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Rekognition.
    /// - `ThrottlingException` : Amazon Rekognition is temporarily unable to process the request. Try your call again.
    func detectFaces(input: DetectFacesInput) async throws -> DetectFacesOutput

    /// Performs the `DetectText` operation on the `RekognitionService` service.
    ///
    /// Detects text in the input image and converts it into machine-readable text. Pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, you must pass it as a reference to an image in an Amazon S3 bucket. For the AWS CLI, passing image bytes is not supported. The image must be either a .png or .jpeg formatted file. The DetectText operation returns text in an array of [TextDetection] elements, TextDetections. Each TextDetection element provides information about a single word or line of text that was detected in the image. A word is one or more script characters that are not separated by spaces. DetectText can detect up to 100 words in an image. A line is a string of equally spaced words. A line isn't necessarily a complete sentence. For example, a driver's license number is detected as a line. A line ends when there is no aligned text after it. Also, a line ends when there is a large gap between words, relative to the length of the words. This means, depending on the gap between words, Amazon Rekognition may detect multiple lines in text aligned in the same direction. Periods don't represent the end of a line. If a sentence spans multiple lines, the DetectText operation returns multiple lines. To determine whether a TextDetection element is a line of text or a word, use the TextDetection object Type field. To be detected, text must be within +/- 90 degrees orientation of the horizontal axis. For more information, see Detecting text in the Amazon Rekognition Developer Guide.
    ///
    /// - Parameter DetectTextInput : [no documentation found]
    ///
    /// - Returns: `DetectTextOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You are not authorized to perform the action.
    /// - `ImageTooLargeException` : The input image size exceeds the allowed limit. If you are calling DetectProtectiveEquipment, the image size or resolution exceeds the allowed limit. For more information, see Guidelines and quotas in Amazon Rekognition in the Amazon Rekognition Developer Guide.
    /// - `InternalServerError` : Amazon Rekognition experienced a service issue. Try your call again.
    /// - `InvalidImageFormatException` : The provided image format is not supported.
    /// - `InvalidParameterException` : Input parameter violated a constraint. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Rekognition is unable to access the S3 object specified in the request.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Rekognition.
    /// - `ThrottlingException` : Amazon Rekognition is temporarily unable to process the request. Try your call again.
    func detectText(input: DetectTextInput) async throws -> DetectTextOutput

    /// Performs the `DetectModerationLabels` operation on the `RekognitionService` service.
    ///
    /// Detects unsafe content in a specified JPEG or PNG format image. Use DetectModerationLabels to moderate images depending on your requirements. For example, you might want to filter images that contain nudity, but not images containing suggestive content. To filter images, use the labels returned by DetectModerationLabels to determine which types of content are appropriate. For information about moderation labels, see Detecting Unsafe Content in the Amazon Rekognition Developer Guide. You pass the input image either as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. You can specify an adapter to use when retrieving label predictions by providing a ProjectVersionArn to the ProjectVersion argument.
    ///
    /// - Parameter DetectModerationLabelsInput : [no documentation found]
    ///
    /// - Returns: `DetectModerationLabelsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You are not authorized to perform the action.
    /// - `HumanLoopQuotaExceededException` : The number of in-progress human reviews you have has exceeded the number allowed.
    /// - `ImageTooLargeException` : The input image size exceeds the allowed limit. If you are calling DetectProtectiveEquipment, the image size or resolution exceeds the allowed limit. For more information, see Guidelines and quotas in Amazon Rekognition in the Amazon Rekognition Developer Guide.
    /// - `InternalServerError` : Amazon Rekognition experienced a service issue. Try your call again.
    /// - `InvalidImageFormatException` : The provided image format is not supported.
    /// - `InvalidParameterException` : Input parameter violated a constraint. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Rekognition is unable to access the S3 object specified in the request.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Rekognition.
    /// - `ResourceNotFoundException` : The resource specified in the request cannot be found.
    /// - `ResourceNotReadyException` : The requested resource isn't ready. For example,
    ///
    ///
    /// this exception occurs when you call DetectCustomLabels with a model version that isn't deployed.
    /// - `ThrottlingException` : Amazon Rekognition is temporarily unable to process the request. Try your call again.
    func detectModerationLabels(input: DetectModerationLabelsInput) async throws -> DetectModerationLabelsOutput

    /// Performs the `DetectLabels` operation on the `RekognitionService` service.
    ///
    /// Detects instances of real-world entities within an image (JPEG or PNG) provided as input. This includes objects like flower, tree, and table; events like wedding, graduation, and birthday party; and concepts like landscape, evening, and nature. For an example, see Analyzing images stored in an Amazon S3 bucket in the Amazon Rekognition Developer Guide. You pass the input image as base64-encoded image bytes or as a reference to an image in an Amazon S3 bucket. If you use the AWS CLI to call Amazon Rekognition operations, passing image bytes is not supported. The image must be either a PNG or JPEG formatted file. Optional Parameters You can specify one or both of the GENERAL_LABELS and IMAGE_PROPERTIES feature types when calling the DetectLabels API. Including GENERAL_LABELS will ensure the response includes the labels detected in the input image, while including IMAGE_PROPERTIES will ensure the response includes information about the image quality and color. When using GENERAL_LABELS and/or IMAGE_PROPERTIES you can provide filtering criteria to the Settings parameter. You can filter with sets of individual labels or with label categories. You can specify inclusive filters, exclusive filters, or a combination of inclusive and exclusive filters. For more information on filtering see [Detecting Labels in an Image](https://docs.aws.amazon.com/rekognition/latest/dg/labels-detect-labels-image.html). When getting labels, you can specify MinConfidence to control the confidence threshold for the labels returned. The default is 55%. You can also add the MaxLabels parameter to limit the number of labels returned. The default and upper limit is 1000 labels. These arguments are only valid when supplying GENERAL_LABELS as a feature type. Response Elements For each object, scene, and concept the API returns one or more labels. The API returns the following types of information about labels:
    ///
    /// * Name - The name of the detected label.
    ///
    /// * Confidence - The level of confidence in the label assigned to a detected object.
    ///
    /// * Parents - The ancestor labels for a detected label. DetectLabels returns a hierarchical taxonomy of detected labels. For example, a detected car might be assigned the label car. The label car has two parent labels: Vehicle (its parent) and Transportation (its grandparent). The response includes the all ancestors for a label, where every ancestor is a unique label. In the previous example, Car, Vehicle, and Transportation are returned as unique labels in the response.
    ///
    /// * Aliases - Possible Aliases for the label.
    ///
    /// * Categories - The label categories that the detected label belongs to.
    ///
    /// * BoundingBox — Bounding boxes are described for all instances of detected common object labels, returned in an array of Instance objects. An Instance object contains a BoundingBox object, describing the location of the label on the input image. It also includes the confidence for the accuracy of the detected bounding box.
    ///
    ///
    /// The API returns the following information regarding the image, as part of the ImageProperties structure:
    ///
    /// * Quality - Information about the Sharpness, Brightness, and Contrast of the input image, scored between 0 to 100. Image quality is returned for the entire image, as well as the background and the foreground.
    ///
    /// * Dominant Color - An array of the dominant colors in the image.
    ///
    /// * Foreground - Information about the sharpness, brightness, and dominant colors of the input image’s foreground.
    ///
    /// * Background - Information about the sharpness, brightness, and dominant colors of the input image’s background.
    ///
    ///
    /// The list of returned labels will include at least one label for every detected object, along with information about that label. In the following example, suppose the input image has a lighthouse, the sea, and a rock. The response includes all three labels, one for each object, as well as the confidence in the label: {Name: lighthouse, Confidence: 98.4629}
    ///     {Name: rock,Confidence: 79.2097}
    ///
    /// {Name: sea,Confidence: 75.061} The list of labels can include multiple labels for the same object. For example, if the input image shows a flower (for example, a tulip), the operation might return the following three labels. {Name: flower,Confidence: 99.0562}
    ///     {Name: plant,Confidence: 99.0562}
    ///
    /// {Name: tulip,Confidence: 99.0562} In this example, the detection algorithm more precisely identifies the flower as a tulip. If the object detected is a person, the operation doesn't provide the same facial details that the [DetectFaces] operation provides. This is a stateless API operation that doesn't return any data. This operation requires permissions to perform the rekognition:DetectLabels action.
    ///
    /// - Parameter DetectLabelsInput : [no documentation found]
    ///
    /// - Returns: `DetectLabelsOutput` : [no documentation found]
    ///
    /// - Throws: One of the exceptions listed below __Possible Exceptions__.
    ///
    /// __Possible Exceptions:__
    /// - `AccessDeniedException` : You are not authorized to perform the action.
    /// - `ImageTooLargeException` : The input image size exceeds the allowed limit. If you are calling DetectProtectiveEquipment, the image size or resolution exceeds the allowed limit. For more information, see Guidelines and quotas in Amazon Rekognition in the Amazon Rekognition Developer Guide.
    /// - `InternalServerError` : Amazon Rekognition experienced a service issue. Try your call again.
    /// - `InvalidImageFormatException` : The provided image format is not supported.
    /// - `InvalidParameterException` : Input parameter violated a constraint. Validate your parameter before calling the API operation again.
    /// - `InvalidS3ObjectException` : Amazon Rekognition is unable to access the S3 object specified in the request.
    /// - `ProvisionedThroughputExceededException` : The number of requests exceeded your throughput limit. If you want to increase this limit, contact Amazon Rekognition.
    /// - `ThrottlingException` : Amazon Rekognition is temporarily unable to process the request. Try your call again.
    func detectLabels(input: DetectLabelsInput) async throws -> DetectLabelsOutput


}

extension RekognitionClient: RekognitionClientProtocol { }
