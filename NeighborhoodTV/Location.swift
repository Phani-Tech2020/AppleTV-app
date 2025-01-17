//
//  Location.swift
//  NeighborhoodTV
//
//  Created by fulldev on 1/21/23.
//

import SwiftUI
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Color {
    static let titleBack =  Color(red: 61/255, green: 57/255, blue: 58/255)
    static let infoMenuColor = Color(red: 47/255, green: 43/255, blue: 44/255)
    static let infoFocusColor = Color(red: 78/255, green: 73/255, blue: 78/255)
    static let sideBarBack = Color(red: 42/255, green: 37/255, blue: 38/255, opacity: 0.7)
    static let sideBarCollapseBack = Color(red: 21/255, green: 71/255, blue: 122/255)
}

struct GridLocationItem: View {
    var locationItem: LocationModel
    @State var isLocationItemFocused = false
    @State var locationHomeSubURI:String = ""
    @State var locationPlayURI:String = ""
    @State var locationAccessKey:String = ""
    @State var apiBaseURL:String = ""
    @State var accessToken:String = ""
    @Binding var locationCurrentVideoPlayURL:String
    @Binding var locationAllMediaItems:[MediaListType]
    @Binding var locationCurrentVideoTitle:String
    @Binding var isLocationVisible:Bool
    @Binding var isLoadingVisible:Bool
    @Binding var sideBarDividerFlag:Bool
    @Binding var isLocationPreviewVideoStatus:Bool
    @Binding var isCollapseSideBar:Bool
    @FocusState var isLocationDefaultFocus:Bool
    
    let pub_default_focus = NotificationCenter.default.publisher(for: NSNotification.Name.locationDefaultFocus)
    
    var body: some View {
        HStack {
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: "\(locationItem.thumbnailUrl)")) { imageItem in
                    imageItem
                        .resizable()
                        .scaledToFit()
                        .frame(width: 360, height: 200)
                        .clipped()
                        .cornerRadius(25)
                } placeholder: {
                    placeholderLocationItemImage()
                        .frame(width: 360, height: 200)
                }
                
