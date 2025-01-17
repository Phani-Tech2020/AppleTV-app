//
//  ContentView.swift
//  NeighborhoodTV
//
//  Created by fulldev on 1/20/23.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @Binding var currentVideoPlayURL:String
    @Binding var allMediaItems:[MediaListType]
    @Binding var allLocationItems:[LocationModel]
    @Binding var currentVideoTitle:String
    
    @State var isFullScreenBtnClicked = false
    @State var isPreviewVideoStatus = false {
        didSet {
            print("Sucharu", isPreviewVideoStatus)
        }
    }
    @State var isCornerScreenFocused = true {
        didSet {
            print("Sucharu", isCornerScreenFocused)
        }
    }
    @State var isTitleFocused = false
    @State var isVideoSectionFocused = false
    
    @State var isLocationItemFocused:Int = 0
    @State var currentVideoDescription:String =  (UserDefaults.standard.object(forKey: "currentVideoDescription") as? String ?? "")
    @State private var isPresentingAlert: Bool = false
    @State var isCollapseSideBar:Bool = false
    @State var sideBarDividerFlag:Bool = false
    @State var isLocationVisible:Bool = true
    @State var isSideBarVisible:Bool = false
    
    let pu_player_stop = NotificationCenter.default.publisher(for: NSNotification.Name.pub_player_stop)
    
    let pub_sidebar = NotificationCenter.default.publisher(for: NSNotification.Name.onFullBtnAction)
    var body: some View {
        ZStack {
            VStack {
                switch self.isLocationItemFocused {
                case 1:
                    Location(
                        allLocationItems:$allLocationItems,
                        sideBarDividerFlag:$sideBarDividerFlag,
                        isLocationVisible:$isLocationVisible,
                        isCollapseSideBar:$isCollapseSideBar
                    )
                    .onExitCommand() {
                        exit(0)
                    }
                case 2:
                    Information(
                        sideBarDividerFlag:$sideBarDividerFlag,
                        isCollapseSideBar:$isCollapseSideBar
                    )
                    .onExitCommand() {
                        exit(0)
                    }
                    case 3:
                        DashBoardAlertView(
                            sideBarDividerFlag: $sideBarDividerFlag,
                            isCollapseSideBar: $isCollapseSideBar,
                            isPreviewVideoStatus: $isPreviewVideoStatus,
                            isLocationItemFocused:$isLocationItemFocused,
                            currentVideoPlayURL:$currentVideoPlayURL,
                            allMediaItems:$allMediaItems,
                            allLocationItems:$allLocationItems,
                            currentVideoTitle:$currentVideoTitle
                         )
                        .background(Image("bg_full_2"))
                        .onExitCommand() {
                            exit(0)
                        }
                default:
                    HStack {
                        /* ------------------ MainContent --------------------- */
                        VStack {
                            if !self.isPreviewVideoStatus {
                                VStack {
                                    Home(
                                        currentVideoTitle:$currentVideoTitle,
                                        isFullScreenBtnClicked: $isFullScreenBtnClicked,
                                        isPreviewVideoStatus:$isPreviewVideoStatus,
                                        isCollapseSideBar:$isCollapseSideBar,
                                        isVideoSectionFocused:$isVideoSectionFocused,
                                        isCornerScreenFocused:$isCornerScreenFocused
                                    ).onReceive(pu_player_stop) {(oPu_player_stop) in
                                        guard let _oPub_player_stop = oPu_player_stop.object as? Bool else {
                                            print("Invalid URL")
                                            return
                                        }
                                        
                                        if _oPub_player_stop {
                                            isPreviewVideoStatus = true
                                        }
                                    }.onDisappear() {
                                        
                                    }
                                    .onExitCommand() {
                                        exit(0)
                                    }
                                }
                            } else if !self.isCornerScreenFocused {
                                VStack {
                                    Description(
                                        currentVideoPlayURL:$currentVideoPlayURL,
                                        isFullScreenBtnClicked: $isFullScreenBtnClicked,
                                        isCornerScreenFocused: $isCornerScreenFocused,
                                        currentVideoTitle:$currentVideoTitle,
                                        currentVideoDescription: $currentVideoDescription,
                                        isVideoSectionFocused:$isVideoSectionFocused,
                                        isPreviewVideoStatus:$isPreviewVideoStatus,
                                        isCollapseSideBar:$isCollapseSideBar
                                    )
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text("\( !self.isCornerScreenFocused ? "Related Videos" : "The Latest")")
                                
                                if isCornerScreenFocused {
                                    Divider()
                                        .focusable(isPreviewVideoStatus ? isCollapseSideBar ? false : true : false) {
                                            newState in isTitleFocused = newState; onUpButtonToHome()
                                            
                                        }
                                }
                                else {
                                    Divider()
                                        .focusable( !isVideoSectionFocused ? isCollapseSideBar ? false : true : false ) {
                                            newState in isTitleFocused = newState ; isVideoSectionFocused = true
                                            
                                        }
                                }
                                MediaList(
                                    allMediaItems:$allMediaItems,
                                    isPreviewVideoStatus : $isPreviewVideoStatus,
                                    isCornerScreenFocused:$isCornerScreenFocused,
                                    currentVideoTitle:$currentVideoTitle,
                                    currentVideoDescription:$currentVideoDescription,
                                    currentVideoPlayURL:$currentVideoPlayURL,
                                    isVideoSectionFocused:$isVideoSectionFocused,
                                    isPresentingAlert:$isPresentingAlert,
                                    isCollapseSideBar:$isCollapseSideBar
                                )
                            }
                            .onExitCommand(perform: {
                                if !self.isCornerScreenFocused {
                                    isVideoSectionFocused = true
                                    DispatchQueue.main.async {
                                        NotificationCenter.default.post(name: .locationDefaultFocus, object: isVideoSectionFocused)
                                    }
                                } else {onUpButtonToHome()}
                            })
                            .frame(width: 1500, height: (isPreviewVideoStatus ? isCornerScreenFocused ?  960 : 500 : 200))
                            .opacity( (!isFullScreenBtnClicked ? 1 : 0))
                        }
                    }
                    .alert("Try again later", isPresented: $isPresentingAlert){}
                    .background(Image("bg_full")
                        .resizable()
                        .frame(width: 1920, height: 1080, alignment: .center))
                }
            }.opacity(isCollapseSideBar ? 0.1 : 1)
            
            VStack {
                SideBar(
                    isCollapseSideBar:$isCollapseSideBar,
                    isPreviewVideoStatus:$isPreviewVideoStatus,
                    isLocationItemFocused:$isLocationItemFocused,
                    currentVideoTitle:$currentVideoTitle,
                    locationAllMediaItems : $allMediaItems, sideBarDividerFlag:$sideBarDividerFlag,
                    isLocationVisible:$isLocationVisible
                )
                .frame(height: 1080)
                .opacity(isSideBarVisible ? 0 : 1)
                .onReceive(pub_sidebar) { (out_side) in
                    guard let _out_side = out_side.object as? Bool else {
                        print("Invalid URL")
                        return
                    }
                    self.isSideBarVisible = _out_side
                }
                .onExitCommand() {
                    exit(0)
                }
            }
        }
    }
    
    func onUpButtonToHome () {
        guard let _currentVideoTitle = UserDefaults.standard.object(forKey: "original_title") as? String else {
            print("Invalid Title")
            return
        }
        
        currentVideoTitle = _currentVideoTitle
        isPreviewVideoStatus = false
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .pub_player_stop, object: false)
        }
    }
    
    func popupShowZipCodeAlerta(){
        let alert = UIAlertController(title: "Forgot Password!", message: "Please enter your Email-ID", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Email-ID"
            textField.textAlignment = .center
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if textField?.text! != ""{
//                WebServices.viewcntrl = self
//                WebServices.ForgotPasswordAPI(email: (textField?.text!)!) { error in
//                    if error == nil{
//                        showAlert(title: "Please check your Inbox for the recoverd password", message: "",vc: self)
//                    }
//                }
             }
        }))
        //self.present(alert, animated: true, completion: nil)
        
        
        
        
    }
    
    
}

