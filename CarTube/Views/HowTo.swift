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
                    Text("Get in your car, plug in your phone, and start CarTube on CarPlay. It will ask you to tap your phone once to wake the screen, but that's all you'll have to do. Enjoy a full-feature YouTube experience in the car!\n\nUsing the app on CarPlay requires your phone screen to be on at all times. Don't worry, it'll do this automatically. CarTube will keep your phone screen on with your Lock Screen dimmed, and will let you know if there's anything else you need to do.")
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
