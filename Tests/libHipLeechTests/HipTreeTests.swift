//
//  HipTreeTests.swift
//  hipleechTests
//
//  Created by Thomas Mellenthin on 13.02.20.
//  Copyright © 2020 Thomas Mellenthin. All rights reserved.
//

import XCTest
import libHipLeech

class HipTreeTests: XCTestCase {
    
        
    func testTwoNewGradesInTwoDifferentCourses() throws {
        // given
        let erGrade = HipGrade(date: "05.02.2020",
                             grade: "1",
                             remark: "Tag der offenen Tür prak. Note",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let er = HipCourse(name: "er - Evangelische Religionslehre", grades: [erGrade])
        let enGrade = HipGrade(date: "29.01.2020",
                             grade: "1",
                             remark: "vocabulary picture poster",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let en = HipCourse(name: "en - Englisch", grades: [enGrade])
        let expectedTree = HipTree()
        expectedTree.courses.append(contentsOf: [en, er])

        let resultBefore = GradeParser.parse(html: file(named: "\(#function)Before", extension: "html"))
        guard case .success(let treeBefore) = resultBefore else { XCTFail(); return }

        let resultAfter = GradeParser.parse(html: file(named: "\(#function)After", extension: "html"))
        guard case .success(let treeAfter) = resultAfter else { XCTFail(); return }

        // when
        let resultTree = HipTree.diff(oldTree: treeBefore, newTree: treeAfter)
        
        // then
        XCTAssertEqual(expectedTree, resultTree)
    }
    
    func testTwoNewGradesTheSameCourses() throws {
        // given
        let grade1 = HipGrade(date: "05.02.2020",
                             grade: "2+",
                             remark: "Test Bruchrechnung",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let grade2 = HipGrade(date: "06.02.2020",
                             grade: "3",
                             remark: "Klassenarbeit",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let ma = HipCourse(name: "ma - Mathematik", grades: [grade1, grade2])

        let expectedTree = HipTree()
        expectedTree.courses.append(contentsOf: [ma])

        let resultBefore = GradeParser.parse(html: file(named: "\(#function)Before", extension: "html"))
        guard case .success(let treeBefore) = resultBefore else { XCTFail(); return }

        let resultAfter = GradeParser.parse(html: file(named: "\(#function)After", extension: "html"))
        guard case .success(let treeAfter) = resultAfter else { XCTFail(); return }

        // when
        let resultTree = HipTree.diff(oldTree: treeBefore, newTree: treeAfter)
        
        // then
        XCTAssertEqual(expectedTree, resultTree, "expected\n\(expectedTree.asJSON)\n\nresult\n\(resultTree.asJSON)")
    }
    
    func testTwoNewGradesInANewCours() throws {
        // given -
        let grade1 = HipGrade(date: "05.02.2020",
                             grade: "2+",
                             remark: "Test Bruchrechnung",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let grade2 = HipGrade(date: "06.02.2020",
                             grade: "3",
                             remark: "Klassenarbeit",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let ma = HipCourse(name: "ma - Mathematik", grades: [grade1, grade2])

        let expectedTree = HipTree()
        expectedTree.courses.append(contentsOf: [ma])

        let resultBefore = GradeParser.parse(html: file(named: "\(#function)Before", extension: "html"))
        guard case .success(let treeBefore) = resultBefore else { XCTFail(); return }

        let resultAfter = GradeParser.parse(html: file(named: "\(#function)After", extension: "html"))
        guard case .success(let treeAfter) = resultAfter else { XCTFail(); return }

        // when
        let resultTree = HipTree.diff(oldTree: treeBefore, newTree: treeAfter)
        
        // then
        XCTAssertEqual(expectedTree, resultTree)
    }
    
    func testJsonExport() throws{
        // given
        let grade1 = HipGrade(date: "05.02.2020",
                             grade: "2+",
                             remark: "Test Bruchrechnung",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let grade2 = HipGrade(date: "06.02.2020",
                             grade: "3",
                             remark: "Klassenarbeit",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let ma = HipCourse(name: "ma - Mathematik", grades: [grade1, grade2])
        let inputTree = HipTree()
        inputTree.courses.append(contentsOf: [ma])
        
        let expected = file(named: #function, extension: "json")

        // when
        let sut = inputTree.asJSON
        
        // then
        XCTAssertEqual(sut, expected)
    }

    
    func testJsonImport() throws{
        // given
        let grade1 = HipGrade(date: "05.02.2020",
                             grade: "2+",
                             remark: "Test Bruchrechnung",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let grade2 = HipGrade(date: "06.02.2020",
                             grade: "3",
                             remark: "Klassenarbeit",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let ma = HipCourse(name: "ma - Mathematik", grades: [grade1, grade2])
        let expected = HipTree()
        expected.courses.append(contentsOf: [ma])

        let json = file(named: #function, extension: "json")

        // when
        let sut = HipTree.from(json: json.data(using: .utf8) ?? Data())
        
        // then
        XCTAssertEqual(sut, expected)
    }

}
