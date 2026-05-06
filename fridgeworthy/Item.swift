//
//  Item.swift
//  fridgeworthy
//
//  Created by Phil Cheng on 5/5/26.
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
