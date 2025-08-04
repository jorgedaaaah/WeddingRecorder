//
//  AppDelegate.swift
//  WeddingRecorder
//
//  Created by Jorge on 8/2/25.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .landscape // or [.landscapeLeft, .landscapeRight]
    }
}
