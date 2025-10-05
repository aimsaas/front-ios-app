//
//  AccountRecovery.swift
//  Her
//
//  Created by dev on 2025/10/3.
//

import Foundation
import SwiftData
import CryptoKit

/// 负责用私钥恢复/创建 UserCache（本地示例）
/// 若你有后端，应在此处调用后端验证/拉取真实用户数据并在本地保存
class AccountRecovery {
    /// 由私钥二进制恢复本地账户：若本地已存在对应 userId，返回该用户；否则创建本地用户（仅本地示例）
    @discardableResult
    static func recoverFromPrivateKeyData(_ privData: Data, context: ModelContext) throws -> UserInfo {
        // 构造私钥对象，派生公钥与 userId
        let priv = try Curve25519.Signing.PrivateKey(rawRepresentation: privData)
        let pubData = priv.publicKey.rawRepresentation
        let userId = RecoveryKeyManager.sha256Hex(data: pubData)

        // 1) 如果本地已有该 userId，则直接返回
        let fetch = FetchDescriptor<UserInfo>(predicate: #Predicate { $0.userId == userId })
        if let existing = try? context.fetch(fetch).first {
            // 确保私钥也写入 Keychain，便于后续自动登录
            try? KeychainHelper.save(data: privData, service: RecoveryKeyManager.keychainService, account: RecoveryKeyManager.keychainAccount)
            return existing
        }

        // 2) 没有本地记录：在真实场景应该向后端请求该 userId 的资料（并用签名挑战验证所有权）
        // 这里演示本地创建一个基础账户（测试用）
        let newUser = UserInfo(
            userId: userId,
            token: "recovered-token-\(UUID().uuidString)",
            avatarUrl: "avatar/default.png",
            certificated: false,
            certification: "",
            level: "silver",
            nickName: "RecoveredUser",
            uid: UUID().uuidString,
            updateTime: Int64(Date().timeIntervalSince1970 * 1000)
        )

        context.insert(newUser)
        try context.save()

        // 保存私钥到 Keychain 以便以后自动恢复
        try KeychainHelper.save(data: privData, service: RecoveryKeyManager.keychainService, account: RecoveryKeyManager.keychainAccount)

        return newUser
    }

    /// 便利方法：如果 Keychain 有私钥则直接用它恢复（或者返回 nil）
    @discardableResult
    static func recoverFromKeychainIfNeeded(context: ModelContext) throws -> UserInfo? {
        if let privData = RecoveryKeyManager.loadPrivateKeyDataFromKeychain() {
            return try recoverFromPrivateKeyData(privData, context: context)
        }
        return nil
    }
}
