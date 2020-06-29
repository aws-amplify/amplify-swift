//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SwiftUI

@available(iOS 13.0.0, *)
public class AmplifyDevMenu: NSObject, UIGestureRecognizerDelegate {
    var devMenuDelegate: DevMenuDelegate?

    init(delegate: DevMenuDelegate) {
        super.init()
        self.devMenuDelegate = delegate
        registerLongPressRecognizer()
    }

    public func registerLongPressRecognizer() {
        // Long press gesture recognizer
        let longPressRecognizer = UILongPressGestureRecognizer(target: self,
                                                               action: #selector(AmplifyDevMenu.longPressed(sender:)))
        longPressRecognizer.delegate = self
        devMenuDelegate?.presentationContext().addGestureRecognizer(longPressRecognizer)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool {
        return true
    }

    @objc private func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            print("long pressed detected in dev menu")
            showMenu()
        }
    }

    public func showMenu() {
        print("showMenu")
        let viewController = UIHostingController(rootView: AmplifyDevMenuList())
        devMenuDelegate?.presentationContext().rootViewController?
            .present(viewController, animated: true, completion: nil)
    }

    public func readConfig() {

        guard let fileUrl = Bundle.main.url(forResource: "amplifyconfiguration", withExtension: "json") else {
            print("File could not be located at the given url")
            return
        }

        do {

            let data = try Data(contentsOf: fileUrl)

            // Decode data to a Dictionary<String, Any> object
            guard let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("Could not cast JSON content as a Dictionary<String, Any>")
                return
            }

            print(dictionary)
        } catch {
            print("Error: \(error)")
        }
    }
}

public protocol DevMenuDelegate {
    func presentationContext() -> UIWindow
}
