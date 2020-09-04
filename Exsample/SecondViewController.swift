//
//  SecondViewController.swift
//  exsample
//
//  Created by shunta nakajima on 2020/09/04.
//  Copyright © 2020 ShuntaNakajima. All rights reserved.
//

import UIKit
import Aias

class SecondViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func logoutPushed(){
        Aias.shared.logout {
            let appDelegate  = UIApplication.shared.delegate
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = storyboard.instantiateViewController(withIdentifier:"FirstVC")
            appDelegate?.window!?.rootViewController = initialViewController
        }
    }
    
    @IBAction func sendConnectionPushed(){
        let msg = "my first message"
        let token = 111111
        print(Aias.shared.encodeData(dataString: msg, token: token))
    }


}

