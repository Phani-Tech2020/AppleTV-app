//
//  AlertView.swift
//  NeighborhoodTV
//
//  Created by Phaneendra on 03/08/2023.
//

import SwiftUI
import AVKit

struct AlertView: View {
    @State private var isLoading = false
    @State private var name:String = ""
    var body: some View{
        ZStack {
            /*--------------------- splashscreen image----------------------- */
            Image("splashscreen").resizable().frame(width: 1920, height: 1080, alignment: .center)
            /*--------------------- Loading... ----------------------- */
            VStack {
                Spacer()
                    .alert("Please Provide ZIP code to get the information related to your Location.", isPresented: $isLoading) {
                        TextField("ZIP Code", text: $name)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                        Button("Proceed",action: {
                            zip_code = name
                            UserDefaults.standard.set(zip_code, forKey: "zip_code")
                             UserDefaults.standard.synchronize()
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .zip_Code_Update, object: zip_code)
                            }
                        })
                        
                    }message: {
                        Text("")
                    }
                    .padding(.bottom, 200)
            }
            
        }.onAppear(){
            self.isLoading = true
        }
        
    }
    
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//      //  ContentView()
//       // SplashScreen()
//        AlertView()
//    }
//}
