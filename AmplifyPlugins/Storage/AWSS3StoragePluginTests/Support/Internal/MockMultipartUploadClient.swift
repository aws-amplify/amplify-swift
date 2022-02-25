import XCTest

@testable import AWSS3StoragePlugin
@testable import Amplify

class MockMultipartUploadClient: StorageMultipartUploadClient {
    enum Failure: Error {
        case sessionNotIntegrated
        case mockFailure
    }

    var partNumbersToFail: [Int] = []

    var uploadPartCount = 0
    var completeMultipartUploadCount = 0
    var abortMultipartUploadCount = 0
    var errorCount = 0
    var taskIdentifier = 100

    let uploadFile: UploadFile
    var session: StorageMultipartUploadSession?

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

        if !partNumbersToFail.contains(partNumber) {
            session.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: taskIdentifier))
            session.handle(uploadPartEvent: .progressUpdated(partNumber: partNumber, bytesTransferred: part.bytes / 2, taskIdentifier: taskIdentifier))
            let eTag = UUID().uuidString
            session.handle(uploadPartEvent: .completed(partNumber: partNumber, eTag: eTag, taskIdentifier: taskIdentifier))
        } else {
            print("Failing part: \(partNumber)")
            session.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: taskIdentifier))
            session.handle(uploadPartEvent: .failed(partNumber: partNumber, error: Failure.mockFailure))
        }
    }

    func completeMultipartUpload(uploadId: UploadID) throws {
        guard let session = session else { throw Failure.sessionNotIntegrated }

        completeMultipartUploadCount += 1

        session.handle(multipartUploadEvent: .completed(uploadId: uploadId))
    }

    func abortMultipartUpload(uploadId: UploadID) throws {
        guard let session = session else { throw Failure.sessionNotIntegrated }

        abortMultipartUploadCount += 1

        session.handle(multipartUploadEvent: .aborted(uploadId: uploadId))
    }

}
