//
//  HipSummary.swift
//  hipleech
//
//  Created by Thomas Mellenthin on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin. All rights reserved.
//

import Foundation


public class HipSummary: Codable, Equatable {
    let key: String
    let value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    public static func == (lhs: HipSummary, rhs: HipSummary) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
}
