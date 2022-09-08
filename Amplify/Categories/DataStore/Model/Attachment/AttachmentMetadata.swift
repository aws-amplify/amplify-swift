//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol EmbeddableAttachment: Embeddable, AttachmentMetadata { }


public protocol AttachmentMetadata {
    var key: String { get }
    var accessLevel: String? { get }
    var identityId: String? { get }
}

protocol AttachmentBehavior {
    associatedtype Metadata: EmbeddableAttachment

    // Retrieve the underlying embedded attachment metadata
    var metadata: Metadata? { get set }
    
    // Attach data to be uploaded
    func attachData(_ data: Data)

    // Attach the file to be uploaded
    func attachFile(_ file: URL)
    
    // Upload the attached data or file object
    func upload() async throws -> String
    
    // Upload a specific data object to Storage
    func uploadData(_ data: Data) async throws -> StorageUploadDataTask
    
    // Upload a specific file to Storage
    func uploadFile(_ file: URL) async throws -> StorageUploadFileTask
    
    // Download the data associated with this attachment
    func downloadData() async throws -> StorageDownloadDataTask
    
    // Download the file associated with this attachment
    func downloadFile(to local: URL) async throws -> StorageDownloadFileTask
    
    // Remove the object from Storage
    func remove() async throws
    
    // Get a URL for the object stored in Storage
    func getURL() async throws -> URL
}
