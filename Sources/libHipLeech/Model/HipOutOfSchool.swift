//
//  HipOutOfSchool.swift
//  hipleech
//
//  Created by Thomas Mellenthin (Privat) on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin (Privat). All rights reserved.
//

import Foundation

/// An entry of absence.
public class HipOutOfSchool: Codable, Equatable {
    let date: String
    let course: String
    let duration: String
    let remark: String
    let excused: String
    let semester: String
    
    public init(date: String, course: String, duration: String, remark: String, excused: String, semester: String) {
        self.date = date
        self.course = course
        self.duration = duration
        self.remark = remark
        self.excused = excused
        self.semester = semester
    }
    
    public static func == (lhs: HipOutOfSchool, rhs: HipOutOfSchool) -> Bool {
        return lhs.date == rhs.date
            && lhs.duration == rhs.duration
            && lhs.course == rhs.course
            && lhs.remark == rhs.remark
            && lhs.excused == rhs.excused
            && lhs.semester == rhs.semester
    }
}
