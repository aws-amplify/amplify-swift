//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import Foundation
import AWSS3

// Behavior that the implemenation class for AWSS3TransferUtility will use.
protocol AWSS3TransferUtilityBehavior {
    func downloadData(fromBucket: String,
                      key: String,
                      expression: AWSS3TransferUtilityDownloadExpression,
                      completionHandler: (AWSS3TransferUtilityDownloadCompletionHandlerBlock)?)
        -> AWSTask<AWSS3TransferUtilityDownloadTask>

    func download(to fileURL: URL,
                  bucket: String,
                  key: String,
                  expression: AWSS3TransferUtilityDownloadExpression,
                  completionHandler: AWSS3TransferUtilityDownloadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityDownloadTask>

    // swiftlint:disable function_parameter_count
    func uploadData(data: Data,
                    bucket: String,
                    key: String,
                    contentType: String,
                    expression: AWSS3TransferUtilityUploadExpression,
                    completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityUploadTask>

    func uploadFile(fileURL: URL,
                    bucket: String,
                    key: String,
                    contentType: String,
                    expression: AWSS3TransferUtilityUploadExpression,
                    completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityUploadTask>

    func uploadUsingMultiPart(fileURL: URL,
                              bucket: String,
                              key: String,
                              contentType: String,
                              expression: AWSS3TransferUtilityMultiPartUploadExpression,
                              completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityMultiPartUploadTask>

    func uploadUsingMultiPart(data: Data,
                              bucket: String,
                              key: String,
                              contentType: String,
                              expression: AWSS3TransferUtilityMultiPartUploadExpression,
                              completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock?)
        -> AWSTask<AWSS3TransferUtilityMultiPartUploadTask>
}
*/
