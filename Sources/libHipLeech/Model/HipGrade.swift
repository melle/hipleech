//
//  HipGrade.swift
//  hipleech
//
//  Created by Thomas Mellenthin (Privat) on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin (Privat). All rights reserved.
//

import Foundation

public enum HipSemester: String, RawRepresentable, Codable {
    case first = "1."
    case second = "2."
}

/// A single grade, one can get in a course.
public class HipGrade: Codable, Equatable, Hashable {
    
    public let date: Date
    private let dateString: String
    public let points: Int?
    public let remark: String
    public let weight: String
    public let semester: HipSemester
    
    public init(date: String, grade: String, remark: String, weight: String, semester: String) {

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "dd.MM.yyyy"
        self.date = dateFormatter.date(from:date) ?? Date()

        self.dateString = date
        self.points = HipGrade.gradeAsPoints(grade: grade)
        self.remark = remark
        self.weight = weight
        self.semester = HipSemester(rawValue: semester) ?? .first
    }

    public static func == (lhs: HipGrade, rhs: HipGrade) -> Bool {
        return lhs.date == rhs.date
            && lhs.points == rhs.points
            && lhs.remark == rhs.remark
            && lhs.weight == rhs.weight
            && lhs.semester == rhs.semester
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(points ?? Int.max)
        hasher.combine(remark)
        hasher.combine(weight)
        hasher.combine(semester)
    }
    
    public static func gradeAsPoints(grade: String) -> Int? {
        // FIXME: better:  17 – (3 * mark), then add/sub 1 for +/-
        switch grade {
        case "1+": return 15
        case "1": return 14
        case "1-": return 13
        case "2+": return 12
        case "2": return 11
        case "2-": return 10
        case "3+": return 9
        case "3": return 8
        case "3-": return 7
        case "4+": return 6
        case "4": return 5
        case "4-": return 4
        case "5+": return 3
        case "5": return 2
        case "5-": return 1
        case "6": return 0
        default: return nil
        }
    }
    
    public static func pointsAsGrade(points: Int) -> String {
        guard points >= 0 && points <= 15 else { return "??" }
        
        let mark = (17 - Double(points)) / 3.0
        let remainer = (17 - points) / 3
        
        let modifier: String
        if mark == Double(remainer) || points == 0 {
            modifier = ""
        } else if (mark - Double(remainer)) < 0.5 {
            modifier = "-"
        } else {
            modifier = "+"
        }
        
        return "\(Int(mark.rounded()))\(modifier)"
    }
    
    public func prettyText(format: OutputFormat = .ascii) -> String {
        let bold = (format == .markdown) ? "*" : ""
        return "\(bold)\(points.map { HipGrade.pointsAsGrade(points:$0) } ?? "A")\(bold)\t\(remark) (\(dateString))"
    }
}
