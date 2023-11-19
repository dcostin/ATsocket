//
//  CoinbaseAuthentication.swift
//  ATsocket
//
//  Created by Dan Costin on 11/18/23.
//

import Foundation
import CryptoKit

class CoinbaseAuthentication : NSObject {
    
    // add your key and secret here
    static var apiKey = "mJZwbq2EqADelBEv"
    static var secret = "nYOAeRoSebb59gGPW3aeyh0UQ1FGvcxI"
    
    class func generateSignature(timestamp: Int64,
                                   channel: String = "ticker",
                                   tickers: String = "BTC-USD") -> String {
        
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
