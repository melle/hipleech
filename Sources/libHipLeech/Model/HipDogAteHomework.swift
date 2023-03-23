//
//  HipDogAteHomework.swift
//  hipleech
//
//  Created by Thomas Mellenthin on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin. All rights reserved.
//

import Foundation

public struct HipDogAteHomework: Hashable, Equatable, Codable {
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
    
    /// Diffs two DogAteHomework entries. The difference is returned as new DaH or nil, if both DoHs are requal.
    public static func diff(lhs: [HipDogAteHomework], rhs: [HipDogAteHomework]) -> [HipDogAteHomework] {
        let lhSet = Set(lhs)
        let rhSet = Set(rhs)
        let diff = lhSet.symmetricDifference(rhSet)
        let newDogAteHomework = Array(diff).sorted(by: { $0.date < $1.date })

        return newDogAteHomework
    }
    
    public func prettyText(format: OutputFormat = .ascii) -> String {
        let bold = (format == .markdown) ? "*" : ""
        return "\(bold)\(courseName) (\(period). Std.)\(bold)\t\(remark) (\(date))"
    }

}
