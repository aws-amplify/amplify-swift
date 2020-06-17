//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockStorageCategoryPlugin {
    struct Responders {
        var getURL: GetURLResponder?
        var downloadData: DownloadDataResponder?
        var downloadFile: DownloadFileResponder?
        var uploadData: UploadDataResponder?
        var uploadFile: UploadFileResponder?
        var remove: RemoveResponder?
        var list: ListResponder?
    }
}

typealias GetURLResponder = (
    String,
    StorageGetURLRequest.Options?,
    StorageGetURLOperation.ResultListener?
) -> Void

typealias DownloadDataResponder = (
    String,
    StorageDownloadDataRequest.Options?,
    ProgressListener?,
    StorageDownloadDataOperation.ResultListener?
) -> Void

typealias DownloadFileResponder = (
    String,
    URL,
    StorageDownloadFileRequest.Options?,
    ProgressListener?,
    StorageDownloadFileOperation.ResultListener?
) -> Void

typealias UploadDataResponder = (
    String,
    Data,
    StorageUploadDataRequest.Options?,
    ProgressListener?,
    StorageUploadDataOperation.ResultListener?
) -> Void

typealias UploadFileResponder = (
    String,
    URL,
    StorageUploadFileRequest.Options?,
    ProgressListener?,
    StorageUploadFileOperation.ResultListener?
) -> Void

typealias RemoveResponder = (
    String,
    StorageRemoveRequest.Options?,
    StorageRemoveOperation.ResultListener?
) -> Void

typealias ListResponder = (
    StorageListRequest.Options?,
    StorageListOperation.ResultListener?
) -> Void
