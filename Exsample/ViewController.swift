//
//  ViewController.swift
//  exsample
//
//  Created by shunta nakajima on 2020/09/03.
//  Copyright © 2020 ShuntaNakajima. All rights reserved.
//

import UIKit
import Aias

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("aaasdafdsaf")
        // Do any additional setup after loading the view.
        do{
            try Aias.shared.auth()
        }catch{
            
        }
    }


}

