//
//  FirstViewController.swift
//  exsample
//
//  Created by shunta nakajima on 2020/09/03.
//  Copyright © 2020 ShuntaNakajima. All rights reserved.
//

import UIKit
import Aias

class FirstViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loginButtonPushed(){
        do{
            try Aias.shared.auth()
        }catch{
            
        }
    }

}

