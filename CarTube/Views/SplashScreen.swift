//
//  SplashScreen.swift
//  CarTube
//
//  Created by Rory Madden on 21/1/2023.
//

import SwiftUI

struct SplashScreen: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Image("cartube")
                Spacer()
            }
            Text("CarTube").fontWeight(.bold).font(.system(size: 20))
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")").fontWeight(.light).font(.system(size: 12))
            Text("Avangelista").fontWeight(.light).font(.system(size: 12))
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
