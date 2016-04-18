//===--- PathToRegexTests.swift -------------------------------------------===//
//
//Copyright (c) 2016 Daniel Leping (dileping)
//
//This file is part of PathToRegex.
//
//PathToRegex is free software: you can redistribute it and/or modify
//it under the terms of the GNU Lesser General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//PathToRegex is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU Lesser General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with PathToRegex.  If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//

import XCTest
import Regex
@testable import PathToRegex

class PathToRegexTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPaths() {
        let digitOptionalVar = try! pathToRegex("/:test(\\d+)?")
        XCTAssert("/123" =~ digitOptionalVar)
        XCTAssert("/" =~ digitOptionalVar)
        XCTAssertFalse("/asd" =~ digitOptionalVar)
        
        XCTAssertEqual("123", digitOptionalVar.findFirst("/123")!.group("test")!)
        
        let routeDigitEnding = try! pathToRegex("/route(\\d+)")
        XCTAssertFalse("/123" =~ routeDigitEnding)
        XCTAssert("/route123" =~ routeDigitEnding)
        XCTAssertFalse("/route" =~ routeDigitEnding)
        
        let everythingStartingSlash = try! pathToRegex("/*")
        XCTAssert("/route123" =~ everythingStartingSlash)
        XCTAssert("/route" =~ everythingStartingSlash)
        XCTAssert("/" =~ everythingStartingSlash)
        XCTAssert("/123" =~ everythingStartingSlash)
        XCTAssert("/123/123/123" =~ everythingStartingSlash)
        
        let twoVars = try! pathToRegex("/:one/:two")
        XCTAssert("/route/123" =~ twoVars)
        XCTAssertFalse("/route" =~ twoVars)
        XCTAssertFalse("/route/" =~ twoVars)
        XCTAssertFalse("/route/123/and" =~ twoVars)
        
        XCTAssertEqual("route", twoVars.findFirst("/route/123")!.group("one")!)
        XCTAssertEqual("123", twoVars.findFirst("/route/123")!.group("two")!)
        
        let methodFormat = try! pathToRegex("/api/user/:id.:format")
        XCTAssertEqual("123", methodFormat.findFirst("/api/user/123.json")!.group("id")!)
        XCTAssertEqual("json", methodFormat.findFirst("/api/user/123.json")!.group("format")!)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
