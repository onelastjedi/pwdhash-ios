//
//  View+ext.swift
//  pwdhash
//
//  Created by Руслан Штыбаев on 02.10.2024.
//

import SwiftUI

extension View {
    func bottomBorder() -> some View {
        self.modifier(BottomBorder())
    }
}
