//
//  HipCourse.swift
//  hipleech
//
//  Created by Thomas Mellenthin (Privat) on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin (Privat). All rights reserved.
//

import Foundation

public class HipCourse: Codable, Equatable {
    public let name: String
    private var grades: [HipGrade]
    
    public init(name: String, grades: [HipGrade]) {
        self.name = name
        self.grades = grades
    }
    
    func addGrade(_ grade: HipGrade) {
        grades.append(grade)
    }
    
    public var allGrades: [HipGrade] {
        grades.sorted(by: {  $0.date < $1.date  })
    }
    
    public static func == (lhs: HipCourse, rhs: HipCourse) -> Bool {
        return lhs.name == rhs.name && lhs.grades == rhs.grades
    }
    
    /// Diffs two courses. The difference is returned as new course or nil, if both courses are requal.
    public static func diff(lhs: HipCourse, rhs: HipCourse) -> HipCourse? {
        let diffGrades: [HipGrade]
        if #available(macOS 15, *) {
            diffGrades = lhs.grades.difference(from: rhs.grades).map { (change) -> HipGrade in
                switch change {
                case .insert(offset: _, element: let element, associatedWith: _):
                    return element
                case .remove(offset: _, element: let element, associatedWith: _):
                    return element
                }
            }
        } else {
            let lhSet = Set(lhs.grades)
            let rhSet = Set(rhs.grades)
            let foo = lhSet.symmetricDifference(rhSet)
            diffGrades = Array(foo).sorted(by: { $0.date < $1.date })
        }
        if diffGrades.count > 0 {
            return HipCourse(name: (lhs.name == rhs.name ? lhs.name : lhs.name + " ☠️ " + rhs.name) , grades: diffGrades)
        }
        return nil
    }
    
    public func prettyName(format: OutputFormat = .ascii) -> String {
        //Name starts with something like "en - English", we want to cut the first chars
        let idx = (name.firstIndex(of: "-") ) ?? name.startIndex
        let bold = format == .markdown ? "*" : ""
        let fullName = String(name[name.index(after: idx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(bold)\(fullName)\(bold)"
    }
    
    public func prettyText(format: OutputFormat = .ascii) -> String {
        let text = """
                   \(prettyName(format: format))\(format == .ascii ? "\n------------------------" : "")
                   \(grades.map { $0.prettyText(format: format) }.joined(separator: "\n"))
                   """
        return text
    }

    public func prettyTextWithAverage(format: OutputFormat = .ascii) -> String {
        let averageString = String(format: "%.01f", currentAverage)
        let text = """
                   \(prettyText(format: format))
                   
                   Durchschnitt: \(averageString)
                   
                   """
        return text
    }
    
    /// Average over the whole year
    public var average: Double {
        // count all valid (non-nil) grades
        let gradeCount = grades.map { $0.points }.compactMap{ $0 }.reduce(0) { sum, nextPoint in sum + 1 }
        guard gradeCount > 0 else {return 0 }

        let averagePoints =  Double(grades.compactMap { $0.points }.reduce(0) { $0 + $1 }) / Double(gradeCount)
        
        return (17 - averagePoints)  / 3
    }

    /// Average for the current Semester
    public var currentAverage: Double {
        let firstSemesterGrades = grades.filter({ HipSemester.first == $0.semester })
        let secondSemesterGrades = grades.filter({ HipSemester.second == $0.semester })
        // there are second semester grades? Use 2nd, else use the first semester grades
        let relevantGrades = secondSemesterGrades.count > 0 ? secondSemesterGrades : firstSemesterGrades
        // count all valid (non-nil) grades
        let gradeCount = relevantGrades
            .map { $0.points }
            .compactMap{ $0 }
            .reduce(0) { sum, nextPoint in sum + 1 }
        guard gradeCount > 0 else {return 0 }

        let averagePoints =  Double(relevantGrades.compactMap { $0.points }.reduce(0) { $0 + $1 }) / Double(gradeCount)
        
        return (17 - averagePoints)  / 3
    }
}
