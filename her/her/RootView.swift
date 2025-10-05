//
//  RootView.swift
//  Her
//
//  Created by dev on 2025/10/2.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [UserInfo]

    @State private var attemptedRecovery = false

    var body: some View {
        Group {
            // 优先取本地已存在用户（Query 会自动更新）
            if let user = users.first {
                launchPage(for: user)
            } else {
                // 没有用户：尝试从 Keychain 自动恢复一次
                if !attemptedRecovery {
                    // use onAppear pattern to avoid doing it during view building
                    Color.clear.onAppear {
                        attemptedRecovery = true
                        attemptKeychainRecovery()
                    }
                    // 过渡页面（可以自定义 Loading）
                    Identity()
                } else {
                    // 恢复后如果仍无用户，按设备策略创建新用户（或者展示默认 ContentView）
                    // 这里保留你之前的“首次创建设备 user”逻辑 —— 如果需要自动创建设备用户也可在此处实现
                    Identity()
                }
            }
        }
    }

    private func attemptKeychainRecovery() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if let _ = try AccountRecovery.recoverFromKeychainIfNeeded(context: context) {
                    // 成功恢复后，@Query 会刷新 UI，回到对应页面
                } else {
                    // Keychain 没有私钥或恢复失败 —— 你可以选择自动创建设备账号或保持 ContentView
                    // 如果你想创建设备账号 automatically, 可以在这里插入创建逻辑
                    // createDeviceUserIfNeeded()
                }
            } catch {
                print("Keychain recovery error:", error)
            }
        }
    }

    @ViewBuilder
    private func launchPage(for user: UserInfo) -> some View {
        switch user.level.lowercased() {
        case "silver":
            Silver()
        case "platinum":
            Platinum()
        case "diamond":
            Diamond()
        case "default":
            Default()
        default:
            Identity()
        }
    }

    // 例：如果你希望在首次无用户时自动创建一个设备账号（非必需）
    private func createDeviceUserIfNeeded() {
        // 可选：用 Keychain 存的 device id 或 UIDevice.identifierForVendor 生成 userId
        // 并插入 UserCache 到 context（同之前 UserCache 结构）
    }
}
