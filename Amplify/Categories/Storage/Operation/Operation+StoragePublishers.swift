//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: - StorageDownloadDataOperation

public extension AmplifyInProcessReportingOperation
    where
    Request == StorageDownloadDataOperation.Request,
    InProcess == StorageDownloadDataOperation.InProcess,
    Success == StorageDownloadDataOperation.Success,
    Failure == StorageDownloadDataOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }

    /// Publishes the progress of the current operation.
    ///
    /// Note that depending on timing and underlying implementation, this may be called
    /// zero or more times before completion. Further, it is not guaranteed that this
    /// publisher will report 100% complete before the upload or download is finished.
    var progressPublisher: AnyPublisher<Progress, Never> {
        internalInProcessPublisher
    }
}

// MARK: - StorageDownloadFileOperation

public extension AmplifyInProcessReportingOperation
    where
    Request == StorageDownloadFileOperation.Request,
    InProcess == StorageDownloadFileOperation.InProcess,
    Success == StorageDownloadFileOperation.Success,
    Failure == StorageDownloadFileOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }

    /// Publishes the progress of the current operation.
    ///
    /// Note that depending on timing and underlying implementation, this may be called
    /// zero or more times before completion. Further, it is not guaranteed that this
    /// publisher will report 100% complete before the upload or download is finished.
    var progressPublisher: AnyPublisher<Progress, Never> {
        internalInProcessPublisher
    }
}

// MARK: - StorageGetURLOperation

public extension AmplifyOperation
    where
    Request == StorageGetURLOperation.Request,
    Success == StorageGetURLOperation.Success,
    Failure == StorageGetURLOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - StorageListOperation

public extension AmplifyOperation
    where
    Request == StorageListOperation.Request,
    Success == StorageListOperation.Success,
    Failure == StorageListOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - StorageRemoveOperation

public extension AmplifyOperation
    where
    Request == StorageRemoveOperation.Request,
    Success == StorageRemoveOperation.Success,
    Failure == StorageRemoveOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - StorageUploadDataOperation

public extension AmplifyInProcessReportingOperation
    where
    Request == StorageUploadDataOperation.Request,
    InProcess == StorageUploadDataOperation.InProcess,
    Success == StorageUploadDataOperation.Success,
    Failure == StorageUploadDataOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }

    /// Publishes the progress of the current operation.
    ///
    /// Note that depending on timing and underlying implementation, this may be called
    /// zero or more times before completion. Further, it is not guaranteed that this
    /// publisher will report 100% complete before the upload or download is finished.
    var progressPublisher: AnyPublisher<Progress, Never> {
        internalInProcessPublisher
    }
}

// MARK: - StorageUploadFileOperation

public extension AmplifyInProcessReportingOperation
    where
    Request == StorageUploadFileOperation.Request,
    InProcess == StorageUploadFileOperation.InProcess,
    Success == StorageUploadFileOperation.Success,
    Failure == StorageUploadFileOperation.Failure {
    /// Publishes the final result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }

    /// Publishes the progress of the current operation.
    ///
    /// Note that depending on timing and underlying implementation, this may be called
    /// zero or more times before completion. Further, it is not guaranteed that this
    /// publisher will report 100% complete before the upload or download is finished.
    var progressPublisher: AnyPublisher<Progress, Never> {
        internalInProcessPublisher
    }
}
#endif
