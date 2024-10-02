//
//  ContentView.swift
//  pwdhash
//
//  Created by Руслан Штыбаев on 02.10.2024.
//

import SwiftUI

struct InitialState {
    var host = "", password = "", hash = "", prefix = "@@"
    var is_alert = false
}

struct ContentView: View {
    
    // MARK: - Properties
    @State var state = InitialState()
    
    let algoritm = PwdHashAlgoritm()
    let pasteboard = UIPasteboard.general
    
    // MARK: - Body
    var body: some View {
        VStack {
            Text("Password \nHash")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top], 10)
                .padding([.bottom, .leading], 20)
                .font(.system(size: 45, weight: .heavy))
            
            Form {
                VStack(spacing: 10) {
                    TextField("Address", text: $state.host)
                        .padding([.bottom, .top], 15)
                        .bottomBorder()
                    SecureField("Password", text: $state.password)
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
        
        .alert("Copied to clipboard:", isPresented: $state.is_alert) {
            TextField("hash", text: $state.hash)
            Button("OK", role: .cancel) {
                reset()
            }
        }
    }
    
    // MARK: - Methods
    private func generate() {
        if (state.host != "" && state.password != "") {
            let hash = algoritm.hmac("MD5", state.host, state.password)
            let size =  state.password.count + state.prefix.count
            let nonalphanumeric = PwdHashAlgoritm().hasSpecialCharacters(state.password)
            let result = PwdHashAlgoritm().apply_constraint(hash, size, nonalphanumeric)
            pasteboard.string = result
            state.hash = result
            state.is_alert = true
        }
    }
    
    private func reset() {
        state.host = ""
        state.password = ""
    }
}