                Text("\(locationItem.title)")
                    .foregroundColor(.white)
                    .font(.custom("Arial Round MT Bold", fixedSize: 20))
                    .frame(width: 360, height: 30)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(Color.titleBack)
            }
            .cornerRadius(25)
            .overlay(RoundedRectangle(cornerRadius: 25).stroke(.white, lineWidth: (isLocationItemFocused ? 8 : 2)))
        }
        .scaleEffect(isLocationItemFocused ? 1.1 : 1)
        .focusable(isCollapseSideBar ? false : true) {newState in isLocationItemFocused = newState}
        .animation(.easeInOut, value: isLocationItemFocused)
        .focused($isLocationDefaultFocus)
        .onAppear() {
            sideBarDividerFlag = false
            PlayerInstance.shared.stopPlayer()

            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if locationItem.locationItemIndex == 1 {
                    self.isLocationDefaultFocus = true
                }
            }
        }
        .onReceive(pub_default_focus) { (out_location_default) in
            guard let _out_location_default = out_location_default.object as? Bool else {
                print("Invalid URL")
                return
            }
            if _out_location_default {
                if locationItem.locationItemIndex == 1 {
                    self.isLocationDefaultFocus = true
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.001, perform: {onLocationItem()})
    }
    
    func placeholderLocationItemImage() ->  some View {
        Image(systemName: "image")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 360, height: 200)
            .foregroundColor(.gray)
            .cornerRadius(25)
    }
    
    func onLocationItem() {
        isLoadingVisible = true
        locationAllMediaItems = []
        do {
            guard let _locationHomeSubURI = locationItem.uri as? String else {
                print("Invalid URI")
                return
            }
            
            locationCurrentVideoTitle = locationItem.title
            locationHomeSubURI = _locationHomeSubURI
            
            locationLoadMediaItem()
        } catch {
            print("Error: Trying to convert JSON data to string", error)
            return
        }
    }
    
    func locationLoadMediaItem() {
        do {
            guard let _accessToken = UserDefaults.standard.object(forKey: "accessToken") as? String else {
                print("Invalid access token")
                return
            }
            
            accessToken = _accessToken
            
            guard let _apiBaseURL = UserDefaults.standard.object(forKey: "api_base_url") as? String else {
                print("Invalid apiBaseURL")
                return
            }
            
            apiBaseURL = _apiBaseURL
            
            guard let locationMediaListParseURL = URL(string: apiBaseURL.appending(locationHomeSubURI)) else {
                print("Invalid URL...")
                return
            }
            
            var locationMediaListRequest = URLRequest(url: locationMediaListParseURL)
            locationMediaListRequest.httpMethod = "POST"
            locationMediaListRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            locationMediaListRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            locationMediaListRequest.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            locationMediaListRequest.httpBody = jsonDefaultData
            
            URLSession.shared.dataTask(with: locationMediaListRequest) { data, response, error in
                guard error == nil else {
                    print("Error: error calling POST")
                    print(error!)
                    return
                }
                guard let data = data else {
                    print("Error: Did not receive data")
                    return
                }
                let _response = response as? HTTPURLResponse
                if (200 ..< 299) ~= _response!.statusCode {
                    print("Success: HTTP request ")
                } else {
                    print("Error: HTTP request failed")
                    getRefreshToken()
                }
                do {
                    guard let jsonLocationMediaListObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("Error: Cannot convert data to jsonMediaListObject object")
                        return
                    }
                    
                    guard let jsonLocationMediaListResults = jsonLocationMediaListObject["results"] as? [String: Any] else {
                        print("Error: Cannot convert data to jsonMediaListResults object")
                        return
                    }
                    
                    UserDefaults.standard.set(jsonLocationMediaListResults["retrieve_uri"], forKey: "retrieve_uri")
                    
                    guard let jsonLocationMediaListItems = jsonLocationMediaListResults["items"] as? [[String: Any]] else {
                        print("Error: Cannot convert data to jsonMediaListItems object")
                        return
                    }
                    
                    guard let jsonLocationMediaListLocation = jsonLocationMediaListResults["location"] as? [String: Any] else {
                        print("Error: Cannot convert data to jsonMediaListLocation object")
                        return
                    }
                    
                    
                    UserDefaults.standard.set(jsonLocationMediaListLocation["access_key"], forKey: "access_key")
                    UserDefaults.standard.set(jsonLocationMediaListResults["retrieve_uri"], forKey: "retrieve_uri")
                    UserDefaults.standard.set(jsonLocationMediaListLocation["title"], forKey: "original_title")
                    UserDefaults.standard.set(jsonLocationMediaListLocation["play_uri"], forKey: "play_uri")
                    
                    
                    for item in jsonLocationMediaListItems {
                        let mediaListItems: MediaListType = MediaListType(itemIndex: locationAllMediaItems.count + 1,
                                                                          _id: item["_id"] as! String,
                                                                          title: item["title"] as! String,
                                                                          description: item["description"] as! String,
                                                                          thumbnailUrl: item["thumbnailUrl"] as! String,
                                                                          duration: item["duration"] as! Int,
                                                                          play_uri: item["play_uri"] as! String,
                                                                          access_key: item["access_key"] as! String
                        )
                        locationAllMediaItems.append(mediaListItems)
                    }
                    locationPreviewVideo()
                    
                } catch {
                    print("Error: Trying to convert JSON data to string", error)
                    return
                }
            }.resume()
            
        } catch {
            print("Error: Trying to convert JSON data to string", error)
            return
        }
    }
    
    func locationPreviewVideo() {
        do {
            guard let _playURI = UserDefaults.standard.object(forKey: "play_uri") as? String else {
                print("Invalid playURI")
                return
            }
            
            guard let _accessKey = UserDefaults.standard.object(forKey: "access_key") as? String else {
                print("Invalid accessKey")
                return
            }
            
            locationPlayURI = _playURI
            locationAccessKey = _accessKey
            
            guard let locationPreviewVideoParseURL = URL(string: apiBaseURL.appending(locationPlayURI)) else {
                print("Invalid URL")
                return
            }
            
            let accessKeyDataModel = AccessKeyData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType, access_key: locationAccessKey,zipcode: zip_code)
            let jsonAccessKeyData = try? JSONEncoder().encode(accessKeyDataModel)
            
            var locationPreviewVideoRequest = URLRequest(url: locationPreviewVideoParseURL)
            locationPreviewVideoRequest.httpMethod = "POST"
            locationPreviewVideoRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            locationPreviewVideoRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            locationPreviewVideoRequest.httpBody = jsonAccessKeyData
            locationPreviewVideoRequest.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: locationPreviewVideoRequest) {data, response, error in
                guard error == nil else {
                    print("Error: error calling POST")
                    print(error!)
                    return
                }
                guard let data = data else {
                    print("Error: Did not receive data")
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
                    guard let jsonLocationPreviewVideoObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                        return
                    }
                    
                    guard let jsonLocationPreviewVideoResults = jsonLocationPreviewVideoObject["results"] as? [String: Any] else {
                        print("Error: Cannot convert data to jsonPreviewVideoResults object")
                        return
                    }
                    
                    guard let _currentVideoPlayURL = jsonLocationPreviewVideoResults["uri"] as? String else {
                        print("Invalid uri")
                        return
                    }
                    
                    UserDefaults.standard.set(1, forKey: "current_is_live")
                    UserDefaults.standard.set(jsonLocationPreviewVideoResults["is_live"], forKey: "origin_is_live")
                    UserDefaults.standard.set(jsonLocationPreviewVideoResults["manage_trp"], forKey: "origin_manage_trp")
                    
                    guard let jsonLocationPreviewVideoTRP = jsonLocationPreviewVideoResults["trp"] as? [String: Any] else {
                        print("Error: Cannot convert data to jsonPreviewVideoResults object")
                        return
                    }

                    UserDefaults.standard.set(jsonLocationPreviewVideoTRP["uri"], forKey: "origin_trp_uri")
                    UserDefaults.standard.set(jsonLocationPreviewVideoTRP["intervel_sec"], forKey: "origin_intervel_sec")
                    UserDefaults.standard.set(jsonLocationPreviewVideoTRP["access_key"], forKey: "origin_trp_access_key")
                    
                    UserDefaults.standard.set(locationItem.thumbnailUrl, forKey: "currentthumbnailUrl")

                                        locationCurrentVideoPlayURL = _currentVideoPlayURL
//                    locationCurrentVideoPlayURL = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
                    
                    UserDefaults.standard.set(locationCurrentVideoPlayURL, forKey: "original_uri")
                //    UserDefaults.standard.set(locationCurrentVideoPlayURL, forKey: "original_uri_update")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .dataDidFlow, object: locationCurrentVideoPlayURL)
                    }
                    isLocationVisible = false
                    isLoadingVisible = false
                    isLocationPreviewVideoStatus = false
                } catch {
                    print("Error: Trying to convert JSON data to string", error)
                    return
                }
            }.resume()
        } catch  {
            print("Error: Trying to convert JSON data to string", error)
            return
        }
    }
    
}

