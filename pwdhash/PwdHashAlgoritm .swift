//
//  PwdHashAlgoritm .swift
//  pwdhash
//
//  Created by Руслан Штыбаев on 02.10.2024.
//

import CommonCrypto
import UIKit

struct PwdHashAlgoritm {
    func hmac(hashName: String, message: Data, key: Data) -> String {
        let algos = ["MD5": (kCCHmacAlgMD5, CC_MD5_DIGEST_LENGTH)]
        let (hashAlgorithm, length) = algos[hashName]!
        
        var macData = Data(count: Int(length))
        
        macData.withUnsafeMutableBytes { macBytes in
            message.withUnsafeBytes { messageBytes in
                key.withUnsafeBytes { keyBytes in
                    CCHmac(CCHmacAlgorithm(hashAlgorithm),
                           keyBytes,
                           key.count,
                           messageBytes,
                           message.count,
                           macBytes
                    )
                }
            }
        }
        
        return macData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
    
    func hmac(_ hashName:String, _ message: String, _ key: String) -> String {
        let messageData = message.data(using:.utf8)!
        let keyData = key.data(using:.utf8)!
        return hmac(hashName: hashName, message: messageData, key: keyData)
    }
    
    func charCodeAt(_ str: Character) -> UInt32 {
        let characterString = String(str)
        let scalars = characterString.unicodeScalars
        return scalars[scalars.startIndex].value
    }
    
    func fromCharCode(_ str: UInt32) -> String {
        return String(UnicodeScalar(UInt8(str)))
    }
    
    func contains(_ str: String, _ pattern: String) -> Bool {
        let match = str.range(
            of: pattern,
            options: .regularExpression
        )
        return match != nil
    }
    
    func hasSpecialCharacters(_ str: String) -> Bool {
        let match = str.range(
            of: ".*[^A-Za-z0-9].*",
            options: .regularExpression
        )
        return match != nil
    }
    
    func apply_constraint(_ hash: String, _ size: Int, _ nonalphanumeric: Bool) -> String {
        let dropped = hash.dropLast(2)
        let start_size = size - 4
        var result = String(dropped.prefix(start_size))
        var extras = Array(dropped.suffix(dropped.count - start_size).reversed())
        
        func nextExtra() -> UInt32 {
            let last = extras.removeLast()
            if (extras.count != 0) {
                return charCodeAt(last)
            } else {
                return 0
            }
        }
        
        func nextExtraChar() -> String {
            let next = nextExtra()
            return fromCharCode(next)
        }
        
        func between(_ min: UInt32, _ interval: UInt32, _ offset: UInt32) -> UInt32 {
            return min + offset % interval
        }
        
        func nextBetween(_ base: Character, _ interval: UInt32) -> String {
            let code = charCodeAt(base)
            let next = nextExtra()
            let result = between(code, interval, next)
            return fromCharCode(result)
        }
        
        func rotate(str: String, amount: UInt32) -> String {
            var i = 0
            var res = Array(str)
            while(i < amount) {
                let shift = res.removeFirst()
                res.append(shift)
                i += 1
            }
            return String(res)
        }
        
        result += contains(result, "[A-Z]") ? nextExtraChar() : nextBetween("A", 26)
        result += contains(result, "[a-z]") ? nextExtraChar() : nextBetween("a", 26)
        result += contains(result, "[0-9]") ? nextExtraChar() : nextBetween("0", 10)
        result += hasSpecialCharacters(result) && nonalphanumeric ? nextExtraChar() : "+"
        
        while (hasSpecialCharacters(result) && !nonalphanumeric) {
            let replacer = nextBetween("A", 26)
            result.replace(/\W+/) { _ in replacer }
        }
        
        result = rotate(str: result, amount: nextExtra())
        return result
    }
}
