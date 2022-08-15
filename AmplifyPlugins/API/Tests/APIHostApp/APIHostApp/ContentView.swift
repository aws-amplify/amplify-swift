//
//  ContentView.swift
//  APIHostApp
//
//  Created by Law, Michael on 7/21/22.
//

import SwiftUI
import Amplify
import AWSPluginsCore
struct APITask {
    
}
extension Model {
    func hasAttachments() -> Bool {
        return true
    }
    
    func getAttachments() -> [Attachment] {
        return []
    }
}

struct Attachment {
    
}

struct StorageRequest<M: Model> {
    let model: M
    let attachment: Attachment
    
    init(_ model: M, _ attachment: Attachment) {
        self.model = model
        self.attachment = attachment
    }
}
class StorageUploader {
    
    // upload multiple storage requests, by default this request performs a transaction
    // by default.
    // 1. if one upload fails, then the successful uploads will be deleted.
    // 2. if one upload fails, then it will be reattempted.
    // 3. if the requestId is returned, it can be used to resume the upload.
    // resumability.
    func uploadMultiple<M:Model>(_ storageRequests: [StorageRequest<M>]) async throws -> Bool {
        return false
    }
}
// A seamless way to work with models and files.


// Create
// long running when model has attachments
// fast running when model does not.

// what happens when first upload fails? - retrying 1/3, 2/3, 3/3.
// what happens when second upload succeeds and second upload fails? 1/2, 2/3, 3/3
// what happens when all uploads successful but create model failed?

// create a file reference, upload the file later.
let post = Post()
let file = File(key)
post.file.append(file)
func create<M: Model>(_ model: M) async throws -> APITask {
    if model.hasAttachments() {
        var storageRequests = [StorageRequest<M>]()
        let attachments = model.getAttachments()
        for attachment in attachments {
            storageRequests.append(StorageRequest(model, attachment))
        }
        let result = try await StorageUploader.uploadMultiple(storageRequests)
        let operation = StorageOperation()
    } else {
        let request = GraphQLRequest<M>.create(model)
        // create operation and add to task, and return task.
        let response = try await Amplify.API.mutate(request: request)
        return APITask()
    }
}
file.replaceExistingWith(data)
Storage.upload(file)

// or
let file = File(key, url)
let file = File(key, data)
create(post)

file.data = "new data" // on set of data, set attachment to "dirty"

// Update
// attachment.replaceWith(data)
func update<M: Model>(_ model: M, where: String? = nil) async throws -> APITask {
    if model.hasAttachmentUpdates() {
        var storageRequests = model.getAttachmentUpdates()
    } else {
        let request = GraphQLRequest<M>.update(model)
        // create operation and add to task, and return task.
        let response = try await Amplify.API.mutate(request: request)
        return APITask()
    }
}


// Query.
func query<M: Model>(_ model: ModelType) async throws -> APITask {
    let request = GraphQLRequest<M>.update(model)
    let response = try await Amplify.API.query(request: request)
    if response.model.hasAttachments() {
        let attachments = response.model.getAttachments()
        for attachment in attachments {
            Storage.download(attachment: attachment)
        }
    }
}

// defered downloads.
let post = try await Amplify.API.query(Post.self)
for file in post.files {
    let data = Storage.download(file)
}


// Delete
// delete attachment - Storage.delete
// Storage.delete(attachment)
// Storage.delete(.attachment(attachment.request))
// Amplify.API.delete(model)
// delete the model first, before deleting the files.
// if model fails to delete, the fails still exist.
// if model is deleted successfully, attempt to delete the files, and return failures for
// any files that could not be cleaned up.
func delete(attachment: Attachment) {
    
}
// cRud
// to replace or add an attachment
// let attachment = Attachment(x,c, data)
// let model = Model(attachment: attachment)
// Storage.upload(attachment)
//

// Update
//

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
