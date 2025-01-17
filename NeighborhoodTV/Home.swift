//
//  Home.swift
//  NeighborhoodTV
//
//  Created by fulldev on 1/20/23.
// com.NeighborhoodTV.NeighborhoodTVOS

import SwiftUI
import AVKit
import UIKit

struct Home: View {
    @Binding var currentVideoTitle:String
    @Binding var isFullScreenBtnClicked:Bool
    @Binding var isPreviewVideoStatus:Bool
    @Binding var isCollapseSideBar:Bool
    @Binding var isVideoSectionFocused:Bool
    @Binding var isCornerScreenFocused:Bool
    
    @FocusState private var nameInfocus: Bool
    let pub_default_focus = NotificationCenter.default.publisher(for: NSNotification.Name.locationDefaultFocus)
    let puh_fullScreen = NotificationCenter.default.publisher(for: Notification.Name.puh_fullScreen)
    
    var body: some View {
        VStack{
            ZStack {
                PreviewVideo()
                    .shadow(color: .black, radius: 10)
                    .frame(width: (isFullScreenBtnClicked ? 1920 : 1500), height: (isFullScreenBtnClicked ? 1080 : 850))
                    .onExitCommand(perform: {onVideoBackButton()})
                    .padding(.top , (!isFullScreenBtnClicked ? 0 : 230) )
                    .focusable(false)
                    .onReceive(puh_fullScreen) { (outFull) in
                        guard let _outFull = outFull.object as? Bool else {
                            print("Invalid URL")
                            return
                        }
                        isFullScreenBtnClicked = _outFull
                    }
                    
                if !self.isFullScreenBtnClicked {
                    HStack {
                        VStack(alignment: .leading){
                            Spacer()
                            Text("Streaming Now - \(currentVideoTitle)")
                                .font(.custom("Arial Round MT Bold", fixedSize: 35))
                            
                            
                            Text("Watch in FullScreen").font(.custom("Arial Round MT Bold", fixedSize: 25))
                                .padding(20)
                                .padding(.horizontal, 20)
                                .background(isVideoSectionFocused ? .white : .gray)
                                .border(isVideoSectionFocused ? .white : .gray)
                                .foregroundColor(isVideoSectionFocused ? .black : .white)
                                .cornerRadius(10)
                                .focusable(isCollapseSideBar ? false : true) {newState in isVideoSectionFocused = newState }
                                .scaleEffect(isVideoSectionFocused ? 1.1 : 1)
                                .onLongPressGesture(minimumDuration: 0.001, perform: {onFullScreenBtn()})
                                .focused($nameInfocus)
                                .onAppear() {
                                    DispatchQueue.main.asyncAfter(deadline: .now()) {
                                        self.nameInfocus = true
                                        self.isCornerScreenFocused = true
                                    }
                                }
                                .onReceive(pub_default_focus) { (out_location_default) in
                                    guard let _out_location_default = out_location_default.object as? Bool else {
                                        print("Invalid URL")
                                        return
                                    }
                                    if _out_location_default {
                                        self.nameInfocus = true
                                    }
                                }
                        }
                        .opacity((isFullScreenBtnClicked ? 0 : 1))
                        .padding(35)
                        Spacer()
                    }
                }
            }
            .frame(width: 1500, height: 850)
        }
    }
    
    func onFullScreenBtn() {
        isFullScreenBtnClicked = true
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .onFullBtnAction, object: isFullScreenBtnClicked)
        }
    }
    
    func onVideoBackButton() {
        isFullScreenBtnClicked = false
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .onFullBtnAction, object: isFullScreenBtnClicked)
        }
    }
}
