//
//  HipGradeTests.swift
//  hipleechTests
//
//  Created by Thomas Mellenthin (Privat) on 13.02.20.
//  Copyright © 2020 Thomas Mellenthin (Privat). All rights reserved.
//

import XCTest
import libHipLeech

class HipGradeTests: XCTestCase {
    
    func testMarkInPoints() {
        XCTAssertEqual(15, HipGrade(date: "", grade: "1+", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(14, HipGrade(date: "", grade: "1", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(13, HipGrade(date: "", grade: "1-", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(12, HipGrade(date: "", grade: "2+", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(11, HipGrade(date: "", grade: "2", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(10, HipGrade(date: "", grade: "2-", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(9, HipGrade(date: "", grade: "3+", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(8, HipGrade(date: "", grade: "3", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(7, HipGrade(date: "", grade: "3-", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(6, HipGrade(date: "", grade: "4+", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(5, HipGrade(date: "", grade: "4", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(4, HipGrade(date: "", grade: "4-", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(3, HipGrade(date: "", grade: "5+", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(2, HipGrade(date: "", grade: "5", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(1, HipGrade(date: "", grade: "5-", remark: "", weight: "", semester: "").points)
        XCTAssertEqual(0, HipGrade(date: "", grade: "6", remark: "", weight: "", semester: "").points)

        // everything else will become nil
        XCTAssertNil(HipGrade(date: "", grade: "A", remark: "", weight: "", semester: "").points)
        XCTAssertNil(HipGrade(date: "", grade: "AAAAAAAAAAAAAAAAAAAAAAAAAAAA", remark: "", weight: "", semester: "").points)
    }
    
    func testPrettyPrint() {
        // when
        let mark = HipGrade(date: "21.02.2019", grade: "3+", remark: "Testnote in Grinsen", weight: "Einfach / Standard", semester: "1.")
        
        // then
        XCTAssertEqual("3+\tTestnote in Grinsen (21.02.2019)", mark.prettyText())
    }
    
    func testPointsToGrades() {
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 666), "??")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 16), "??")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: -1), "??")

        XCTAssertEqual(HipGrade.pointsAsGrade(points: 15), "1+")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 14), "1")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 13), "1-")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 12), "2+")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 11), "2")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 10), "2-")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 9), "3+")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 8), "3")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 7), "3-")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 6), "4+")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 5), "4")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 4), "4-")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 3), "5+")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 2), "5")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 1), "5-")
        XCTAssertEqual(HipGrade.pointsAsGrade(points: 0), "6")
    }
}