struct Location: View {
    @State var locationCurrentVideoPlayURL:String = ""
    @State var isLocationFullScreenBtnClicked:Bool = false
    @State var locationCurrentVideoTitle:String = ""
    @State var isLocationCornerScreenFocused:Bool = true
    @State var locationCurrentVideoDescription:String = ""
    @State var isLocationPreviewVideoStatus:Bool = false
    @State var isLocationVideoSectionFocused = false
    @State var isPresentingAlert:Bool = false
    
    @Binding var allLocationItems:[LocationModel]
    @Binding var sideBarDividerFlag:Bool
    @Binding var isLocationVisible:Bool
    @Binding var isCollapseSideBar:Bool
    
    @State var locationAllMediaItems:[MediaListType] = []
    @State var isLocationTitleFocused = false
    @State var isLoadingVisible = false
    
    let pu_player_stop = NotificationCenter.default.publisher(for: NSNotification.Name.pub_player_stop)
    let locationColumns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        if self.isLocationVisible {
            ZStack {
                VStack {
                    Text("Choose Location below")
                        .foregroundColor(.white)
                        .font(.custom("Arial Round MT Bold", fixedSize: 30))
                        .frame(width: 360, height: 30)
                        .padding(.bottom, 10)
                    
                    LazyVGrid(columns: locationColumns) {
                        ForEach(allLocationItems, id:\._id) { locationItem in
                            GridLocationItem(
                                locationItem:locationItem,
                                locationCurrentVideoPlayURL:$locationCurrentVideoPlayURL,
                                locationAllMediaItems:$locationAllMediaItems,
                                locationCurrentVideoTitle:$locationCurrentVideoTitle,
                                isLocationVisible:$isLocationVisible,
                                isLoadingVisible:$isLoadingVisible,
                                sideBarDividerFlag:$sideBarDividerFlag,
                                isLocationPreviewVideoStatus:$isLocationPreviewVideoStatus,
                                isCollapseSideBar:$isCollapseSideBar
                            )
                        }
                    }.frame(width: 1500)
                }
                .opacity((isLoadingVisible ? 0.1 : 1))
                
                if isLoadingVisible {
                    Loading()
                }
                
            }
        } else {
            HStack {
                /* ------------------ MainContent --------------------- */
                VStack(alignment: .leading) {
                    if !isLocationPreviewVideoStatus {
                        VStack {
                            Home(
                                currentVideoTitle:$locationCurrentVideoTitle,
                                isFullScreenBtnClicked: $isLocationFullScreenBtnClicked,
                                isPreviewVideoStatus: $isLocationPreviewVideoStatus,
                                isCollapseSideBar:$isCollapseSideBar,
                                isVideoSectionFocused:$isLocationVideoSectionFocused,
                                isCornerScreenFocused:$isLocationCornerScreenFocused
                            )
                            .onReceive(pu_player_stop) {(oPu_player_stop) in
                                guard let _oPub_player_stop = oPu_player_stop.object as? Bool else {
                                    print("Invalid URL")
                                    return
                                }
                                
                                if _oPub_player_stop {
                                    isLocationPreviewVideoStatus = true
                                }
                            }
                            .onExitCommand(perform: {
                                isLocationVisible = true
                                
                            })
                        }
                    } else {
                        if !isLocationCornerScreenFocused {
                            VStack {
                                Description(
                                    currentVideoPlayURL:$locationCurrentVideoPlayURL,
                                    isFullScreenBtnClicked: $isLocationFullScreenBtnClicked,
                                    isCornerScreenFocused: $isLocationCornerScreenFocused,
                                    currentVideoTitle:$locationCurrentVideoTitle,
                                    currentVideoDescription: $locationCurrentVideoDescription,
                                    isVideoSectionFocused: $isLocationVideoSectionFocused,
                                    isPreviewVideoStatus: $isLocationPreviewVideoStatus,
                                    isCollapseSideBar:$isCollapseSideBar
                                )
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("\( !isLocationCornerScreenFocused ? "Related Videos" : "The Latest")")
                        if isLocationCornerScreenFocused {
                            Divider()
                                .focusable(isLocationPreviewVideoStatus ? true : false) {newState in isLocationTitleFocused = newState; onLocationUpButtonToHome() }
                        }
                        else {
                            Divider()
                                .focusable( !isLocationVideoSectionFocused ? true : false ) { newState in isLocationTitleFocused = newState ; isLocationVideoSectionFocused = true  }
                        }
                        
                        MediaList(
                            allMediaItems:$locationAllMediaItems,
                            isPreviewVideoStatus : $isLocationPreviewVideoStatus,
                            isCornerScreenFocused:$isLocationCornerScreenFocused,
                            currentVideoTitle:$locationCurrentVideoTitle,
                            currentVideoDescription:$locationCurrentVideoDescription,
                            currentVideoPlayURL:$locationCurrentVideoPlayURL,
                            isVideoSectionFocused:$isLocationVideoSectionFocused,
                            isPresentingAlert:$isPresentingAlert,
                            isCollapseSideBar:$isCollapseSideBar
                        )
                    }
                    .onExitCommand(perform: {
                        if !self.isLocationCornerScreenFocused {
                            isLocationVideoSectionFocused = true
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: .locationDefaultFocus, object: isLocationVideoSectionFocused)
                            }
                        } else {
                            onLocationUpButtonToHome()
                        }
                    })
                    .frame(width: 1500, height: (isLocationPreviewVideoStatus ? isLocationCornerScreenFocused ?  960 : 500 : 200))
                    .opacity((!isLocationFullScreenBtnClicked ? 1 : 0))
                }
            }
            .alert("Try again later", isPresented: $isPresentingAlert){}
            .background(Image("bg_full")
                .resizable()
                .frame(width: 1920, height: 1080, alignment: .center))
            
        }
    }
    
    func onLocationUpButtonToHome() {
        guard let _originalVideoPlayURL = UserDefaults.standard.object(forKey: "original_uri") as? String else {
            print("Invalid URL")
            return
        }
        
//        guard let _originalVideoPlayURL = UserDefaults.standard.object(forKey: "original_uri_update") as? String else {
//            print("Invalid URL")
//            return
//        }
 
        
        guard let _originalVideoTitle = UserDefaults.standard.object(forKey: "original_title") as? String else {
            print("Invalid Title")
            return
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .dataDidFlow, object: _originalVideoPlayURL)
        }
        
        locationCurrentVideoTitle = _originalVideoTitle
        locationAllMediaItems = locationAllMediaItems
        locationCurrentVideoPlayURL = _originalVideoPlayURL
        isLocationPreviewVideoStatus = false
    }
}
