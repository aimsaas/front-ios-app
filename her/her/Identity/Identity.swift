//
//  Identity.swift
//  Her
//
//  Created by dev on 2025/10/2.
//

import SwiftUI
import SwiftData

enum IdentityState: Equatable {
    case none          // 还没有创建身份或已注销
    case active(String) // 已有身份，对应导出的私钥字符串
}

struct Identity: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [UserInfo]

    @State private var showExportAlert = false
    @State private var exportedKey = ""
    @State private var showImportSheet = false
    @State private var importKey = ""
    @State private var showKeyErrorAlert = false
    @State private var identityState: IdentityState = .none

    var body: some View {
        VStack(spacing: 20) {
            Text("Hello Identity")
                .font(.largeTitle)
                .padding()
            
            if let user = users.first {
                Text("User ID: \(user.userId)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // 创建身份按钮：如果已有身份则禁用
            Button("创建身份") {
                do {
                    let pair = try RecoveryKeyManager.generateAndStore()
                    let newUser = UserInfo(
                        userId: pair.userId,
                        token: "token_string",
                        avatarUrl: "avatar/2025/9/\(pair.userId).png",
                        certificated: true,
                        certification: "走哪啦团队",
                        level: "diamond",
                        nickName: "功夫小猫",
                        uid: UUID().uuidString,
                        updateTime: Int64(Date().timeIntervalSince1970 * 1000)
                    )
                    context.insert(newUser)
                    try? context.save()
                    print("✅ 已创建身份并生成私钥，userId = \(pair.userId)")
                } catch {
                    print("❌ 生成私钥失败: \(error)")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!(users.first?.userId.isEmpty ?? true))

            Button("创建身份") {
                do {
                    let pair = try RecoveryKeyManager.generateAndStore()
                    let newUser = UserInfo(
                        userId: pair.userId,
                        token: "token_string",
                        avatarUrl: "avatar/2025/9/\(pair.userId).png",
                        certificated: true,
                        certification: "走哪啦团队",
                        level: "diamond",
                        nickName: "功夫小猫",
                        uid: UUID().uuidString,
                        updateTime: Int64(Date().timeIntervalSince1970 * 1000)
                    )
                    context.insert(newUser)
                    try? context.save()
                    
                    // 🔹 更新 identityState
                    identityState = .active(RecoveryKeyManager.loadPrivateKeyDataFromKeychain()!.base64EncodedString())

                    print("✅ 已创建身份并生成私钥，userId = \(pair.userId)")
                } catch {
                    print("❌ 生成私钥失败: \(error)")
                }
            }
            
            
            // 注销身份
            Button("注销身份") {
                if let user = users.first {
                    // 删除用户信息
                    clearUser(user: user)
                    
                    // 同时销毁私钥
                    RecoveryKeyManager.deletePrivateKey()
                    
                    // 打印确认
                    print("🗑️ 已注销身份并销毁私钥")
                }
            }
            .buttonStyle(.bordered)

            Divider()

            // 导出私钥
            Button("导出私钥") {
                if case .active(let key) = identityState {
                    showExportAlert = true
                } else {
                    // 为安全起见，这里仍然尝试加载一次，防止状态不同步
                    if let data = RecoveryKeyManager.loadPrivateKeyDataFromKeychain() {
                        let key = data.base64EncodedString()
                        identityState = .active(key)
                        showExportAlert = true
                    } else {
                        identityState = .none
                        showExportAlert = true
                    }
                }
            }
            .buttonStyle(.bordered)
            .disabled(identityState == .none)

            // 从私钥恢复
            Button("从私钥恢复") {
                showImportSheet = true
            }
        }
        // 导出私钥弹窗
        .alert("导出私钥", isPresented: $showExportAlert) {
            switch identityState {
            case .none:
                Button("关闭", role: .cancel) {}
            case .active(let key):
                Button("复制") {
                    UIPasteboard.general.string = key
                }
                Button("关闭", role: .cancel) {}
            }
        } message: {
            switch identityState {
            case .none:
                Text("当前没有可导出的身份，请先创建或恢复。")
            case .active(let key):
                Text("请妥善保存此私钥（不要截图或泄漏）:\n\n\(key)")
            }
        }

        // 恢复账号输入界面
        .sheet(isPresented: $showImportSheet) {
            VStack {
                Text("请输入私钥 Base64")
                    .font(.headline)
                TextEditor(text: $importKey)
                    .border(.gray)
                    .frame(height: 150)
                Button("恢复账号") {
                    do {
                        guard let data = Data(base64Encoded: importKey) else {
                            showKeyErrorAlert = true
                            showImportSheet = false
                            return
                        }
                        let _ = try RecoveryKeyManager.importPrivateKey(base64: importKey)
                        _ = try AccountRecovery.recoverFromPrivateKeyData(data, context: context)
                        showImportSheet = false
                    } catch {
                        print("恢复失败:", error)
                        showKeyErrorAlert = true
                        showImportSheet = false
                    }
                }
                .padding()
            }
            .padding()
        }

        // 密钥错误提示
        .alert("密钥错误", isPresented: $showKeyErrorAlert) {
            Button("关闭", role: .cancel) {}
        } message: {
            Text("输入的密钥无效或格式错误。")
        }
    }

    private func clearUser(user: UserInfo) {
        context.delete(user)
        try? context.save()
    }
}
