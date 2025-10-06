//
//  ShortID.swift
//  Her
//
//  Created by dev on 2025/10/6.
//

import Foundation
import CryptoKit

public struct ShortID {
    /// 从随机源生成短ID
    public static func generate(length: Int = 9) -> String {
        var randomBytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let hash = SHA256.hash(data: Data(randomBytes))
        let base64 = Data(hash).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return String(base64.prefix(length))
    }

    /// 从输入数据派生短ID（稳定可复现）
    public static func generate(from data: Data, length: Int = 9) -> String {
        let hash = SHA256.hash(data: data)
        let base64 = Data(hash).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return String(base64.prefix(length))
    }
}
