//
//  Utils.swift
//  NeighborhoodTV
//
//  Created by fulldev on 1/20/23.
//

import Foundation
import UIKit

let baseURL = "https://apiv2.watchntv.tv/v2"//"https://api.watchntv.tv/v2/user"
let tokenURL = "https://apiv2.watchntv.tv/v2/user"
/* Create Model */
struct DefaultData: Codable {
    let version_name: String
    let device_id: String
    let device_model: String
    let version_code: String
    let device_type: String
    var zipcode:String
}

let defaultDataModel = DefaultData(version_name: versionName, device_id: deviceId, device_model: deviceModel, version_code: versionCode, device_type: deviceType,zipcode:zip_code)
let jsonDefaultData = try? JSONEncoder().encode(defaultDataModel)
let versionName = "nbh_iosTV_\(versionStr())"
let deviceId = UIDevice.current.identifierForVendor!.uuidString
let deviceModel = UIDevice.modelName
let versionCode = "1"
let deviceType = "Apple TV"
var zip_code = ""
var spalshActive:Bool = false
//var accessToken = ""
//var apiBaseURL = ""
//var homeSubURI = ""
//var playURI = ""
//var accessKey = ""
//var currentVideoPlayURL = ""


/* ------------ */
struct MediaListType: Codable {
    var itemIndex: Int
    var _id: String
    var title: String
    var description: String
    var thumbnailUrl: String
    var duration: Int
    var play_uri: String
    var access_key: String
}

/* AccessKey Model */
struct AccessKeyData: Codable {
    var version_name: String
    var device_id: String
    var device_model: String
    var version_code: String
    var device_type: String
    var access_key: String
    var zipcode : String
}
/* ------------ */

struct LocationModel:Codable {
    var locationItemIndex: Int
    var _id:String
    var thumbnailUrl:String
    var title: String
    var uri:String
}

extension Notification.Name {
    static let dataDidFlow = Notification.Name("DataDidFlow")
    static let previousItemIndex = Notification.Name("previousItemIndex")
    static let locationDefaultFocus = Notification.Name("locationDefaultFocus")
    static let onFullBtnAction = Notification.Name("onFullBtnAction")
    static let isCollapseSideBar = Notification.Name("isCollapseSideBar")
    static let puh_fullScreen = Notification.Name("puh_fullScreen")
    static let pub_player_stop = Notification.Name("pub_player_stop")
    static let pub_des_player_stop = Notification.Name("pub_des_player_stop")
    static let zip_Code_Update = Notification.Name("zip_Code_Update")
    static let zip_Code_locationDefaultFocus = Notification.Name("zip_Code_locationDefaultFocus")
    static let zip_Code_Update_Dashboard = Notification.Name("zip_Code_Update_Dashboard")
}

/* RefreshToken Model */
struct RefreshToken: Codable {
    var version_name: String
    var device_id: String
    var device_model: String
    var version_code: String
    var device_type: String
    var token: String
}
/* ------------ */

func getRefreshToken() {
    guard let _refreshTokenURL = UserDefaults.standard.object(forKey: "api_refresh_token") as? String else {
        print("Invalid Refresh Token")
        return
    }
    
    guard let _refreshParseTokenURL = URL(string: _refreshTokenURL) else {
        print("Invalid URL")
        return
    }
    
    guard let _refreshToken = UserDefaults.standard.object(forKey: "refreshToken") as? String else {
        print("Invalid refreshToken")
        return
    }
    
    let refreshTokenDataModel = RefreshToken(version_name: "1.0", device_id: "1", device_model: "1", version_code: "1.0", device_type: "Fire TV", token: _refreshToken)
    let jsonRefreshTokenData = try? JSONEncoder().encode(refreshTokenDataModel)
    
    var refreshToken = URLRequest(url: _refreshParseTokenURL)
    refreshToken.httpMethod = "POST"
    refreshToken.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    refreshToken.setValue("application/json", forHTTPHeaderField: "Accept")
    refreshToken.httpBody = jsonRefreshTokenData
    
    URLSession.shared.dataTask(with: refreshToken) { data, response , error in
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
            print("Error: HTTP request failed")
            if _response?.statusCode == 440 {
                reGetAccessToken()
            }
            
        }
        
        do {
            guard let jsonRefreshTokenObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Error: Cannot convert data to jsonRefreshTokenObject object")
                return
            }
            
            guard let jsonRefreshTokenResults = jsonRefreshTokenObject["results"] as? [String: Any] else {
                print("Error: Cannot convert data to JSON object")
                return
            }
            
            UserDefaults.standard.set(jsonRefreshTokenResults["accessToken"], forKey: "accessToken")
            UserDefaults.standard.set(jsonRefreshTokenResults["refreshToken"], forKey: "refreshToken")
        } catch {
            print("Error: Trying to convert JSON data to string", error)
            return
        }
    }.resume()
}

func reGetAccessToken() {
    do {
        guard let tokenParseURL = URL(string: tokenURL) else {
            print("Invalid URL")
            return
        }
        
        var tokenRequest = URLRequest(url: tokenParseURL)
        tokenRequest.httpMethod = "POST"
        tokenRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        tokenRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        tokenRequest.httpBody = jsonDefaultData
        
        URLSession.shared.dataTask(with: tokenRequest) { data, response, error in
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
              //  print("Success: HTTP request ")
            } else {
                print("Error: HTTP request failed")
            }
            
            do {
                guard let jsonTokenObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("Error: Cannot convert data to jsonTokenObject object")
                    return
                }
                
                
                guard let jsonTokenResults = jsonTokenObject["results"] as? [String: Any] else {
                    print("Error: Cannot convert data to jsonTokenResults object")
                    return
                }
                UserDefaults.standard.set(jsonTokenResults["accessToken"], forKey: "accessToken")
                UserDefaults.standard.set(jsonTokenResults["refreshToken"], forKey: "refreshToken")
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

func versionStr()->String{
  let appVerString: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? ""
  return appVerString
}

func versionCodeStr()->String{
  let appBuildString: String = Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? ""
  return appBuildString
}

