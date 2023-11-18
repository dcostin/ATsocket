//
//  CoinbaseAuthentication.swift
//  ATsocket
//
//  Created by Dan Costin on 11/18/23.
//

import Foundation
import CryptoKit

class CoinbaseAuthentication : NSObject {
    
    // add your key and secret here, or put it in the Mac KeyChain:
    //  Name: CoinbaseAT.View
    //  Account: your API Key
    //  Password: your Secret
    static var apiKey = ""
    static var secret = ""
    
    class func generateSignature(timestamp: Int64,
                                   channel: String = "ticker",
                                   tickers: String = "BTC-USD") -> String {
        
        if secret == "" {
            (apiKey, secret) = getKeychainItem(for: "CoinbaseAT.View")
        }
        
        let preHash = "\(timestamp)\(channel)\(tickers)"
         
        guard let preHashData = preHash.data(using: .utf8) else {
            Log.Log("Coinbase generateSignatureWS failed to encode preHash to data using utf8")
            return ""
        }
            
        guard let secretData = secret.data(using: .utf8) else {
            Log.Log("Coinbase generateSignatureWS failed to encode secret to data using utf8")
            return ""
        }
        
        let hmac = Data(HMAC<SHA256>.authenticationCode(for: preHashData, using: SymmetricKey(data: secretData))).hexEncodedString()
        
        return hmac
    }
    
    class func authenticate(_ subscriptionInput: CoinbaseATSocket.Subscription) -> CoinbaseATSocket.Subscription {
        var subscription = subscriptionInput
        
        let timestamp = Int64(Date().timeIntervalSince1970)
        
        let pairsList = subscription.product_ids.joined(separator: ",")
        
        subscription.timestamp = "\(timestamp)"
        subscription.signature = generateSignature(timestamp: timestamp, channel: subscription.channel, tickers: pairsList)
        subscription.api_key = apiKey // after generateSignature, which gets the key when needed
        
        return subscription
    }
    
    
    
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }
    
    // retrieve items from the Mac Keychain
    class func getKeychainItem(for label: String) -> (String, String) {
        do {
            let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                        kSecAttrLabel as String: label,
                                        kSecMatchLimit as String: kSecMatchLimitOne,
                                        kSecReturnAttributes as String: true,
                                        kSecReturnData as String: true]
            
            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status != errSecItemNotFound else { throw KeychainError.noPassword }
            guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
            
            guard let existingItem = item as? [String : Any],
                  let passwordData = existingItem[kSecValueData as String] as? Data,
                  let password = String(data: passwordData, encoding: String.Encoding.utf8),
                  let account = existingItem[kSecAttrAccount as String] as? String
            else {
                throw KeychainError.unexpectedPasswordData
            }
            
//            Log.Log("Username: \(account), password starts with: \(password.prefix(5))")
            Log.Log("√√√ Retrieved \(label) API key starting with \(account.prefix(5))")
            return (account, password)
            
        } catch {
            let kerror = error as! KeychainError
            switch kerror {
            case KeychainError.noPassword:
                Log.Log("\(label) trade secret not found on keychain")
            case KeychainError.unexpectedPasswordData:
                Log.Log("Unexpected password data retrieving \(label) trade secret")
            case KeychainError.unhandledError(let status):
                Log.Log("OS error getting \(label) trade secret: \(status)")
            }
            return ("", "")
        }
    }
    

}

//https://stackoverflow.com/questions/39075043/how-to-convert-data-to-hex-string-in-swift
extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}
