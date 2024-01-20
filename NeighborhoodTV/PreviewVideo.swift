//
//  PreviewVideo.swift
//  NeighborhoodTV
//
//  Created by fulldev on 1/20/23.
//

import SwiftUI
import AVKit

class PlayerInstance {
    private init() {}
    static let shared = PlayerInstance()
    var previewPlayer : AVQueuePlayer?
    var previewVideoLooper: AVPlayerLooper?
    
    var urlToLoad:String? = nil
    var videoTotalLength = String()
    var currentPlayingPosition = String()
    var trpTimer: Timer?
    var timer: Timer?

    func getPlayer(withURL path:String) -> AVQueuePlayer? {
        
        print(#function)
        self.startPlaying(withURL: path)
        return previewPlayer
        
    }
    
    
    func startPlaying(withURL path:String) {
        
        self.stopPlayer()
        self.previewPlayer = nil
        print(#function)
        guard let url = URL.init(string: path) else { return }
        self.addTimeObserver(url: url)
        let templateItem = AVPlayerItem(url: url)
        self.previewPlayer = AVQueuePlayer(playerItem: templateItem)
        self.previewPlayer?.play()
        let videoCurrent = CMTimeGetSeconds((self.previewPlayer?.currentTime())!)
        self.currentPlayingPosition = String(format: "%f", videoCurrent)
        videoTotalLength = String(format: "%ld", CMTimeValue((self.previewPlayer?.currentItem?.duration.value)!))
        if UserDefaults.standard.value(forKey: "origin_manage_trp") != nil{
            let manageTRP = UserDefaults.standard.value(forKey: "origin_manage_trp") as? Bool
            if manageTRP == true{
               // self.startTRPUpdate()
            }
        }
        
    }
    
 
    
    func addTimeObserver(url:URL){
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQue = DispatchQueue.main
        previewPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: mainQue, using: { [weak self ] time in
            guard let currentItem = self?.previewPlayer?.currentItem else{return}
            let videoCurrent = CMTimeGetSeconds((self?.previewPlayer!.currentTime())!)
            self?.currentPlayingPosition = String(format: "%f", videoCurrent)
            self?.videoTotalLength = String(format: "%ld", CMTimeValue((self?.previewPlayer!.currentItem?.duration.value)!))
         })
    }
    
    
    
    func updatePlaying(withURL path:String) {
        guard let url = URL.init(string: path) else { return }
        print(#function)
        let templateItem = AVPlayerItem(url: url)
        if self.previewPlayer != nil {
            self.addTimeObserver(url: url)
            self.previewPlayer?.insert(templateItem, after: self.previewPlayer!.currentItem)
            self.previewPlayer?.advanceToNextItem()
            self.previewPlayer?.play()
            let videoCurrent = CMTimeGetSeconds((self.previewPlayer?.currentTime())!)
            self.currentPlayingPosition = String(format: "%f", videoCurrent)
            videoTotalLength = String(format: "%ld", CMTimeValue((self.previewPlayer?.currentItem?.duration.value ?? 0)!))
            if UserDefaults.standard.value(forKey: "origin_manage_trp") != nil{
                let manageTRP = UserDefaults.standard.value(forKey: "origin_manage_trp") as? Bool
                if manageTRP == true{
                    self.startTRPUpdate { status in
                        if status == true{
                        }
                    }
                    guard var isLive = UserDefaults.standard.object(forKey: "current_is_live") as? Int else {
                        print("Invalid URL")
                        return
                    }
                    var interval  = 50
                     if  isLive == 1{
                         if UserDefaults.standard.value(forKey: "origin_intervel_sec") != nil{
                             interval = UserDefaults.standard.object(forKey: "origin_intervel_sec") as! Int
                         }
                     }else{
                         if UserDefaults.standard.value(forKey: "current_intervel_sec") != nil{
                             interval = UserDefaults.standard.object(forKey: "current_intervel_sec") as! Int
                         }
                     }
                     let duration = interval
                    self.trpTimer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(self.moviewTimerFired), userInfo: nil, repeats: true)
                 }
            }
        }
        
    }
    
    
    func stopPlayer() {
        print(#function)
        self.previewPlayer?.pause()
        self.previewPlayer?.seek(to: .zero)
        self.previewPlayer?.removeAllItems()
        self.endTRPUpdate()
    }
 
    func startTRPUpdate(completionHandler:@escaping (_ status:Bool)->Void ) -> () {
        print(#function)
        do {
            
            guard let isLive = UserDefaults.standard.object(forKey: "origin_is_live") as? Int else {
                print("Invalid URL")
                return
            }
            
            guard let isFromDiscription = UserDefaults.standard.object(forKey: "current_is_live") as? Int else {
                print("Invalid URL")
                return
            }
            
            var trpUrl  = ""
            var trpAccesskey = ""
            if isLive == 1 && isFromDiscription == 1{
                if UserDefaults.standard.value(forKey: "origin_trp_uri") != nil{
                    trpUrl = (UserDefaults.standard.object(forKey: "origin_trp_uri") as? String)!
                }
                
                if UserDefaults.standard.value(forKey: "origin_trp_access_key") != nil{
                    trpAccesskey = (UserDefaults.standard.object(forKey: "origin_trp_access_key") as? String)!
                }
            }else{
                if UserDefaults.standard.value(forKey: "current_trp_uri") != nil{
                    trpUrl = (UserDefaults.standard.object(forKey: "current_trp_uri") as? String)!
                }
                
                if UserDefaults.standard.value(forKey: "current_trp_access_key") != nil{
                    trpAccesskey = (UserDefaults.standard.object(forKey: "current_trp_access_key") as? String)!
                }
            }

            trpUrl = trpUrl.replacingOccurrences(of: "[TOTAL_DURATION]", with: videoTotalLength)
            trpUrl = trpUrl.replacingOccurrences(of: "[PLAYING_STATUS]", with: "1")
            trpUrl = trpUrl.replacingOccurrences(of: "[CURRENT_PLAYING_POSITION]", with: currentPlayingPosition)
            let url = baseURL + trpUrl
//            let deviceID = UIDevice.current.identifierForVendor?.uuidString
            let param = NSMutableDictionary()
            param.setValue(deviceId, forKey: "device_id")
            param.setValue(versionName, forKey: "version_name")
            param.setValue(versionCode, forKey: "version_code")
            param.setValue(deviceType, forKey: "device_type")
            param.setValue(deviceModel, forKey: "device_model")
            param.setValue(trpAccesskey, forKey: "access_key")
            param.setValue(zip_code, forKey: "zipcode")

            guard let apiUrl = URL(string: url) else {
                return
            }
            
            guard let accessToken = UserDefaults.standard.object(forKey: "accessToken") as? String else {
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
                var request = URLRequest(url: apiUrl)
                request.httpMethod = "POST"
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = data
                request.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) {data, response, error in
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
                    if _response!.statusCode == 401 {
                        getRefreshToken()
                    }
                    do {
                        guard let jsonTrpObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            //print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                            return
                        }
                        
                        print(jsonTrpObject)
            
                        completionHandler(true)
 
                        
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
    }
    
    @objc func moviewTimerFired(){
        NSLog("hello World")
        self.repeatTRPUpdate()
    }
 
    
    func repeatTRPUpdate() {
        print(#function)
        do {
 
            
            guard let isLive = UserDefaults.standard.object(forKey: "origin_is_live") as? Int else {
                print("Invalid URL")
                return
            }
            
            guard let isFromDiscription = UserDefaults.standard.object(forKey: "current_is_live") as? Int else {
                print("Invalid URL")
                return
            }
            
            var trpUrl  = ""
            var trpAccesskey = ""
            if isLive == 1 && isFromDiscription == 1{
                if UserDefaults.standard.value(forKey: "origin_trp_uri") != nil{
                    trpUrl = (UserDefaults.standard.object(forKey: "origin_trp_uri") as? String)!
                }
                
                if UserDefaults.standard.value(forKey: "origin_trp_access_key") != nil{
                    trpAccesskey = (UserDefaults.standard.object(forKey: "origin_trp_access_key") as? String)!
                }
            }else{
                if UserDefaults.standard.value(forKey: "current_trp_uri") != nil{
                    trpUrl = (UserDefaults.standard.object(forKey: "current_trp_uri") as? String)!
                }
                
                if UserDefaults.standard.value(forKey: "current_trp_access_key") != nil{
                    trpAccesskey = (UserDefaults.standard.object(forKey: "current_trp_access_key") as? String)!
                }
            }

            trpUrl = trpUrl.replacingOccurrences(of: "[TOTAL_DURATION]", with: videoTotalLength)
            trpUrl = trpUrl.replacingOccurrences(of: "[PLAYING_STATUS]", with: "1")
            trpUrl = trpUrl.replacingOccurrences(of: "[CURRENT_PLAYING_POSITION]", with: currentPlayingPosition)
            let url = baseURL + trpUrl
            let deviceID = UIDevice.current.identifierForVendor?.uuidString
            let param = NSMutableDictionary()
            param.setValue(deviceId, forKey: "device_id")
            param.setValue(versionName, forKey: "version_name")
            param.setValue(versionCode, forKey: "version_code")
            param.setValue(deviceType, forKey: "device_type")
            param.setValue(deviceModel, forKey: "device_model")
            param.setValue(trpAccesskey, forKey: "access_key")
            param.setValue(zip_code, forKey: "zipcode")

            guard let apiUrl = URL(string: url) else {
                return
            }
            
            guard let accessToken = UserDefaults.standard.object(forKey: "accessToken") as? String else {
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
                var request = URLRequest(url: apiUrl)
                request.httpMethod = "POST"
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = data
                request.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) {data, response, error in
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
                    if _response!.statusCode == 401 {
                        getRefreshToken()
                    }
                    do {
                        guard let jsonTrpObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            //print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                            return
                        }
                        
                        guard let jsonTrpResults = jsonTrpObject["results"] as? [String: Any] else {
                            //print("Error: Cannot convert data to jsonPreviewVideoResults object")
                            return
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
    }
    
    func endTRPUpdate() {
        print(#function)
        do {
            if self.trpTimer != nil{
                self.trpTimer?.invalidate()
            }
            
            guard let isLive = UserDefaults.standard.object(forKey: "origin_is_live") as? Int else {
                print("Invalid URL")
                return
            }
            
            guard let isFromDiscription = UserDefaults.standard.object(forKey: "current_is_live") as? Int else {
                print("Invalid URL")
                return
            }
            
            var trpUrl  = ""
            var trpAccesskey = ""
            if isLive == 1 && isFromDiscription == 1{
                if UserDefaults.standard.value(forKey: "origin_trp_uri") != nil{
                    trpUrl = (UserDefaults.standard.object(forKey: "origin_trp_uri") as? String)!
                }
                
                if UserDefaults.standard.value(forKey: "origin_trp_access_key") != nil{
                    trpAccesskey = (UserDefaults.standard.object(forKey: "origin_trp_access_key") as? String)!
                }
            }else{
                if UserDefaults.standard.value(forKey: "current_trp_uri") != nil{
                    trpUrl = (UserDefaults.standard.object(forKey: "current_trp_uri") as? String)!
                }
                
                if UserDefaults.standard.value(forKey: "current_trp_access_key") != nil{
                    trpAccesskey = (UserDefaults.standard.object(forKey: "current_trp_access_key") as? String)!
                }
            }
            
            trpUrl = trpUrl.replacingOccurrences(of: "[TOTAL_DURATION]", with: videoTotalLength)
            trpUrl = trpUrl.replacingOccurrences(of: "[PLAYING_STATUS]", with: "2")
            trpUrl = trpUrl.replacingOccurrences(of: "[CURRENT_PLAYING_POSITION]", with: currentPlayingPosition)
            let url = baseURL + trpUrl
            let deviceID = UIDevice.current.identifierForVendor?.uuidString
            let param = NSMutableDictionary()
            param.setValue(deviceId, forKey: "device_id")
            param.setValue(versionName, forKey: "version_name")
            param.setValue(versionCode, forKey: "version_code")
            param.setValue(deviceType, forKey: "device_type")
            param.setValue(deviceModel, forKey: "device_model")
            param.setValue(trpAccesskey, forKey: "access_key")
            param.setValue(zip_code, forKey: "zipcode")

            guard let apiUrl = URL(string: url) else {
                return
            }
            
            guard let accessToken = UserDefaults.standard.object(forKey: "accessToken") as? String else {
                return
            }
            
            do {
                let data = try JSONSerialization.data(withJSONObject: param, options: .prettyPrinted)
                var request = URLRequest(url: apiUrl)
                request.httpMethod = "POST"
                request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                request.httpBody = data
                request.setValue( "Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                
                URLSession.shared.dataTask(with: request) {data, response, error in
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
                    if _response!.statusCode == 401 {
                        getRefreshToken()
                    }
                    do {
                        guard let jsonTrpObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                            //print("Error: Cannot convert jsonPreviewVideoObject to JSON object")
                            return
                        }
                        
                        guard let jsonTrpResults = jsonTrpObject["results"] as? [String: Any] else {
                            //print("Error: Cannot convert data to jsonPreviewVideoResults object")
                            return
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
    }
    
}


struct PreviewVideo: View {
    @State var originVideoPlayURL:String = UserDefaults.standard.object(forKey: "original_uri") as? String ?? ""
//    @State private var previewPlayer : AVQueuePlayer?
//    @State private var previewVideoLooper: AVPlayerLooper?
    @State var isFSModeFlag:Bool = false
    @State var previewCurrentthumbnailUrl:String = (UserDefaults.standard.object(forKey: "currentthumbnailUrl") as? String)!
    
    let pub_player_stop = NotificationCenter.default.publisher(for: NSNotification.Name.pub_player_stop)
    
    var body: some View {
        
        VideoPlayer(player: PlayerInstance.shared.getPlayer(withURL: originVideoPlayURL))
                    .overlay(AsyncImage(url: URL(string: previewCurrentthumbnailUrl), content: {image in
                 image.resizable()
                    .scaledToFill()
            }, placeholder: {progressView()}).opacity(isFSModeFlag ? 1: 0))
            .focusable(false)
            .onAppear() {
                isFSModeFlag = false
                UserDefaults.standard.set(1, forKey: "current_is_live")
                guard let _originVideoPlayURL = UserDefaults.standard.object(forKey: "original_uri") as? String else {
                    print("Error: Invalid Original_URL")
                    return
                }
                
                originVideoPlayURL = _originVideoPlayURL
                
                PlayerInstance.shared.updatePlaying(withURL: originVideoPlayURL)
                print("-------->>>>>>>>play3", _originVideoPlayURL)
                
                guard let _previewCurrentthumbnailUrl = UserDefaults.standard.object(forKey: "currentthumbnailUrl") as? String else {
                    print("Invalid access token")
                    return
                }
                previewCurrentthumbnailUrl = _previewCurrentthumbnailUrl
               // getTRPInfo()
                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil, using: self.didPlayToEnd)
            }
            
            .onReceive(pub_player_stop) {(oPub_player_stop) in
                guard let _oPub_player_stop = oPub_player_stop.object as? Bool else {
                    print("Invalid URL")
                    return
                }
                if _oPub_player_stop {
                    print("------->>>>>>>>>Pause1")
//                    PlayerInstance.shared.previewPlayer!.pause()
//                    PlayerInstance.shared.previewPlayer!.seek(to: .zero)
                    PlayerInstance.shared.stopPlayer()

                }
            }
    }
    
    func progressView() -> some View {
        Image(systemName: "")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
    }
    
    func didPlayToEnd(_ notification: Notification) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .puh_fullScreen, object: false)
            NotificationCenter.default.post(name: .onFullBtnAction, object: false)
        }
        PlayerInstance.shared.stopPlayer()

//        PlayerInstance.shared.previewPlayer!.pause()
//        PlayerInstance.shared.previewPlayer!.seek(to: .zero)
    }
    

    
}


