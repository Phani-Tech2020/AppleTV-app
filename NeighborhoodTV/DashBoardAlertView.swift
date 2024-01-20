//
//  DashBoardAlertView.swift
//  NeighborhoodTV
//
//  Created by Phaneendra on 10/08/2023.
//

import SwiftUI
import AVKit

struct DashBoardAlertView: View {
    @State private var isLoading = false
    @State private var name:String = ""
    @Binding var sideBarDividerFlag:Bool
    @Binding var isCollapseSideBar:Bool
    @FocusState var isEditLocationDefaultFocus:Bool
    
//    @State var allMediaItems:[MediaListType] = []
    @State var accessToken:String = ""
    @State var apiBaseURL:String = ""
    @State var homeSubURI:String = ""
    @State var playURI:String = ""
    @State var accessKey:String = ""
//   @State var currentVideoPlayURL:String = ""
  //  @State var allLocationItems:[LocationModel] = []
//    @State var currentVideoTitle:String = ""
    @Binding var isPreviewVideoStatus:Bool
    @FocusState private var isEditLocationFocus:Bool

    @State private var showingAlert = false
    @Binding var isLocationItemFocused:Int
    @Binding var currentVideoPlayURL:String
    @Binding var allMediaItems:[MediaListType]
    @Binding var allLocationItems:[LocationModel]
    @Binding var currentVideoTitle:String

    
    
