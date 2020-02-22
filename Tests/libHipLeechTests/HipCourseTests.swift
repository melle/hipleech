//
//  HipCourseTests.swift
//  hipleechTests
//
//  Created by Thomas Mellenthin (Privat) on 13.02.20.
//  Copyright © 2020 Thomas Mellenthin (Privat). All rights reserved.
//

import XCTest
import libHipLeech

class HipCourseTests: XCTestCase {

    func testPrettyText() {
        // given
        let mark1 = HipGrade(date: "05.02.2020",
                             grade: "2+",
                             remark: "Test Bruchrechnung",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let mark2 = HipGrade(date: "06.02.2020",
                             grade: "3",
                             remark: "Klassenarbeit",
                             weight: "Standard / Einfach",
                             semester: "1.")
        let ma = HipCourse(name: "ma - Mathematik", grades: [mark1, mark2])

        // when
        let result = ma.prettyTextWithAverage()
        
        // then
        XCTAssertEqual(result,
                                """
                                Mathematik
                                ------------------------
                                2+\tTest Bruchrechnung (05.02.2020)
                                3\tKlassenarbeit (06.02.2020)

                                Durchschnitt: 2.3

                                """
        )
    }
    
    func testAverage() {
        // given
        let grade1 = HipGrade(date: "", grade: "2+", remark: "", weight: "", semester: "")
        let grade2 = HipGrade(date: "", grade: "2", remark: "", weight: "", semester: "")
        let grade3 = HipGrade(date: "", grade: "2-", remark: "", weight: "", semester: "")
        let grade4 = HipGrade(date: "", grade: "1", remark: "", weight: "", semester: "")
        let grade5 = HipGrade(date: "", grade: "3", remark: "", weight: "", semester: "")

        let ma = HipCourse(name: "ma - Mathematik", grades: [grade1, grade2, grade3, grade4, grade5])

        // then
        XCTAssertEqual(ma.average, 2.0)        
    }
}
