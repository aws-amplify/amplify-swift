//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct PlaceholderError: Error {}

struct Action<Input: Encodable, Output: Decodable> {
    let name: String
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let mapError: (Data, HTTPURLResponse) throws -> Error

    let encode: (Input, JSONEncoder) throws -> Data = { model, encoder in
        try encoder.encode(model)
    }

    let decode: (Data, JSONDecoder) throws -> Output = { data, decoder in
        try decoder.decode(Output.self, from: data)
    }

    func url(region: String) throws -> URL {
        guard let url = URL(
            string: "https://\(hostPrefix)s3.\(region).amazonaws.com\(requestURI)"
        ) else {
            throw PlaceholderError()
        }

        return url
    }
}

extension Action where Input == DeleteObjectInput, Output == DeleteObjectOutputResponse {
/*
 "DeleteObject":{
   "name":"DeleteObject",
   "http":{
     "method":"DELETE",
     "requestUri":"/{Bucket}/{Key+}",
     "responseCode":204
   },
   "input":{"shape":"DeleteObjectRequest"},
   "output":{"shape":"DeleteObjectOutput"},
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectDELETE.html"
 },
 */
    static func deleteObject() -> Self {
        .init(
            name: "DeleteObject",
            requestURI: "/",
            successCode: 204,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}



extension Action where Input == ListObjectsV2Input, Output == ListObjectsV2OutputResponse {
/*
 "ListObjectsV2":{
   "name":"ListObjectsV2",
   "http":{
     "method":"GET",
     "requestUri":"/{Bucket}?list-type=2"
   },
   "input":{"shape":"ListObjectsV2Request"},
   "output":{"shape":"ListObjectsV2Output"},
   "errors":[
     {"shape":"NoSuchBucket"}
   ]
 },
 */
    static func listObjectsV2(bucket: String) -> Self {
        .init(
            name: "ListObjectsV2",
            requestURI: "/\(bucket)?list-type=2",
            successCode: 204,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}

extension Action where Input == CreateMultipartUploadInput, Output == CreateMultipartUploadOutputResponse {
/*
 "CreateMultipartUpload":{
   "name":"CreateMultipartUpload",
   "http":{
     "method":"POST",
     "requestUri":"/{Bucket}/{Key+}?uploads"
   },
   "input":{"shape":"CreateMultipartUploadRequest"},
   "output":{"shape":"CreateMultipartUploadOutput"},
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadInitiate.html",
   "alias":"InitiateMultipartUpload"
 },
 */
    static func createMultipartUpload(input: CreateMultipartUploadInput) -> Self {
        .init(
            name: "CreateMultipartUpload",
            requestURI: "/\(input.bucket)/\(input.key)?uploads",
            successCode: 204,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}

extension Action where Input == ListPartsInput, Output == ListPartsOutputResponse {
/*
 "ListParts":{
   "name":"ListParts",
   "http":{
     "method":"GET",
     "requestUri":"/{Bucket}/{Key+}"
   },
   "input":{"shape":"ListPartsRequest"},
   "output":{"shape":"ListPartsOutput"},
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadListParts.html"
 },
 */
    static func listParts(input: ListPartsInput) -> Self {
        .init(
            name: "ListParts",
            requestURI: "/\(input.bucket)/\(input.key)",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}


extension Action where Input == CompleteMultipartUploadInput, Output == CompleteMultipartUploadOutputResponse {
/*
 "CompleteMultipartUpload":{
   "name":"CompleteMultipartUpload",
   "http":{
     "method":"POST",
     "requestUri":"/{Bucket}/{Key+}"
   },
   "input":{"shape":"CompleteMultipartUploadRequest"},
   "output":{"shape":"CompleteMultipartUploadOutput"},
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadComplete.html"
 }
 */
    static func completeMultipartUpload(input: CompleteMultipartUploadInput) -> Self {
        .init(
            name: "CompleteMultipartUpload",
            requestURI: "/\(input.bucket)/\(input.key)",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}

extension Action where Input == AbortMultipartUploadInput, Output == AbortMultipartUploadOutputResponse {
/*
 "AbortMultipartUpload":{
   "name":"AbortMultipartUpload",
   "http":{
     "method":"DELETE",
     "requestUri":"/{Bucket}/{Key+}",
     "responseCode":204
   },
   "input":{"shape":"AbortMultipartUploadRequest"},
   "output":{"shape":"AbortMultipartUploadOutput"},
   "errors":[
     {"shape":"NoSuchUpload"}
   ],
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/mpUploadAbort.html"
 },
 */
    static func abortMultipartUpload(input: AbortMultipartUploadInput) -> Self {
        .init(
            name: "AbortMultipartUpload",
            requestURI: "/\(input.bucket)/\(input.key)",
            successCode: 204,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}

extension Action where Input == HeadObjectInput, Output == HeadObjectOutputResponse {
/*
 "HeadObject":{
   "name":"HeadObject",
   "http":{
     "method":"HEAD",
     "requestUri":"/{Bucket}/{Key+}"
   },
   "input":{"shape":"HeadObjectRequest"},
   "output":{"shape":"HeadObjectOutput"},
   "errors":[
     {"shape":"NoSuchKey"}
   ],
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectHEAD.html"
 },
 */
    static func headObject(input: HeadObjectInput) -> Self {
        .init(
            name: "AbortMultipartUpload",
            requestURI: "/\(input.bucket)/\(input.key)",
            successCode: 200,
            hostPrefix: "",
            mapError: mapError(data:response:)
        )
    }
}


extension Action {
    static func mapError(data: Data, response: HTTPURLResponse) throws -> Error {
        PlaceholderError()
    }
}
