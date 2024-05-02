//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin
import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var image: Image?

    var body: some View {
        NavigationStack {
            VStack {
                image?
                    .resizable()
                    .scaledToFit()
            }
            .padding()
            PhotosPicker(
                selection: $selectedPhoto
            ) {
                Text("Select a photo to upload")
            }
            .task(id: selectedPhoto) {
                //print(selectedPhoto?.supportedContentTypes)
                image = try? await selectedPhoto?.loadTransferable(type: Image.self)
                if let imageData = try? await selectedPhoto?.loadTransferable(type: Data.self) {
                    let uploadTask = Amplify.Storage.uploadData(
                        path: .fromString("picture-submissions/myPhoto.png"),
                        data: imageData
                    )
                }

            }
        }
    }
}
