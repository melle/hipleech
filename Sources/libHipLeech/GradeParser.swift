//
//  GradeParser.swift
//  hipleech
//
//  Created by Thomas Mellenthin on 13.02.20.
//  Copyright © 2020 Thomas Mellenthin. All rights reserved.
//

import Foundation
import SwiftSoup

public class GradeParser {
    
    public enum ParserError: Error {
        case exception(Error)
    }
    
    public static func parse(html: String) -> Result<HipTree, GradeParser.ParserError>  {
        
        do {
            let doc: Document = try SwiftSoup.parse(html)
            
            let courses = try doc.select("h3").array()
            let grades = try doc.select("table.t02").array()
            assert(courses.count == grades.count)
            
            let tree: HipTree = HipTree()
            for i in 0..<grades.count {
                let e = grades[i]
                
                let rows = try e.getElementsByTag("tr")
                for row in rows {
                    let col = try row.getElementsByTag("td").array()
                    guard col.count != 0 else { continue }
                    if col.count == 5 {
                        let grade = HipGrade(date: try col[0].text(),
                                           grade: try col[1].text(),
                                           remark: try col[2].text(),
                                           weight: try col[3].text(),
                                           semester: try col[4].text())
                        let courseName = try courses[i].text()
                        if let course = tree.courses.filter({ $0.name == courseName  }).first {
                            course.addGrade(grade)
                        } else {
                            let course = HipCourse(name: courseName, grades: [grade])
                            tree.courses.append(course)
                        }
                    } else if try courses[i].text() == "Fehltage" {
                        let oos = HipOutOfSchool(date: try col[0].text(),
                                                 course: "Kompletter Schultag",
                                                 duration: "Ganzer Tag",
                                                 remark: try col[1].text(),
                                                 excused: try col[2].text(),
                                                 semester: try col[3].text())
                        tree.oos.append(oos)
                    } else if try courses[i].text() == "Fehlstunden" {
                        let oos = HipOutOfSchool(date: try col[0].text(),
                                                 course: try col[1].text(),
                                                 duration: try col[2].text(),
                                                 remark: try col[3].text(),
                                                 excused: try col[4].text(),
                                                 semester: try col[5].text())
                        tree.oos.append(oos)
                    } else if try courses[i].text() == "Zusammenfassung" {
                        let summary = HipSummary(key: try col[0].text(),
                                            value: try col[1].text())
                        tree.summary.append(summary)
                    } else {
                        print("⚠️ Ignoring Row \(try row.text())")
                    }
                }
            }
            return .success(tree)
        }
        catch {
            return .failure(.exception(error))
        }
    }
}
