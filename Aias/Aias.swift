//
//  Aias.swift
//  Aias
//
//  Created by shunta nakajima on 2020/09/03.
//  Copyright © 2020 ShuntaNakajima. All rights reserved.
//

import Foundation

public final class Aias {

    public static let shared = Aias()
    
    private var signature = ""
    private var scheme = ""
    
    public func configure(scheme:String){
        self.scheme = scheme
    }
    
    public func loadScheme(url:URL){
        guard let host = url.host else { return }
        if host != "aias" { return }
        guard let comp = NSURLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let params = urlComponentsToDict(comp: comp)
        guard let encodedSignature = params["signature"] else { return }
        guard let restoreData = Data(base64Encoded: encodedSignature) else { return }
        guard let signature = String(data: restoreData, encoding: .utf8) else { return }
        self.signature = signature
    }
    
    public func encodeData(token:String) -> String{
        return ""
    }
    
    private func urlComponentsToDict(comp:NSURLComponents) -> Dictionary<String, String> {
        var dict:Dictionary<String, String> = Dictionary<String, String>()
        for i in 0...(comp.queryItems?.count ?? 0) - 1 {
            let item = comp.queryItems![i] as NSURLQueryItem
            dict[item.name] = item.value
        }
        return dict
    }
}