    let pub_default_focus = NotificationCenter.default.publisher(for: NSNotification.Name.zip_Code_locationDefaultFocus)
    
    
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
//                            showingAlert = true
                            getToken()
                        })
                        
                    }
                    .focused($isEditLocationFocus)
                    .alert("ZIP code Updated Successfully", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) {
                            onHomeButton()
                        }
                    }
            message: {
                        Text(zip_code)
                    }
                    .padding(.bottom, 200)
                    .onReceive(pub_default_focus) { (output) in
                        guard let _objURL = output.object as? String else {
                            print("Invalid URL")
                            return
                        }
                         print(_objURL)
                        self.isEditLocationFocus = true
                    }
             }
            VStack {
                Spacer()
                Loading()
                .padding(.bottom, 200)
            }
        }.onAppear(){
            self.isLoading = true
            PlayerInstance.shared.stopPlayer()
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                     self.isEditLocationFocus = true
             }
        }
        
    }
    
    /* -----------------------GetToken------------------------ */
    func getToken() {
         
        let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playback, mode: .moviePlayback)
            }
            catch {
                //print("Setting category to AVAudioSessionCategoryPlayback failed.")
            }
        do {
            guard let tokenParseURL = URL(string: tokenURL) else {
                //print("Invalid URL")
                return
            }
            var tokenRequest = URLRequest(url: tokenParseURL)
            tokenRequest.httpMethod = "POST"
            tokenRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            tokenRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let defaultDataModel = DefaultData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType,zipcode:zip_code)
            let jsonAccessKeyData = try? JSONEncoder().encode(defaultDataModel)
            
            tokenRequest.httpBody = jsonAccessKeyData
            
            URLSession.shared.dataTask(with: tokenRequest) { data, response, error in
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
                    guard let jsonTokenObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonTokenObject object")
                        return
                    }
                    
                    guard let jsonTokenResults = jsonTokenObject["results"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonTokenResults object")
                        return
                    }
                    
                    guard let jsonTokenLocations = jsonTokenResults["locations"] as? [[String: Any]] else {
                        //print("Error: Cannot convert data to jsonMediaListItems object")
                        return
                    }
                    
                    for locationItem in jsonTokenLocations {
                        let locationItems: LocationModel = LocationModel (locationItemIndex: allLocationItems.count + 1,
                                                                          _id: locationItem["_id"] as! String,
                                                                          thumbnailUrl: locationItem["thumbnailUrl"] as! String,
                                                                          title: locationItem["title"] as! String,
                                                                          uri: locationItem["uri"] as! String)
                        allLocationItems.append(locationItems)
                    }
                    
                    UserDefaults.standard.set(jsonTokenResults["accessToken"], forKey: "accessToken")
                    UserDefaults.standard.set(jsonTokenResults["refreshToken"], forKey: "refreshToken")
                    UserDefaults.standard.set(jsonTokenResults["home_uri"], forKey: "home_sub_uri")
                    
                    guard let jsonTokenConfig = jsonTokenResults["config"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonTokenResults object")
                        return
                    }
                      UserDefaults.standard.set(jsonTokenConfig["api_base_url"], forKey: "api_base_url")
                    UserDefaults.standard.set(jsonTokenConfig["api_refresh_token"], forKey: "api_refresh_token")
                    UserDefaults.standard.set(jsonTokenConfig["api_about_us"], forKey: "api_about_us")
                    UserDefaults.standard.set(jsonTokenConfig["api_privacy_policy"], forKey: "api_privacy_policy")
                    UserDefaults.standard.set(jsonTokenConfig["api_visitor_agreement"], forKey: "api_visitor_agreement")
                    loadMediaList()
                } catch {
                    //print("Error: Trying to convert JSON data to string", error)
                    return
                }
            }.resume()
        } catch  {
            //print("Error: Trying to convert JSON data to string", error)
            return
        }
        
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
            let defaultDataModel = DefaultData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType,zipcode:zip_code)
            let jsonAccessKeyData = try? JSONEncoder().encode(defaultDataModel)
            
            mediaListRequest.httpBody = jsonAccessKeyData
 
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
                    
                    allMediaItems.removeAll()
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
                    previewVideo()

                    
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
    
    /* -----------------------PreviewMedia------------------------ */
    func previewVideo() {
        do {
            guard let _playURI = UserDefaults.standard.object(forKey: "play_uri") as? String else {
                //print("Invalid playURI")
                return
            }
            
            guard let _accessKey = UserDefaults.standard.object(forKey: "access_key") as? String else {
                //print("Invalid accessKey")
                return
            }
            
            playURI = _playURI
            accessKey = _accessKey
            
            guard let previewVideoParseURL = URL(string: apiBaseURL.appending(playURI)) else {
                //print("Invalid URL")
                return
            }
            
            
            let accessKeyDataModel = AccessKeyData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType, access_key: accessKey,zipcode: zip_code)
            let jsonAccessKeyData = try? JSONEncoder().encode(accessKeyDataModel)
            
            var previewVideoRequest = URLRequest(url: previewVideoParseURL)
            previewVideoRequest.httpMethod = "POST"
            previewVideoRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            previewVideoRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            previewVideoRequest.httpBody = jsonAccessKeyData
            previewVideoRequest.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: previewVideoRequest) {data, response, error in
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
                    guard let jsonPreviewVideoObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        //print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                        return
                    }
                    
                    guard let jsonPreviewVideoResults = jsonPreviewVideoObject["results"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonPreviewVideoResults object")
                        return
                    }
                    
                    guard let _currentVideoPlayURL = jsonPreviewVideoResults["uri"] as? String else {
                        //print("Invalid uri")
                        return
                    }
                    
                    UserDefaults.standard.set(1, forKey: "current_is_live")
                    UserDefaults.standard.set(jsonPreviewVideoResults["is_live"], forKey: "origin_is_live")
                    UserDefaults.standard.set(jsonPreviewVideoResults["manage_trp"], forKey: "origin_manage_trp")
                    
                    
                    guard let jsonPreviewVideoTRP = jsonPreviewVideoResults["trp"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonPreviewVideoResults object")
                        return
                    }

                    UserDefaults.standard.set(jsonPreviewVideoTRP["uri"], forKey: "origin_trp_uri")
                    UserDefaults.standard.set(jsonPreviewVideoTRP["intervel_sec"], forKey: "origin_intervel_sec")
                    UserDefaults.standard.set(jsonPreviewVideoTRP["access_key"], forKey: "origin_trp_access_key")
                    
                    
                                        currentVideoPlayURL = _currentVideoPlayURL
                     UserDefaults.standard.set(currentVideoPlayURL, forKey: "original_uri")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .dataDidFlow, object: currentVideoPlayURL)
                    }
                    infoAboutUs()
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
    
    /* -----------------------About Us------------------------ */
    func infoAboutUs() {
        do {
            guard let _infoAboutUsURL = UserDefaults.standard.object(forKey: "api_about_us") as? String else {
                //print("Invalid playURI")
                return
            }
            
            guard let infoAboutUsParseURL = URL(string: _infoAboutUsURL) else {
                //print("Invalid URL...")
                return
            }
            
            var infoAboutUsRequest = URLRequest(url: infoAboutUsParseURL)
            infoAboutUsRequest.httpMethod = "POST"
            infoAboutUsRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            infoAboutUsRequest.setValue("application/json", forHTTPHeaderField: "Accept") // the response expected to be in JSON format
            let defaultDataModel = DefaultData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType,zipcode:zip_code)
            let jsonAccessKeyData = try? JSONEncoder().encode(defaultDataModel)
            
             infoAboutUsRequest.httpBody = jsonAccessKeyData
            infoAboutUsRequest.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: infoAboutUsRequest) {data, response, error in
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
                    guard let jsonInfoAboutUsObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        //print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                        return
                    }
                    
                    guard let jsonInfoAboutUsResults = jsonInfoAboutUsObject["results"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonPreviewVideoResults object")
                        return
                    }
                    
                    UserDefaults.standard.set(jsonInfoAboutUsResults["page_body"], forKey: "about_us_page_body")
                    UserDefaults.standard.set(jsonInfoAboutUsResults["seo_title"], forKey: "about_us_seo_title")
                    
                    infoPrivacyPolicy()
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
    
    /* -----------------------PrivacyPolicy------------------------ */
    func infoPrivacyPolicy() {
        do {
            guard let _infoPrivacyPolicyURL = UserDefaults.standard.object(forKey: "api_privacy_policy") as? String else {
                //print("Invalid playURI")
                return
            }
            
            guard let infoPrivacyPolicyParseURL = URL(string: _infoPrivacyPolicyURL) else {
                //print("Invalid URL...")
                return
            }
            
            let defaultDataModel = DefaultData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType,zipcode:zip_code)
            let jsonAccessKeyData = try? JSONEncoder().encode(defaultDataModel)
            
 
            
            var infoPrivacyPolicyRequest = URLRequest(url: infoPrivacyPolicyParseURL)
            infoPrivacyPolicyRequest.httpMethod = "POST"
            infoPrivacyPolicyRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            infoPrivacyPolicyRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            infoPrivacyPolicyRequest.httpBody = jsonAccessKeyData
            infoPrivacyPolicyRequest.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: infoPrivacyPolicyRequest) {data, response, error in
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
                    guard let jsonInfoPrivacyPolicyObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        //print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                        return
                    }
                    
                    guard let jsonInfoPrivacyPolicyResults = jsonInfoPrivacyPolicyObject["results"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonPreviewVideoResults object")
                        return
                    }
                    
                    UserDefaults.standard.set(jsonInfoPrivacyPolicyResults["seo_title"], forKey: "privacy_policy_seo_title")
                    UserDefaults.standard.set(jsonInfoPrivacyPolicyResults["page_body"], forKey: "privacy_policy_page_body")
                   
                    infoVisitorAgreement()
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
    
    /* -----------------------VisitorAgreement------------------------ */
    func infoVisitorAgreement() {
        do {
            guard let _infoVisitorAgreementURL = UserDefaults.standard.object(forKey: "api_visitor_agreement") as? String else {
                //print("Invalid playURI")
                return
            }
            
            guard let infoVisitorAgreementParseURL = URL(string: _infoVisitorAgreementURL) else {
                //print("Invalid URL...")
                return
            }
            let defaultDataModel = DefaultData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType,zipcode:zip_code)
            let jsonAccessKeyData = try? JSONEncoder().encode(defaultDataModel)
            
 
            var infoVisitorAgreementRequest = URLRequest(url: infoVisitorAgreementParseURL)
            infoVisitorAgreementRequest.httpMethod = "POST"
            infoVisitorAgreementRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            infoVisitorAgreementRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            infoVisitorAgreementRequest.httpBody = jsonAccessKeyData
            infoVisitorAgreementRequest.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: infoVisitorAgreementRequest) {data, response, error in
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
                    guard let jsonInfoVisitorAgreementObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        //print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                        return
                    }
                    
                    guard let jsonInfoVisitorAgreementResults = jsonInfoVisitorAgreementObject["results"] as? [String: Any] else {
                        //print("Error: Cannot convert data to jsonPreviewVideoResults object")
                        return
                    }
                    
                    UserDefaults.standard.set(jsonInfoVisitorAgreementResults["page_body"], forKey: "visitor_agreement_page_body")
                    UserDefaults.standard.set(jsonInfoVisitorAgreementResults["seo_title"], forKey: "visitor_agreement_seo_title")
                  
                    self.onHomeButton()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                      //  self.onHomeButton()
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
   
    func onHomeButton() {
//        guard let _currentVideoTitle = UserDefaults.standard.object(forKey: "original_title") as? String else {
//            print("Invalid Title")
//            return
//        }
//
//        print(currentVideoPlayURL)
//        print(currentVideoTitle)
//        isPreviewVideoStatus = true
//        isCollapseSideBar = true
//
//
//
//
//        DispatchQueue.main.async {
//           NotificationCenter.default.post(name: .pub_player_stop, object: true)
//        }
        
        guard let _currentVideoTitle = UserDefaults.standard.object(forKey: "original_title") as? String else {
            print("Invalid Title")
            return
        }
        
        isLocationItemFocused = 0
        currentVideoTitle = _currentVideoTitle
        allMediaItems = allMediaItems
         isPreviewVideoStatus = false
        isCollapseSideBar = false
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .pub_player_stop, object: false)
        }
        
        
        
    }
    
    
    
    
}
 
