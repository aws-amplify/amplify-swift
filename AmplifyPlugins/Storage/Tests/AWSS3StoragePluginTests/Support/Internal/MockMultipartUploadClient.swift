import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class MockMultipartUploadClient: StorageMultipartUploadClient {

    enum Failure: Error {
        case sessionNotIntegrated
        case mockFailure
    }

    var uploadPartCount = 0
    var completeMultipartUploadCount = 0
    var abortMultipartUploadCount = 0
    var errorCount = 0
    var taskIdentifier = 100

    let uploadFile: UploadFile
    var session: StorageMultipartUploadSession?

    var didCreate: ((StorageMultipartUploadSession) -> Void)?
    var didStartPartUpload: ((StorageMultipartUploadSession, PartNumber) -> Void)?
    var didTransferBytesForPartUpload: ((StorageMultipartUploadSession, PartNumber, Int) -> Void)?
    var shouldFailPartUpload: ((StorageMultipartUploadSession, PartNumber) -> Bool)?
    var didCompletePartUpload: ((StorageMultipartUploadSession, PartNumber, String, TaskIdentifier) -> Void)?
    var didFailPartUpload: ((StorageMultipartUploadSession, PartNumber, Error) -> Void)?
    var didCompleteMultipartUpload: ((StorageMultipartUploadSession, UploadID) -> Void)?
    var didAbortMultipartUpload: ((StorageMultipartUploadSession, UploadID) -> Void)?

    init(uploadFile: UploadFile? = nil) {
        self.uploadFile = uploadFile ?? UploadFile(fileURL: URL(fileURLWithPath: "/tmp/upload.txt"), temporaryFileCreated: true, size: UInt64(Bytes.megabytes(42).bytes))
    }

    func integrate(session: StorageMultipartUploadSession) {
        self.session = session
    }

    func createMultipartUpload() throws {
        guard let session = session else { throw Failure.sessionNotIntegrated }

        let uploadId = UUID().uuidString
        session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: uploadId))
        didCreate?(session)
    }

    func uploadPart(partNumber: PartNumber, multipartUpload: StorageMultipartUpload, subTask: StorageTransferTask) throws {
        guard let _ = multipartUpload.uploadFile,
              let _ = multipartUpload.uploadId,
              let _ = multipartUpload.partSize,
              let part = multipartUpload.part(for: partNumber) else {
                  fatalError()
              }
        print("Upload Part \(partNumber)")
        guard let session = session else { throw Failure.sessionNotIntegrated }

        uploadPartCount += 1

        defer {
            taskIdentifier += 1
        }

        subTask.sessionTask = MockStorageSessionTask(taskIdentifier: taskIdentifier, state: .suspended)

        session.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: taskIdentifier))
        didStartPartUpload?(session, partNumber)

        let bytesTransferred = part.bytes / 2
        session.handle(uploadPartEvent: .progressUpdated(partNumber: partNumber, bytesTransferred: bytesTransferred, taskIdentifier: taskIdentifier))
        didTransferBytesForPartUpload?(session, partNumber, bytesTransferred)

        if shouldFailPartUpload?(session, partNumber) ?? false {
            session.handle(uploadPartEvent: .failed(partNumber: partNumber, error: Failure.mockFailure))
            return
        }

        let eTag = UUID().uuidString
        session.handle(uploadPartEvent: .completed(partNumber: partNumber, eTag: eTag, taskIdentifier: taskIdentifier))
        didCompletePartUpload?(session, partNumber, eTag, taskIdentifier)
    }

    func completeMultipartUpload(uploadId: UploadID) throws {
        guard let session = session else { throw Failure.sessionNotIntegrated }

        completeMultipartUploadCount += 1

        session.handle(multipartUploadEvent: .completed(uploadId: uploadId))
        didCompleteMultipartUpload?(session, uploadId)
    }

    func abortMultipartUpload(uploadId: UploadID, error: Error?) throws {
        guard let session = session else { throw Failure.sessionNotIntegrated }

        abortMultipartUploadCount += 1

        session.handle(multipartUploadEvent: .aborted(uploadId: uploadId, error: error))
        didAbortMultipartUpload?(session, uploadId)
    }

    func cancelUploadTasks(taskIdentifiers: [TaskIdentifier]) {
        print("Canceling upload tasks")
    }

}
