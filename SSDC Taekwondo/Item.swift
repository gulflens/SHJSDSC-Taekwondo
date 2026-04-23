//
//  Item.swift
//  SSDC Taekwondo
//
//  Created by Ayman Maklad on 24/04/2026.
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
