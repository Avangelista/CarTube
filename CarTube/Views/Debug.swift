//
//  Debug.swift
//  CarTube
//
//  Created by Rory Madden on 6/1/2023.
//

import SwiftUI

struct Debug: View {
    var body: some View {
        Form {
            List {
                Section {
                    Button("Go Back in Browser") {
                        CarPlaySingleton.shared.goBack()
                    }
                    Button("Restart Browser") {
                        CarPlaySingleton.shared.goHome()
                    }
                    Button("Toggle CarPlay Keyboard") {
                        CarPlaySingleton.shared.toggleKeyboard()
                    }
                    Button("Hide Bugged Keyboard Bar") {
                        UIApplication.shared.alert(title: "Done", body: "Bugged keyboard bar hidden (hopefully).", window: .carPlay)
                    }
                }
            }
        }.navigationBarTitle("Debug", displayMode: .inline)
    }
}

struct Debug_Previews: PreviewProvider {
    static var previews: some View {
        Debug()
    }
}
