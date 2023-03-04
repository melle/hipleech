//
//  HipTree.swift
//  hipleech
//
//  Created by Thomas Mellenthin on 12.02.20.
//  Copyright © 2020 Thomas Mellenthin. All rights reserved.
//

import Foundation

/// A tree of courses with grades and other stuff like, out of school entries, forgotten homework and a summary.
public class HipTree: Codable, Equatable {
    public var courses: [HipCourse] = []
    public var oos:[HipOutOfSchool] = []
    public var dah:[HipDogAteHomework] = []
    public var summary: [HipSummary] = []
    
    public init() {
        
    }
    
    public static func from(json: Data) -> HipTree {
        let jd = JSONDecoder()
        do {
            return try jd.decode(HipTree.self, from: json)
        } catch {
            print(error.localizedDescription)
            return HipTree()
        }
    }
    
    public static func == (lhs: HipTree, rhs: HipTree) -> Bool {
        return lhs.courses == rhs.courses
            && lhs.oos == rhs.oos
            && lhs.dah == rhs.dah
            && lhs.summary == rhs.summary
    }

    // Assumes, that the rhs tree contains more data
    public static func diff(oldTree: HipTree, newTree: HipTree) -> HipTree {
        let diffTree = HipTree()

        let diffCourses: [HipCourse] = newTree.courses.compactMap { (newCourse) in
            if let oldCourse = oldTree.course(named: newCourse.name) {
                return HipCourse.diff(lhs: oldCourse, rhs: newCourse)
            }
            return newCourse
        }

        diffTree.courses.append(contentsOf: diffCourses)
        
        return diffTree
    }
    
    public func course(named: String) -> HipCourse? {
        return courses.filter({ $0.name == named }).first
    }
    
    public func prettyText(format: OutputFormat = .ascii) -> String {
        return courses.map { $0.prettyText(format: format) }.joined(separator: "\n\n")
    }
    
    public func prettyTextWithAverage(format: OutputFormat = .ascii) -> String {
        let coursesText = courses.map { $0.prettyText(format: format) }.joined(separator: "\n\n")
        let averageText = String(format: "%0.1f", totalAverage)
        
        return """
               \(coursesText)

               Gesamt - Alle Fächer
               ------------------------
               Durchschnitt: \(averageText)
               """
    }

    public var currentSemester: HipSemester {
        // find any course with a grade for the second semester -> second
        guard courses.contains(where: { course in
            course.allGrades.contains { grade in grade.semester == .second }
        }) else {
            // no grade for the second semester
            return .first
        }
        // there is at least one grade for the second semester
        return .second
    }
    
    public var totalAverage: Double {
        guard courses.count > 0 else { return 0 }

        return courses.reduce(0) { (result, course) in result + course.average  } / Double(courses.count)
    }

    public var currentSemesterAverage: Double {
        guard courses.count > 0 else { return 0 }
        let currentSemester = currentSemester
        let allGrades: [HipGrade] = courses.reduce([]) { partialResult, course in
            course.allGrades.filter { grade in
                grade.semester == currentSemester
            }
        }
        // count all valid (non-nil) grades
        let gradeCount = allGrades.count
        guard gradeCount > 0 else { return 0 }

        let averagePoints =  Double(allGrades.compactMap { $0.points }.reduce(0) { $0 + $1 }) / Double(gradeCount)
        // Points -> grade
        return (17 - averagePoints)  / 3
    }

    public var asJSON: String {
        let je = JSONEncoder.init()
        je.outputFormatting = .prettyPrinted
        var json = ""
        do {
            let jsonData = try je.encode(self)
            json = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print(error.localizedDescription)
        }
        return json
    }
}
