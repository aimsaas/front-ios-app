//
//  Diamond.swift
//  Her
//
//  Created by dev on 2025/10/1.
//

import SwiftUI
import SwiftData

struct Diamond: View {
    @Query private var users: [UserInfo]

    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello Diamond")
                    .font(.largeTitle)
                    .padding()

                if let user = users.first {
                    Text("UserId: \(user.userId)")
                        .padding()
                } else {
                    Text("No User Found")
                        .padding()
                }

                NavigationLink(destination: Identity()) {
                    Text("回到身份页面")
                        .font(.headline)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
    }
}
