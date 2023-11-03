//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore

struct PlaceholderError: Error {}

func defaultDecode<Output: Decodable & HeadersApplying>(data: Data, decoder: JSONDecoder, headers: [String: String]) throws -> Output {
    let output = try decoder.decode(Output.self, from: data)
    return output.applying(headers: headers)
}

struct Action<Input: Encodable, Output: Decodable & HeadersApplying> {
    let name: String
    let requestURI: String
    let successCode: Int
    let hostPrefix: String
    let method: HTTPMethod
    let mapError: (Data, HTTPURLResponse) throws -> Error

    // TODO: Figure out a better way to do this / combine with decoding
//    let applyHeaders: ([String: String?]) -> Output

    let encode: (Input, JSONEncoder) throws -> Data = { model, encoder in
        try encoder.encode(model)
    }

    let decode: (Data, JSONDecoder, [String: String]) throws -> Output

    init(
        name: String,
        requestURI: String,
        successCode: Int,
        hostPrefix: String,
        method: HTTPMethod,
        mapError: @escaping (Data, HTTPURLResponse) throws -> Error,
        decode: @escaping (Data, JSONDecoder, [String: String]) throws -> Output = defaultDecode(data:decoder:headers:)
    ) {
        self.name = name
        self.requestURI = requestURI
        self.successCode = successCode
        self.hostPrefix = hostPrefix
        self.method = method
        self.mapError = mapError
        self.decode = decode
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
    static func deleteObject(input: DeleteObjectInput) -> Self {
        .init(
            name: "DeleteObject",
            requestURI: "/\(input.key)",
            successCode: 204,
            hostPrefix: "\(input.bucket).",
            method: .delete,
            mapError: mapError(data:response:),
            decode: { _, response, headers in
                let output = DeleteObjectOutputResponse()
                return output.applying(headers: headers)
            }
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
            method: .get,
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
            requestURI: "/\(input.key)?uploads",
            successCode: 204,
            hostPrefix: "\(input.bucket).",
            method: .post,
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
            requestURI: "/\(input.key)",
            successCode: 200,
            hostPrefix: "\(input.bucket).",
            method: .get,
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
            requestURI: "/\(input.key)",
            successCode: 200,
            hostPrefix: "\(input.bucket).",
            method: .post,
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
            requestURI: "/\(input.key)",
            successCode: 204,
            hostPrefix: "\(input.bucket).",
            method: .delete,
            mapError: mapError(data:response:),
            decode: { _, response, headers in
                let output = AbortMultipartUploadOutputResponse()
                return output.applying(headers: headers)
            }
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
            requestURI: "/\(input.key)",
            successCode: 200,
            hostPrefix: "\(input.bucket).",
            method: .head,
            mapError: mapError(data:response:),
            decode: { _, response, headers in
                let output = HeadObjectOutputResponse()
                return output.applying(headers: headers)
            }
        )
    }
}


extension Action {
    static func mapError(data: Data, response: HTTPURLResponse) throws -> Error {
        ServiceError(
            message: String(decoding: data, as: UTF8.self),
            type: "placeholder",
            httpURLResponse: response
        )
    }
}
