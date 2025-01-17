//
//  Loading.swift
//  NeighborhoodTV
//
//  Created by fulldev on 2/5/23.
//

import Foundation
import SwiftUI
import AVKit

struct Loading: View {
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            ZStack {
                Text("Loading...")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .offset(x: 0, y: -25)
                    .padding(.bottom, 10)
                
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color(.gray), lineWidth: 3)
                    .frame(width: 400, height: 10)
                
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 50, height: 10)
                    .offset(x: isLoading ? 110 : -110, y : 0)
                    .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false))
            }.onAppear(){
                self.isLoading = true
            }
        }
    }
}

//struct Loading_Previews: PreviewProvider {
//    static var previews: some View {
//      //  ContentView()
//        SplashScreen()
//    }
//}
