//
//  Aias.swift
//  Aias
//
//  Created by shunta nakajima on 2020/09/03.
//  Copyright © 2020 ShuntaNakajima. All rights reserved.
//

import Foundation
import UIKit

public final class Aias {

    public static let shared = Aias()
    
    private var signature = ""
    private var scheme = ""
    private var publicKey = ""
    private var isSignatureExist:Bool{
        signature != ""
    }
    private var isPublicKeyExist:Bool{
        publicKey != ""
    }
    
    public func configure(scheme:String){
        self.scheme = scheme
        do{
            self.publicKey = try KeyPairManager().generateKeyPair()
        }catch{}
    }
    
    public func auth() throws{
        if isSignatureExist { throw AiasError.alreadyHaveSignature }
        if !isPublicKeyExist{
            do{
                self.publicKey = try KeyPairManager().generateKeyPair()
            }catch{
                throw AiasError.failedToGenerateKey
            }
        }
        let encodedKey = Base64Manager().encode(text: self.publicKey)
        let urlString = "aias://?pubkey=" + encodedKey + "&scheme=" + self.scheme
        guard let url = URL(string: urlString) else { return }
        if UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url, options: [:])
        }
        
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

private class KeyPairManager {
    
    func generateKeyPair() throws -> String{
        let tagForPrivateKey = "com.aias.key".data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tagForPrivateKey]
        ]
        var error: Unmanaged<CFError>?
        guard let generatedPrivateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw AiasError.failedToGenerateKey
        }
        guard let generatedPublicKey = SecKeyCopyPublicKey(generatedPrivateKey) else{
            throw AiasError.failedToGenerateKey
        }
        if let cfdata = SecKeyCopyExternalRepresentation(generatedPublicKey, &error) {
            let data:Data = cfdata as Data
            let b64Key = data.base64EncodedString()
            return b64Key
        }else{
            throw AiasError.failedToGenerateKey
        }
    }
    
    func getPublicKey() throws -> String{
        let tagForPrivateKey = "com.aias.key".data(using: .utf8)!
        let getquery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tagForPrivateKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw AiasError.failedToGetKey
        }

        let retrievedPrivateKey = item as! SecKey
        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCopyPublicKey(retrievedPrivateKey) else{
            throw AiasError.failedToGenerateKey
        }
        if let cfdata = SecKeyCopyExternalRepresentation(publicKey, &error) {
            let data:Data = cfdata as Data
            let b64Key = data.base64EncodedString()
            return b64Key
        }else{
            throw AiasError.failedToGenerateKey
        }
        
    }
    
}

private class Base64Manager {
    
    func encode(text:String) -> String{
        let textData = text.data(using: .utf8)
        guard let encodedText = textData?.base64EncodedString() else { return "" }
        return encodedText
    }
    
    func decode(text:String) -> String{
        return ""
    }
    
}

enum AiasError: Error{
    case failedToGenerateKey
    case failedAuth
    case failedToGetKey
    case alreadyHaveSignature
}
