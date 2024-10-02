//
//  BottomBorder.swift
//  pwdhash
//
//  Created by Руслан Штыбаев on 02.10.2024.
//

import SwiftUI

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
