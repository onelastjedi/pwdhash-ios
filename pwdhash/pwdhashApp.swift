// Author: J.D <jd@phon.one>
import CommonCrypto
import SwiftUI

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

struct BottomBorder: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 6)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .frame(width: geometry.size.width, height: 1)
                        .background(.gray)
                        .offset(y: geometry.size.height)
                }
            )
    }
}

extension View {
    func bottomBorder() -> some View {
        self.modifier(BottomBorder())
    }
}

struct InitialState {
    var host = "", password = "", hash = "", prefix = "@@"
    var is_alert = false
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

struct ContentView: View {
    @State var __ = InitialState()
    let pasteboard = UIPasteboard.general
    
    private func generate() {
        if (__.host != "" && __.password != "") {
            let hash = hmac("MD5", __.host, __.password)
            let size =  __.password.count + __.prefix.count
            let nonalphanumeric = hasSpecialCharacters(__.password)
            let result = apply_constraint(hash, size, nonalphanumeric)
            pasteboard.string = result
            __.hash = result
            __.is_alert = true
        }
    }
    
    private func reset() {
        __.host = ""
        __.password = ""
    }
    
    var body: some View {
        VStack {
            Text("Password \nHash")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top], 10)
                .padding([.bottom, .leading], 20)
                .font(.system(size: 45, weight: .heavy))
            
            Form {
                VStack(spacing: 10) {
                    TextField("Address", text: $__.host)
                        .padding([.bottom, .top], 15)
                        .bottomBorder()
                    SecureField("Password", text: $__.password)
                        .padding([.bottom, .top], 15)
                }
            }
            .frame(height: 200)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
            
            Button("Generate", action: generate)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(.black)
                .cornerRadius(15)
                .padding(
                    EdgeInsets(
                        top: 15, leading: 15,
                        bottom: 0, trailing: 15)
                )
        }
        .frame(minWidth: 0, maxWidth: .infinity,
           minHeight: 0, maxHeight: .infinity,
           alignment: .topLeading)
        
        .alert("Copied to clipboard:", isPresented: $__.is_alert) {
            TextField("hash", text: $__.hash)
            Button("OK", role: .cancel) {
                reset()
            }
        }
    }
}

@main
struct pwdhash: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    ContentView()
}
