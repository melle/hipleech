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
        diffTree.dah = HipDogAteHomework.diff(lhs: oldTree.dah, rhs: newTree.dah)
        
        return diffTree
    }
    
    public func course(named: String) -> HipCourse? {
        return courses.filter({ $0.name == named }).first
    }
    
    public func prettyText(format: OutputFormat = .ascii, usePoints: Bool) -> String {
        let courses = courses.map { $0.prettyText(format: format, usePoints: usePoints) }
        
        let dahBody = dah.map { $0.prettyText(format: format) }
        let dahHeadline = """
                          🐶 The dog ate my homework 📝
                          -----------------------------
                          """
        let dah: [String] = (dahBody.count > 0 ? [dahHeadline] : []) + dahBody
        
        return (courses + dah).joined(separator: "\n\n")
    }
    
    public func prettyTextWithAverage(format: OutputFormat = .ascii, scoreFormat: ScoreFormat) -> String {
        let coursesText = courses.map { $0.prettyText(format: format, usePoints: scoreFormat == .points) }.joined(separator: "\n\n")
        let averageText = String(format: "%0.1f", average(currentSemesterOnly: false, scoreFormat: scoreFormat))
        
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
    
    public func average(currentSemesterOnly: Bool, scoreFormat: ScoreFormat) -> Double {
        // count all valid (non-nil) grades
        let allPoints = allPoints(currentSemesterOnly: currentSemesterOnly)
        let gradeCount = allPoints.count
        guard gradeCount > 0 else { return 0 }
        let averagePoints =  Double(allPoints.reduce(0) { $0 + $1 }) / Double(gradeCount)
        
        switch scoreFormat {
        case .grades:
            // Points -> grade
            return (17 - averagePoints)  / 3
        case .points:
            return averagePoints
        }
    }
    
    public var asJSON: String {
        let je = JSONEncoder.init()
        je.outputFormatting = [.prettyPrinted, .sortedKeys]
        var json = ""
        do {
            let jsonData = try je.encode(self)
            json = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            print(error.localizedDescription)
        }
        return json
    }
    
    public var totalPoints: Int {
        let allPoints = allPoints(currentSemesterOnly: false)
        let gradeCount = allPoints.count
        guard gradeCount > 0 else { return 0 }
        let totalPoints =  allPoints.reduce(0) { $0 + $1 }
        return totalPoints
    }
    
    private func allPoints(currentSemesterOnly: Bool) -> [Int] {
        func include(grade: HipGrade, currentSemesterOnly: Bool) -> Bool {
            // semester filer && ignore all non-grades like "A"
            return (currentSemesterOnly ? grade.semester == currentSemester : true) // && grade.points != nil
        }

        guard courses.count > 0 else { return [] }
        let allGrades: [HipGrade] = courses
            .map{ $0.allGrades }
            .flatMap { $0 } // flatten the 2 dimensional array
            .filter { include(grade: $0, currentSemesterOnly: false) }

        // count all valid (non-nil) grades
        let allPoints: [Int] = allGrades.compactMap { $0.points }
        return allPoints
    }
}
