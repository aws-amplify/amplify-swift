//
//  APIHostAppApp.swift
//  APIHostApp
//
//  Created by Law, Michael on 7/21/22.
//

import SwiftUI

// Run project on iOS 13; https://stackoverflow.com/questions/62935053/use-main-in-xcode-12

@main
struct APIHostAppAppWrapper {
    static func main() {
        if #available(iOS 14.0, *) {
            APIHostAppApp.main()
        }
        else {
            UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(SceneDelegate.self))
        }
    }
}

@available(iOS 14.0, *)
struct APIHostAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = ContentView()

        // Use a UIHostingController as window root view controller.
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
