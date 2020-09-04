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
    
    @IBOutlet var textField : UITextField!
    @IBOutlet var textView: UITextView!
    let hostString = "http://localhost:5000"
    var token:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.isEditable = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchData()
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
        let text = textField.text ?? ""
        if text == "" { return }
        textField.text = ""
        view.endEditing(true)
        
        func postToServer(){
            let url = URL(string: hostString + "/post")
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.httpBody = Aias.shared.encodeData(dataString: text, token: token).data(using: .utf8)
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                if error == nil, let data = data {
                    do{
                        let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        self.token = Int((dic!["random"] as? String) ?? "0") ?? 0
                        self.fetchData()
                    }catch{}
                }
            }.resume()
        }
        
        if token == 0{
            let url = URL(string: hostString + "/token")
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.httpBody = Aias.shared.encodeData(dataString: text, token: token).data(using: .utf8)
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                if error == nil, let data = data {
                    do{
                        let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        self.token = Int((dic!["random"] as? String) ?? "0") ?? 0
                        postToServer()
                    }catch{}
                }
            }.resume()
        }else{
            postToServer()
        }
    }
    
    func fetchData(){
        let url = URL(string: hostString + "/get")
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        let session = URLSession.shared
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let data = data {
                do{
                    let dic = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let data = dic!["data"] as? [String] ?? []
                    DispatchQueue.main.async {
                        self.textView.text = data.joined(separator: "\n")
                    }
                }catch{}
            }
        }.resume()
    }

}

