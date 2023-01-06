//
//  HowTo.swift
//  CarTube
//
//  Created by Rory Madden on 6/1/2023.
//

import SwiftUI

struct HowTo: View {
    
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Form {
            List {
                Section {
                    Text("CarTube requires your phone screen to be on at all times. But don't worry, it takes care of this itself.\n\nCarTube will keep your phone screen on with your Lock Screen dimmed while it's running, and will let you know if there's anything you need to do.\n\nFor example, if you get in your car, plug in your phone, and start CarTube, it will ask you once to tap your phone to wake the screen, but that's all you'll have to do - CarTube will keep the Lock Screen on and dimmed indefinitely so you can enjoy YouTube uninterrupted.")
                }
                Section {
                    Button("View Source on GitHub") {
                        openURL(URL(string: "https://github.com/Avangelista/CarTube")!)
                    }
                    Button("Donate to Avangelista") {
                        openURL(URL(string: "https://ko-fi.com/avangelista")!)
                    }
                }
            }
        }.navigationBarTitle("How to Use", displayMode: .inline)
    }
}

struct HowTo_Previews: PreviewProvider {
    static var previews: some View {
        HowTo()
    }
}
