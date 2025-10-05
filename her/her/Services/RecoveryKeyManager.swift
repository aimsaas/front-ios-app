//
//  RecoveryKeyManager.swift
//  Her
//
//  Created by dev on 2025/10/3.
//

import Foundation
import CryptoKit

/// 返回给用户备份的密钥对数据结构
struct RecoveryKeyPair {
    let privateKeyBase64: String
    let publicKeyBase64: String
    let userId: String
}

class RecoveryKeyManager {
    // Keychain 配置
    static let keychainService = "com.yourapp.recovery"
    static let keychainAccount = "recoveryPrivateKey" // 可以按 userId 变化也可固定

    /// 生成新的签名密钥对（Curve25519.Signing，也可改成别的），把私钥写入 Keychain，返回可导出的字符串
    /// 注意：Curve25519.Signing 在 CryptoKit 中即 Ed25519 / Curve25519 签名的表示
    static func generateAndStore() throws -> RecoveryKeyPair {
        let privateKey = Curve25519.Signing.PrivateKey()
        let privData = privateKey.rawRepresentation
        let pubData = privateKey.publicKey.rawRepresentation

        let privBase64 = privData.base64EncodedString()
        let pubBase64 = pubData.base64EncodedString()
        let userId = sha256Hex(data: pubData)

        // 保存私钥二进制到 Keychain
        try KeychainHelper.save(data: privData, service: keychainService, account: keychainAccount)

        return RecoveryKeyPair(privateKeyBase64: privBase64, publicKeyBase64: pubBase64, userId: userId)
    }

    /// 从 Keychain 直接加载私钥（如果存在）
    static func loadPrivateKeyFromKeychain() -> Curve25519.Signing.PrivateKey? {
        guard let data = KeychainHelper.load(service: keychainService, account: keychainAccount) else { return nil }
        return try? Curve25519.Signing.PrivateKey(rawRepresentation: data)
    }

    /// 获取 Keychain 中的私钥原始 Data（用于传给恢复逻辑）
    static func loadPrivateKeyDataFromKeychain() -> Data? {
        return KeychainHelper.load(service: keychainService, account: keychainAccount)
    }

    /// 导出私钥 base64 到用户（或者把 base64 保存到密码管理器）。此函数仅把私钥保存到 Keychain（导入时会覆盖）
    @discardableResult
    static func importPrivateKey(base64: String) throws -> String {
        guard let data = Data(base64Encoded: base64) else { throw NSError(domain: "InvalidBase64", code: -1) }
        // 验证能否构造私钥
        let priv = try Curve25519.Signing.PrivateKey(rawRepresentation: data)
        let pub = priv.publicKey.rawRepresentation
        let userId = sha256Hex(data: pub)
        try KeychainHelper.save(data: data, service: keychainService, account: keychainAccount)
        return userId
    }

    /// 从给定私钥 base64 得到 userId（便于先预览）
    static func userIdFromPrivateKeyBase64(_ base64: String) -> String? {
        guard let data = Data(base64Encoded: base64),
              let priv = try? Curve25519.Signing.PrivateKey(rawRepresentation: data) else { return nil }
        return sha256Hex(data: priv.publicKey.rawRepresentation)
    }

    static func sha256Hex(data: Data) -> String {
        let h = SHA256.hash(data: data)
        return h.map { String(format: "%02x", $0) }.joined()
    }

    /// 删除 Keychain 中的私钥（例如注销时）
    static func deletePrivateKeyFromKeychain() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
    }
}
