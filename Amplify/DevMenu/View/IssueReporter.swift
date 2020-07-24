//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// Issue report screen in developer menu
@available(iOS 13.0, *)
struct IssueReporter: View {
    @State var issueDescription: String = ""
    @State var includeLogs = true
    @State var includeEnvInfo = true
    @State var includeDeviceInfo = true

    private let issueDescriptionTitle = "Issue Description"
    private let issueDescriptionHint = "Please provide a short description of the issue.."
    private let includeLogsText = "Include logs"
    private let includeEnvInfoText = "Include environment information"
    private let includeDeviceInfoText = "Include device information"
    private let reportOnGithubButtonText = "Report on Github"
    private let copyToClipboardButtonText = "Copy to Clipboard"
    private let doneButtonText = "Done"
    private let screenTitle = "Report Issue"
    private let amplifyIosNewIssueUrl = "https://github.com/aws-amplify/amplify-ios/issues/new?&title=&body="

    var body: some View {
        VStack {
            HStack {
                Text(issueDescriptionTitle)
                Spacer()
                Button(doneButtonText, action: dismissKeyboard)
            }

            MultilineTextField(text: $issueDescription, placeHolderText: issueDescriptionHint)
                .border(Color.gray)
                .frame(height: 350)

            Toggle(isOn: $includeEnvInfo) {
                Text(includeEnvInfoText).bold()
            }.padding(.bottom)

            Toggle(isOn: $includeDeviceInfo) {
                Text(includeDeviceInfoText).bold()
            }.padding(.bottom)

            Toggle(isOn: $includeLogs) {
                Text(includeLogsText).bold()
            }.padding(.bottom)

            Spacer()

            Button(reportOnGithubButtonText, action: reportToGithub)
            .padding()
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .border(Color.blue)
            .padding(.bottom)

            Button(copyToClipboardButtonText, action: copyToClipboard)
            .padding()
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .border(Color.blue)

        }.padding()
        .navigationBarTitle(Text(screenTitle))
    }

    /// Open Amplify iOS issue logging screen on Github
    private func reportToGithub() {
        let issueDescriptionMarkdown =
            IssueInfoHelper.generateMarkdownForIssue(
                issue: IssueInfo(issueDescription: issueDescription,
                         includeEnvInfo: includeEnvInfo,
                         includeDeviceInfo: includeDeviceInfo,
                         includeLogs: includeLogs))

        let urlString = amplifyIosNewIssueUrl + issueDescriptionMarkdown
        guard let url = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        guard let urlToOpen = URL(string: url) else { return }

        UIApplication.shared.open(urlToOpen)
    }

    /// Copy issue as a markdown string to clipboard
    private func copyToClipboard() {
        UIPasteboard.general.string =
            IssueInfoHelper.generateMarkdownForIssue(
            issue: IssueInfo(issueDescription: issueDescription,
                             includeEnvInfo: includeEnvInfo,
                             includeDeviceInfo: includeDeviceInfo,
                             includeLogs: includeLogs))
    }

    /// Dismiss phone's keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

@available(iOS 13.0.0, *)
struct IssueReporter_Previews: PreviewProvider {
    static var previews: some View {
        IssueReporter()
    }
}

/// Custom defined view for multi line text field
@available(iOS 13.0, *)
struct MultilineTextField: UIViewRepresentable {
    @Binding var text: String
    var placeHolderText: String

    func makeUIView(context: UIViewRepresentableContext<MultilineTextField>) -> UITextView {
        let view = UITextView()
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.delegate = context.coordinator
        view.font = .systemFont(ofSize: 15)
        view.textColor = .secondaryLabel
        view.text = placeHolderText
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        return MultilineTextField.Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextField

        init(parent: MultilineTextField) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.textColor == .secondaryLabel {
                textView.text = nil
                textView.textColor = .label
            }
        }
    }
}
