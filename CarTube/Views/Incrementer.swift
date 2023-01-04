//
//  Incrementer.swift
//  CarTube
//
//  Created by Rory Madden on 4/1/2023.
//

import SwiftUI

struct Incrementer: View {
    @Binding var value: Int

    var body: some View {
        HStack {
            Text("Zoom Level")
            Spacer()
            Button(action: {
                self.value -= 5
                self.value = max(self.value, 50)
            }) {
                Image(systemName: "minus.circle")
            }.buttonStyle(BorderlessButtonStyle())
            Text("\(value)%").frame(width: 50, alignment: .center)
            Button(action: {
                self.value += 5
                self.value = min(self.value, 150)
            }) {
                Image(systemName: "plus.circle")
            }.buttonStyle(BorderlessButtonStyle())
        }
    }
}
