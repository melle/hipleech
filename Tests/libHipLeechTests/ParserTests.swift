//
//  ParserTests.swift
//  hipleech
//
//  Created by Thomas Mellenthin on 02.02.20.
//  Copyright © 2020 Thomas Mellenthin. All rights reserved.
//

import XCTest
import libHipLeech
import SwiftSoup

class ParserTests: XCTestCase {
        
    func testParser() throws {
        // when
        let result = GradeParser.parse(html: file(named: #function, extension: "html"))
        guard case .success(let tree) = result else { XCTFail(); return }
        
        let courses = tree.courses
        let german = courses.filter({ $0.name == "de - Deutsch"}).first!
        
        // then
        XCTAssertEqual(courses.count, 11)
        XCTAssertEqual(german.allGrades.count, 9)
        XCTAssertEqual(german.allGrades.last!.remark, "Epochalnote 1. HJ")
    }
}
