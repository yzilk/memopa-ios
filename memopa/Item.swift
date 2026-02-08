//
//  Item.swift
//  memopa
//
//  Created by Yugo Noji on 2026/02/08.
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
