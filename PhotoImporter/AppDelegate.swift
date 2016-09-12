//
//  AppDelegate.swift
//  PhotoImporter
//
//  Created by Yoshimasa Niwa on 8/6/16.
//  Copyright © 2016 Yoshimasa Niwa. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        if let window = self.window {
            window.rootViewController = UINavigationController(rootViewController: ViewController())
            window.makeKeyAndVisible()
        }
        return true
    }
}
