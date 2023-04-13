//
//  ContentView.swift
//  PredictionsHostApp
//
//  Created by Saultz, Ian on 11/3/22.
//

import SwiftUI
import Amplify

struct ContentView: View {


    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("foobar")
        .padding()
    }

    func convert() async throws {
        let url = URL(string: "")!
        let textToSpeech = try await Amplify.Predictions.convert(.textToSpeech("hello, world!"))
        _ = textToSpeech
        let speechToText = try await Amplify.Predictions.convert(.speechToText(url: url))
        _ = speechToText
    }

    func identify() async throws {
        let imageURL = URL(string: "")!
        let identifyTextOptions = Identify.Options(
            defaultNetworkPolicy: .auto,
            uploadToRemote: false,
            pluginOptions: nil
        )

        let text = try await Amplify.Predictions.identify(
            .text,
            in: imageURL,
            options: identifyTextOptions
        )

        _ = text
        let celebrities = try await Amplify.Predictions.identify(.celebrities, in: imageURL)
        _ = celebrities
        let entities = try await Amplify.Predictions.identify(.entities, in: imageURL)
        _ = entities
        let entitiesFromCollection = try await Amplify.Predictions.identify(
            .entitiesFromCollection(withID: ""),
            in: imageURL
        )
        _ = entitiesFromCollection
        let allLabels = try await Amplify.Predictions.identify(
            .labels(type: .all),
            in: imageURL
        )
        _ = allLabels
        let labels = try await Amplify.Predictions.identify(
            .labels(type: .labels),
            in: imageURL
        )
        _ = labels
        let moderationLabels = try await Amplify.Predictions.identify(
            .labels(type: .moderation),
            in: imageURL
        )
        _ = moderationLabels
        let textFromDocAll = try await Amplify.Predictions.identify(
            .textInDocument(textFormatType: .all),
            in: imageURL
        )
        _ = textFromDocAll
        let textFromDocForm = try await Amplify.Predictions.identify(
            .textInDocument(textFormatType: .form),
            in: imageURL
        )
        _ = textFromDocForm
        let textFromDocTable = try await Amplify.Predictions.identify(
            .textInDocument(textFormatType: .table),
            in: imageURL
        )
        _ = textFromDocTable
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
