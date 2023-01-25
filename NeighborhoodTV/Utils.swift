//
//  Utils.swift
//  NeighborhoodTV
//
//  Created by fulldev on 1/20/23.
//

import Foundation

let tokenURL = "https://api.watchntv.tv/v2/user"

/* Create Model */
struct DefaultData: Codable {
    let version_name: String
    let device_id: String
    let device_model: String
    let version_code: String
    let device_type: String
}

let defaultDataModel = DefaultData(version_name: "3", device_id: "3", device_model: "3", version_code: "3", device_type: "Iphone")
let jsonDefaultData = try? JSONEncoder().encode(defaultDataModel)
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
    let version_name: String
    let device_id: String
    let device_model: String
    let version_code: String
    let device_type: String
    let access_key: String
}
/* ------------ */

struct LocationModel:Codable {
    var title: String
    var access_key:String
    var description:String
    var thumbnailUrl:String
    var play_uri:String
    var _id:String
    var locationId:String
}

