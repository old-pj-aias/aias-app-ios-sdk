//
//  AppDelegate.swift
//  exsample
//
//  Created by shunta nakajima on 2020/09/03.
//  Copyright © 2020 ShuntaNakajima. All rights reserved.
//

import UIKit
import Aias

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Aias.shared.configure(scheme: "aias-demo")
        sendSecondVCIfLogginIn()
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        Aias.shared.loadScheme(url: url)
        sendSecondVCIfLogginIn()
        return true
    }
    
    func sendSecondVCIfLogginIn(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var initialViewController = storyboard.instantiateViewController(withIdentifier:"FirstVC")
        if Aias.shared.isLoggingIn{
            initialViewController = storyboard.instantiateViewController(withIdentifier:"SecondVC")
        }
        self.window?.rootViewController = initialViewController
        self.window?.makeKeyAndVisible()
    }

}

