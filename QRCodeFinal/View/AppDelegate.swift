//
//  AppDelegate.swift
//  QRCodeFinal
//
//  Created by Chính Phạm on 6/19/19.
//  Copyright © 2019 Chính Phạm. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.makeKeyAndVisible()

        let detectQRCodeVC = DetectQRCodeViewController()
        window?.rootViewController = UINavigationController(rootViewController: detectQRCodeVC)
        return true
    }
}

