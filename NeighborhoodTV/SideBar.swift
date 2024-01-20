//
//  SideBar.swift
//  NeighborhoodTV
//
//  Created by fulldev on 2/2/23.
//

import Foundation
import SwiftUI
import AVKit

struct SideBar: View {
    
    @State var isSideHomeFocus = false
    @State var isSideLocationFocus = false
    @State var isSideInfoFocus = false
    @State var isSideEditLocationFocus = false
    @State var isDividerFocus1 = false
    @State var isDividerFocus2 = false
    @State var isDividerFocus3 = false
    @State var isDividerFocus4 = false
    @State var isSideFocusState = false
    @Binding var isCollapseSideBar:Bool
    @Binding var isPreviewVideoStatus:Bool
    @Binding var isLocationItemFocused:Int
    @Binding var currentVideoTitle:String
    @Binding var locationAllMediaItems:[MediaListType]
     @Binding var sideBarDividerFlag:Bool
    @Binding var isLocationVisible:Bool
    @FocusState private var isLogoDefaultFocus:Bool
    @FocusState private var isLocationDefaultFocus:Bool
    @FocusState private var isInfoDefaultFocus:Bool
    @FocusState private var isEditLocationFocus:Bool
    let pub_isCollapseSideBar = NotificationCenter.default.publisher(for: NSNotification.Name.isCollapseSideBar)
    @State var allMediaItems:[MediaListType] = []
    @State var accessToken:String = ""
    @State var apiBaseURL:String = ""
    @State var homeSubURI:String = ""
    var body: some View {
        HStack(spacing: 1) {
            VStack {
                /*--------------------------------------*/
                Label {
                } icon: {
                    if isCollapseSideBar {
                        Image("logo").resizable().frame(width: 250, height: 50)
                    } else {
                        Image("icon").resizable().frame(width: 50, height: 50)
                    }
                }
                .padding(20)
                .background(isSideHomeFocus ? Color.gray : Color.infoMenuColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isSideFocusState ? (isSideHomeFocus == true) ? Color.white : Color.infoMenuColor : isLocationItemFocused == 0 ? Color.white : Color.infoMenuColor), lineWidth: 3)
                )
                .focusable(true) {newState in isSideHomeFocus = newState ; if newState { isSideFocusState = true} else { isSideFocusState = false}; onCollapseStatus()}
                .focused($isLogoDefaultFocus)
                .onLongPressGesture(minimumDuration: 0.001, perform: {isLocationItemFocused = 0 ; onHomeButton()})
                
                /*--------------------------------------*/
                
                Label {
                    if isCollapseSideBar {
                        VStack(alignment: .leading){
                            Text("Choose Stream").font(.custom("Arial Round MT Bold", fixedSize: 25)).padding(.leading, -25).frame(width: 150, alignment: .leading)
                        }
                        
                    }
                } icon: {
                    Image("location").resizable().frame(width: 50, height: 50)
                }
                .padding(20)
                .background(isSideLocationFocus ? Color.gray : Color.infoMenuColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isSideFocusState ? (isSideLocationFocus == true) ? Color.white : Color.infoMenuColor : isLocationItemFocused == 1 ? Color.white : Color.infoMenuColor), lineWidth: 3)
                )
                .focusable(true) {newState in isSideLocationFocus = newState; if newState { isSideFocusState = true} else { isSideFocusState = false}; onCollapseStatus() }
                .focused($isLocationDefaultFocus)
                .onLongPressGesture(minimumDuration: 0.001, perform: {onLocationButton()})
                
                
                /*--------------------------------------*/
                Label {
                    if isCollapseSideBar {
                        Text("Information").font(.custom("Arial Round MT Bold", fixedSize: 25)).padding(.leading, -25).frame(width: 150, alignment: .leading)
                    }
                } icon: {
                    Image("info").resizable().frame(width: 50, height: 50)
                }
                .padding(20)
                .background(isSideInfoFocus ? Color.gray : Color.infoMenuColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isSideFocusState ? (isSideInfoFocus == true) ? Color.white : Color.infoMenuColor : isLocationItemFocused == 2 ? Color.white : Color.infoMenuColor), lineWidth: 3)
                )
                .focusable(true) {newState in isSideInfoFocus = newState; if newState { isSideFocusState = true} else { isSideFocusState = false}; onCollapseStatus()}
                .focused($isInfoDefaultFocus)
                .onLongPressGesture(minimumDuration: 0.001, perform: {onInfoButton()})
                
                
                /*--------------------------------------*/
                Label {
                    if isCollapseSideBar {
                        Text("Edit Location").font(.custom("Arial Round MT Bold", fixedSize: 25)).padding(.leading, -25).frame(width: 150, alignment: .leading)
                    }
                } icon: {
                    Image("Edit-location").resizable().frame(width: 50, height: 50)
                }
                .padding(20)
                .background(isSideEditLocationFocus ? Color.gray : Color.infoMenuColor)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((isSideFocusState ? (isSideEditLocationFocus == true) ? Color.white : Color.infoMenuColor : isLocationItemFocused == 3 ? Color.white : Color.infoMenuColor), lineWidth: 3)
                )
                .focusable(true) {newState in isSideEditLocationFocus = newState; if newState { isSideFocusState = true} else { isSideFocusState = false}; onCollapseStatus()}
                .focused($isEditLocationFocus)
                .onLongPressGesture(minimumDuration: 0.001, perform: {onEditLocationButton()})
                
                Spacer()
            }
            .padding(.top, 50)
            .frame(width: (isCollapseSideBar ? 350 : 140 ))
            //            .background(isCollapseSideBar ? Color.sideBarCollapseBack : Color.sideBarBack)
            .background(Color.sideBarBack)
            
            if sideBarDividerFlag {
                Divider().focusable(true) {
                    newStat in isDividerFocus1 = newStat ; fromDividerToContent()
                    
                }
            } else {
                Divider().focusable(isCollapseSideBar ? false : true) { newState in isDividerFocus2 = newState; fromContentToDivider()}
            }
            
            
            Spacer()
        }.padding(.leading, -80)
    }
    
    
    
    func onCollapseStatus() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .isCollapseSideBar, object: isCollapseSideBar)
        }
    }
    
    func fromDividerToContent() {
        self.isCollapseSideBar = false
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .locationDefaultFocus, object: true)
        }
        
        sideBarDividerFlag = false
    }
    
    func fromContentToDivider() {
        switch isLocationItemFocused {
            case 0:
                self.isLogoDefaultFocus = true
            case 1:
                self.isLocationDefaultFocus = true
            case 2:
                self.isInfoDefaultFocus = true
            default:
                self.isEditLocationFocus = true
        }
        
        self.isCollapseSideBar = true
        sideBarDividerFlag = true
    }
    
    func onInfoButton() {
        isLocationItemFocused = 2
        isCollapseSideBar = false
        isPreviewVideoStatus = false
    }
    
    func onEditLocationButton() {
        isLocationItemFocused = 3
        isLocationVisible = false
        isCollapseSideBar = false
        isPreviewVideoStatus = false
          
     }
    
    
    func onHomeButton() {
        
//        guard let _currentVideoTitle = UserDefaults.standard.object(forKey: "original_title") as? String else {
//            print("Invalid Title")
//            return
//        }
//        
//        currentVideoTitle = _currentVideoTitle
        isPreviewVideoStatus = false
        isCollapseSideBar = false
//        locationAllMediaItems = locationAllMediaItems
//        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .pub_player_stop, object: false)
        }
        
        
        
     //   self.loadMediaList()
        
    }
    
    
    
    /* -----------------------MediaList------------------------ */
    func loadMediaList() {
        do {
            guard let _accessToken = UserDefaults.standard.object(forKey: "accessToken") as? String else {
                //print("Invalid access token")
                return
            }
            
            accessToken = _accessToken
            
            guard let _apiBaseURL = UserDefaults.standard.object(forKey: "api_base_url") as? String else {
                //print("Invalid apiBaseURL")
                return
            }
            
            apiBaseURL = _apiBaseURL
            
            guard let _homeSubURI = UserDefaults.standard.object(forKey: "home_sub_uri") as? String else {
                //print("Invalid homeSubURI")
                return
            }
            
            homeSubURI = _homeSubURI
            
            guard let mediaListParseURL = URL(string: apiBaseURL.appending(homeSubURI)) else {
                //print("Invalid URL...")
                return
            }
            
            var mediaListRequest = URLRequest(url: mediaListParseURL)
            mediaListRequest.httpMethod = "POST"
            mediaListRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            mediaListRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            mediaListRequest.setValue( "Bearer \(_accessToken)", forHTTPHeaderField: "Authorization")
            mediaListRequest.httpBody = jsonDefaultData
            
            URLSession.shared.dataTask(with: mediaListRequest) { data, response, error in
                guard error == nil else {
                    //print("Error: error calling POST")
                    //print(error!)
                    return
                }
                guard let data = data else {
                    //print("Error: Did not receive data")
                    return
                }
                
                let _response = response as? HTTPURLResponse
                if (200 ..< 299) ~= _response!.statusCode {
                    //print("Success: HTTP request ")
                } else {
                    //print("Error: HTTP request failed")
                    getRefreshToken()
                }
                
                do {
                    guard let jsonMediaListObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonMediaListObject object")
                        return
                    }
                    
                    guard let jsonMediaListResults = jsonMediaListObject["results"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonMediaListResults object")
                        return
                    }
                    
                    UserDefaults.standard.set(jsonMediaListResults["retrieve_uri"], forKey: "retrieve_uri")
                    
                    guard let jsonMediaListItems = jsonMediaListResults["items"] as? [[String: Any]] else {
                        //print("Error: Cannot convert data to jsonMediaListItems object")
                        return
                    }
                    
                    guard let jsonMediaListLocation = jsonMediaListResults["location"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonMediaListLocation object")
                        return
                    }
                    
                    guard let _currentVideoTitle = jsonMediaListLocation["title"] as? String else {
                        //print("Invalid Title")
                        return
                    }
                    
                    currentVideoTitle = _currentVideoTitle
                    
                    
                    UserDefaults.standard.set(jsonMediaListLocation["access_key"], forKey: "access_key")
                    UserDefaults.standard.set(jsonMediaListResults["retrieve_uri"], forKey: "retrieve_uri")
                    UserDefaults.standard.set(jsonMediaListLocation["title"], forKey: "original_title")
                    UserDefaults.standard.set(jsonMediaListLocation["play_uri"], forKey: "play_uri")
                    UserDefaults.standard.set(jsonMediaListLocation["thumbnailUrl"], forKey: "currentthumbnailUrl")
                    
                    
                    for item in jsonMediaListItems {
                        let mediaListItems: MediaListType = MediaListType(itemIndex: allMediaItems.count + 1,
                                                                          _id: item["_id"] as! String,
                                                                          title: item["title"] as! String,
                                                                          description: item["description"] as! String,
                                                                          thumbnailUrl: item["thumbnailUrl"] as! String,
                                                                          duration: item["duration"] as! Int,
                                                                          play_uri: item["play_uri"] as! String,
                                                                          access_key: item["access_key"] as! String
                        )
                        allMediaItems.append(mediaListItems)
                    }
 
                    guard let _currentVideoTitle = UserDefaults.standard.object(forKey: "original_title") as? String else {
                        print("Invalid Title")
                        return
                    }
                    
                    currentVideoTitle = _currentVideoTitle
                    isPreviewVideoStatus = false
                    isCollapseSideBar = false
                    locationAllMediaItems = allMediaItems
                     

                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .pub_player_stop, object: false)
                    }
                    
                    
                    
                } catch {
                    //print("Error: Trying to convert JSON data to string", error)
                    return
                }
            }.resume()
        } catch {
            //print("Error: Trying to convert JSON data to string", error)
            return
        }
        
        
    }
    
    
    
    func onLocationButton() {
        isLocationItemFocused = 1
        isLocationVisible = true
        isCollapseSideBar = false
        isPreviewVideoStatus = false
        
    }
}
