//
//  ContentView.swift
//  Her
//
//  Created by dev on 2025/9/30.
//

import SwiftUI
import SwiftData

struct Default: View {
    @Query private var users: [UserInfo]
    
    var body: some View {
        VStack {
            Text("Hello Default")
                .font(.largeTitle)
                .padding()
            
            if let user = users.first {
                Text("UserId: \(user.userId)")
                    .padding()
            } else {
                Text("No User Found")
                    .padding()
            }
        }
    }
}
