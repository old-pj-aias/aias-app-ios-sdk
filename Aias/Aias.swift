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
    
    private var FBSignature = ""
    private var scheme = ""
    private var publicKey = ""
    public var isLoggingIn:Bool{
        FBSignature != ""
    }
    private var isPublicKeyExist:Bool{
        publicKey != ""
    }
    
    public func configure(scheme:String){
        self.scheme = scheme
        do{
            _ = try KeyPairManager().getPrivateKey()
            do{
                self.publicKey = try KeyPairManager().getPublicKey()
            }catch{}
        }catch{
            do{
                self.publicKey = try KeyPairManager().generateKeyPair()
            }catch{}
        }
        guard let data = KeyChain.load(key: "com.aias.signature") else { return }
        guard let signature = String(data: data, encoding: .utf8) else { return }
        FBSignature = signature
    }
    
    public func auth() throws{
        if isLoggingIn { throw AiasError.alreadyHaveSignature }
        if !isPublicKeyExist{
            do{
                self.publicKey = try KeyPairManager().generateKeyPair()
            }catch{}
        }
        let encodedKey = Base64Manager().encode(text: self.publicKey)
        let urlString = "aias://?pubkey=" + encodedKey + "&scheme=" + self.scheme
        guard let url = URL(string: urlString) else { return }
        if UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url, options: [:])
        }
        
    }
    
    public func logout(sucess:() -> ()){
        KeyChain.remove(key: "com.aias.signature")
        return sucess()
    }
    
    public func loadScheme(url:URL){
        guard let host = url.host else { return }
        if host != "aias" { return }
        guard let comp = NSURLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let params = urlComponentsToDict(comp: comp)
        guard let encodedSignature = params["signature"] else { return }
        guard let restoreData = Data(base64Encoded: encodedSignature) else { return }
        guard let signature = String(data: restoreData, encoding: .utf8) else { return }
        guard let data = signature.data(using: .utf8) else { return }
        self.FBSignature = signature
        _ = KeyChain.save(key: "com.aias.signature", data: data)
    }
    
    public func encodeData(dataString:String,token:Int) -> String{
        let signedObject = Base64Manager().encode(text: dataString) + "." + String(token)
        var signature = ""
        do{
            signature = try KeyPairManager().createSignature(text: signedObject)
        }catch{
            return ""
        }
        
        let data: [String: Any] = [
            "data": dataString,
            "random": token
        ]
        
        let jsonObject: [String: Any] = [
            "fair_blind_signature": FBSignature,
            "pubkey": publicKey,
            "signature": signature,
            "signed": data
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            let jsonStr = String(bytes: jsonData, encoding: .utf8)!
            return jsonStr
        } catch {
            return ""
        }
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
            let b64Key = SwKeyConvert.PublicKey.derToPKCS8PEM(data)
            return b64Key
        }else{
            throw AiasError.failedToGenerateKey
        }
    }
    
    func getPublicKey() throws -> String{
        var error: Unmanaged<CFError>?
        do{
            let privateKey = try getPrivateKey()
            guard let publicKey = SecKeyCopyPublicKey(privateKey) else{
                throw AiasError.failedToGenerateKey
            }
            if let cfdata = SecKeyCopyExternalRepresentation(publicKey, &error) {
                let data:Data = cfdata as Data
                let b64Key = SwKeyConvert.PublicKey.derToPKCS8PEM(data)
                return b64Key
            }else{
                throw AiasError.failedToGenerateKey
            }
        }catch{
            throw AiasError.failedToGenerateKey
        }
        
    }
    
    func getPrivateKey() throws -> SecKey{
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
        return retrievedPrivateKey
    }
    
    func keyToString(key:SecKey) throws -> String{
        var error: Unmanaged<CFError>?
        if let cfdata = SecKeyCopyExternalRepresentation(key, &error) {
            let data:Data = cfdata as Data
            let b64Key = data.base64EncodedString()
            return b64Key
        }else{
            throw AiasError.failedToGenerateKey
        }
    }
    
    func createSignature(text:String) throws -> String{
        var error: Unmanaged<CFError>?
        let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
        do{
            let privateKey = try getPrivateKey()
            guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
                throw AiasError.failedToGenerateSignature
            }
            guard let signature = SecKeyCreateSignature(
                privateKey,
                algorithm,
                text.data(using: .utf8)! as CFData,
                &error) as Data? else {
                    throw error!.takeRetainedValue() as Error
            }
            let signatureString = signature.base64EncodedString()
            return signatureString
        }catch{
            throw AiasError.failedToGenerateSignature
        }
    }
    
}

private class Base64Manager {
    
    func encode(text:String) -> String{
        let textData = text.data(using: .utf8)
        guard let encodedText = textData?.base64EncodedString() else { return "" }
        return encodedText
    }
    
}

public enum AiasError: Error{
    case failedToGenerateKey
    case failedAuth
    case failedToGetKey
    case alreadyHaveSignature
    case failedToGenerateSignature
}

class KeyChain {

    class func save(key: String, data: Data) -> OSStatus {
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key,
            kSecValueData as String   : data ] as [String : Any]

        SecItemDelete(query as CFDictionary)

        return SecItemAdd(query as CFDictionary, nil)
    }
    
    class func remove(key:String){
        let query = [
            kSecClass as String       : kSecClassGenericPassword as String,
            kSecAttrAccount as String : key ] as [String : Any]

        SecItemDelete(query as CFDictionary)
    }

    class func load(key: String) -> Data? {
        let query = [
            kSecClass as String       : kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue!,
            kSecMatchLimit as String  : kSecMatchLimitOne ] as [String : Any]

        var dataTypeRef: AnyObject? = nil

        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == noErr {
            return dataTypeRef as! Data?
        } else {
            return nil
        }
    }
    

    class func createUniqueID() -> String {
        let uuid: CFUUID = CFUUIDCreate(nil)
        let cfStr: CFString = CFUUIDCreateString(nil, uuid)

        let swiftString: String = cfStr as String
        return swiftString
    }
}

extension Data {

    init<T>(from value: T) {
        var value = value
        self.init(buffer: UnsafeBufferPointer(start: &value, count: 1))
    }

    func to<T>(type: T.Type) -> T {
        return self.withUnsafeBytes { $0.load(as: T.self) }
    }
}
