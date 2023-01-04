//
//  KeyboardView.swift
//  CarTube
//
//  Created by Rory Madden on 1/1/2023.
//

import SwiftUI

// Keyboard Button
struct KBBtn: View {
    var label: String?
    var image: Image?
    var action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            if label != nil {
                Text(label!).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black).border(Color(UIColor.init(hue: 0, saturation: 0, brightness: 0.2, alpha: 1.0)))
            } else if image != nil {
                image!.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black).border(Color(UIColor.init(hue: 0, saturation: 0, brightness: 0.2, alpha: 1.0)))
            }
        }.buttonStyle(PlainButtonStyle())
    }
}

struct KeyboardView: View {
    @State private var shifted: Bool = false
    
    func shift() {
        shifted = !shifted
    }
    
    func sendKey(key: String) {
        CarPlaySingleton.shared.sendInput(input: shifted ? key.uppercased() : key)
    }
    
    func backspace() {
        CarPlaySingleton.shared.backspaceInput()
    }
    
    func MakeKBBtn(label: String? = nil, image: Image? = nil, action: (() -> Void)? = nil) -> KBBtn {
        return KBBtn(label: shifted ? label?.uppercased() : label, image: image, action: action ?? { sendKey(key: label != nil ? label! : "") })
    }
    
    var body: some View {
        
        VStack (spacing: 0) {
            HStack(spacing: 0) {
                MakeKBBtn(label: "1")
                MakeKBBtn(label: "2")
                MakeKBBtn(label: "3")
                MakeKBBtn(label: "4")
                MakeKBBtn(label: "5")
                MakeKBBtn(label: "6")
                MakeKBBtn(label: "7")
                MakeKBBtn(label: "8")
                MakeKBBtn(label: "9")
                MakeKBBtn(label: "0")
            }
            HStack(spacing: 0) {
                MakeKBBtn(label: "q")
                MakeKBBtn(label: "w")
                MakeKBBtn(label: "e")
                MakeKBBtn(label: "r")
                MakeKBBtn(label: "t")
                MakeKBBtn(label: "y")
                MakeKBBtn(label: "u")
                MakeKBBtn(label: "i")
                MakeKBBtn(label: "o")
                MakeKBBtn(label: "p")
            }
            HStack(spacing: 0) {
                MakeKBBtn(label: "a")
                MakeKBBtn(label: "s")
                MakeKBBtn(label: "d")
                MakeKBBtn(label: "f")
                MakeKBBtn(label: "g")
                MakeKBBtn(label: "h")
                MakeKBBtn(label: "j")
                MakeKBBtn(label: "k")
                MakeKBBtn(label: "l")
            }
            HStack(spacing: 0) {
                MakeKBBtn(image: shifted ? Image(systemName: "shift.fill") : Image(systemName: "shift"), action: { shift() })
                MakeKBBtn(label: "z")
                MakeKBBtn(label: "x")
                MakeKBBtn(label: "c")
                MakeKBBtn(label: "v")
                MakeKBBtn(label: "b")
                MakeKBBtn(label: "n")
                MakeKBBtn(label: "m")
                MakeKBBtn(image: Image(systemName: "delete.left"), action: { backspace() })
            }
            HStack(spacing: 0) {
                MakeKBBtn(image: Image(systemName: "space"), action: { sendKey(key:" ") })
            }
        }
    }
}

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardView()
    }
}
