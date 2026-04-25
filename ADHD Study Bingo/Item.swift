//
//  Item.swift
//  ADHD Study Bingo
//
//  Created by Mirro on 4/25/26.
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
