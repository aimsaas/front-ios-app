//
//  UserCache.swift
//  Her
//
//  Created by dev on 2025/10/2.
//

import SwiftData

@Model
class UserInfo {
    var userId: String
    var token: String
    var avatarUrl: String
    var certificated: Bool
    var certification: String
    var level: String
    var nickName: String
    var uid: String
    var updateTime: Int64

    init(userId: String,
         token: String,
         avatarUrl: String,
         certificated: Bool,
         certification: String,
         level: String,
         nickName: String,
         uid: String,
         updateTime: Int64) {
        self.userId = userId
        self.token = token
        self.avatarUrl = avatarUrl
        self.certificated = certificated
        self.certification = certification
        self.level = level
        self.nickName = nickName
        self.uid = uid
        self.updateTime = updateTime
    }
}
