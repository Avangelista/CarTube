//
//  KeyboardView.swift
//  CarTube
//
//  Created by Rory Madden on 1/1/2023.
//

import SwiftUI

enum KeyboardMode {
    case letters
    case symbols1
    case symbols2
}

// Keyboard Button
struct KBBtn: View {
    var label: String?
    var image: Image?
    var maxWidth: CGFloat?
    var action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            if label != nil {
                Text(label!).frame(maxWidth: maxWidth ?? .infinity, maxHeight: .infinity).background(Color.black).border(Color(UIColor.init(hue: 0, saturation: 0, brightness: 0.2, alpha: 1.0)))
            } else if image != nil {
                image!.frame(maxWidth: maxWidth ?? .infinity, maxHeight: .infinity).background(Color.black).border(Color(UIColor.init(hue: 0, saturation: 0, brightness: 0.2, alpha: 1.0)))
            }
        }.buttonStyle(PlainButtonStyle())
    }
}

struct KeyboardView: View {
    var width: CGFloat = 720
    
    @State private var mode: KeyboardMode = .letters
    @State private var shifted: Bool = false
    
    func shift() {
        shifted = !shifted
    }
    
    func setKeyboardMode(_ mode: KeyboardMode) {
        self.mode = mode
    }
    
    func sendKey(key: String) {
        CarPlaySingleton.shared.sendInput(shifted ? key.uppercased() : key)
    }
    
    func backspace() {
        CarPlaySingleton.shared.backspaceInput()
    }
    
    func dismiss() {
        CarPlaySingleton.shared.toggleKeyboard()
    }
    
    func MakeKBBtn(label: String? = nil, image: Image? = nil, maxWidth: CGFloat? = nil, action: (() -> Void)? = nil) -> KBBtn {
        return KBBtn(label: shifted ? label?.uppercased() : label, image: image, maxWidth: maxWidth, action: action ?? { sendKey(key: label != nil ? label! : "") })
    }
    
    var body: some View {
        if mode == .letters {
            VStack (spacing: 0) {
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
                    MakeKBBtn(image: shifted ? Image(systemName: "shift.fill") : Image(systemName: "shift"), maxWidth: width / 9, action: { shift() })
                    MakeKBBtn(label: "z")
                    MakeKBBtn(label: "x")
                    MakeKBBtn(label: "c")
                    MakeKBBtn(label: "v")
                    MakeKBBtn(label: "b")
                    MakeKBBtn(label: "n")
                    MakeKBBtn(label: "m")
                    MakeKBBtn(image: Image(systemName: "delete.left"), maxWidth: width / 9, action: { backspace() })
                }
                HStack(spacing: 0) {
                    MakeKBBtn(image: Image(systemName: "textformat.123"), maxWidth: width / 9, action: { setKeyboardMode(.symbols1) })
                    MakeKBBtn(image: Image(systemName: "space"), action: { sendKey(key:" ") })
                    MakeKBBtn(image: Image(systemName: "keyboard.chevron.compact.down"), maxWidth: width / 9, action: { dismiss() })
                }
            }
        } else if mode == .symbols1 {
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
                    MakeKBBtn(label: "-")
                    MakeKBBtn(label: "/")
                    MakeKBBtn(label: ":")
                    MakeKBBtn(label: ";")
                    MakeKBBtn(label: "(")
                    MakeKBBtn(label: ")")
                    MakeKBBtn(label: "$")
                    MakeKBBtn(label: "&")
                    MakeKBBtn(label: "@")
                    MakeKBBtn(label: "\"")
                }
                HStack(spacing: 0) {
                    MakeKBBtn(image: Image(systemName: "number.square"), maxWidth: width / 9, action: { setKeyboardMode(.symbols2) })
                    MakeKBBtn(label: ".")
                    MakeKBBtn(label: ",")
                    MakeKBBtn(label: "?")
                    MakeKBBtn(label: "!")
                    MakeKBBtn(label: "'")
                    MakeKBBtn(image: Image(systemName: "delete.left"), maxWidth: width / 9, action: { backspace() })
                }
                HStack(spacing: 0) {
                    MakeKBBtn(image: Image(systemName: "abc"), maxWidth: width / 9, action: { setKeyboardMode(.letters) })
                    MakeKBBtn(image: Image(systemName: "space"), action: { sendKey(key:" ") })
                    MakeKBBtn(image: Image(systemName: "keyboard.chevron.compact.down"), maxWidth: width / 9, action: { dismiss() })
                }
            }
        } else if mode == .symbols2 {
            VStack (spacing: 0) {
                HStack(spacing: 0) {
                    MakeKBBtn(label: "[")
                    MakeKBBtn(label: "]")
                    MakeKBBtn(label: "{")
                    MakeKBBtn(label: "}")
                    MakeKBBtn(label: "#")
                    MakeKBBtn(label: "%")
                    MakeKBBtn(label: "^")
                    MakeKBBtn(label: "*")
                    MakeKBBtn(label: "+")
                    MakeKBBtn(label: "=")
                }
                HStack(spacing: 0) {
                    MakeKBBtn(label: "_")
                    MakeKBBtn(label: "\\")
                    MakeKBBtn(label: "|")
                    MakeKBBtn(label: "~")
                    MakeKBBtn(label: "<")
                    MakeKBBtn(label: ">")
                    MakeKBBtn(label: "£")
                    MakeKBBtn(label: "€")
                    MakeKBBtn(label: "¥")
                    MakeKBBtn(label: "•")
                }
                HStack(spacing: 0) {
                    MakeKBBtn(image: Image(systemName: "textformat.123"), maxWidth: width / 9, action: { setKeyboardMode(.symbols1) })
                    MakeKBBtn(label: ".")
                    MakeKBBtn(label: ",")
                    MakeKBBtn(label: "?")
                    MakeKBBtn(label: "!")
                    MakeKBBtn(label: "'")
                    MakeKBBtn(image: Image(systemName: "delete.left"), maxWidth: width / 9, action: { backspace() })
                }
                HStack(spacing: 0) {
                    MakeKBBtn(image: Image(systemName: "abc"), maxWidth: width / 9, action: { setKeyboardMode(.letters) })
                    MakeKBBtn(image: Image(systemName: "space"), action: { sendKey(key:" ") })
                    MakeKBBtn(image: Image(systemName: "keyboard.chevron.compact.down"), maxWidth: width / 9, action: { dismiss() })
                }
            }
        }
    }
}

struct KeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardView()
    }
}
