//
//  HipDogAteHomework.swift
//  hipleech
//
//  Created by Thomas Mellenthin on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin. All rights reserved.
//

import Foundation

public class HipDogAteHomework: Equatable, Codable {
    let date: String
    let period: String
    let courseName: String
    let remark: String
    
    public init(date: String, period: String, courseName: String, remark: String) {
        self.date = date
        self.period = period
        self.courseName = courseName
        self.remark = remark
    }
    
    public static func == (lhs: HipDogAteHomework, rhs: HipDogAteHomework) -> Bool {
        return lhs.date == rhs.date
            && lhs.period == rhs.period
            && lhs.courseName == rhs.courseName
            && lhs.remark == rhs.remark
    }
}
