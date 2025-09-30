//
//  Item.swift
//  Her
//
//  Created by dev on 2025/9/30.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
