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

    func testPaths() {
        let digitOptionalVar = try! Regex(path: "/:test(\\d+)?")
        XCTAssert("/123" =~ digitOptionalVar)
        XCTAssert("/" =~ digitOptionalVar)
        XCTAssertFalse("/asd" =~ digitOptionalVar)
        
        XCTAssertEqual("123", digitOptionalVar.findFirst(in: "/123")!.group(named: "test")!)
        
        let routeDigitEnding = try! Regex(path: "/route(\\d+)")
        XCTAssertFalse("/123" =~ routeDigitEnding)
        XCTAssert("/route123" =~ routeDigitEnding)
        XCTAssertFalse("/route" =~ routeDigitEnding)
        
        let everythingStartingSlash = try! Regex(path: "/*")
        XCTAssert("/route123" =~ everythingStartingSlash)
        XCTAssert("/route" =~ everythingStartingSlash)
        XCTAssert("/" =~ everythingStartingSlash)
        XCTAssert("/123" =~ everythingStartingSlash)
        XCTAssert("/123/123/123" =~ everythingStartingSlash)
        
        let twoVars = try! Regex(path: "/:one/:two")
        XCTAssert("/route/123" =~ twoVars)
        XCTAssertFalse("/route" =~ twoVars)
        XCTAssertFalse("/route/" =~ twoVars)
        XCTAssertFalse("/route/123/and" =~ twoVars)
        
        XCTAssertEqual("route", twoVars.findFirst(in: "/route/123")!.group(named: "one")!)
        XCTAssertEqual("123", twoVars.findFirst(in: "/route/123")!.group(named: "two")!)
        
        let methodFormat = try! Regex(path: "/api/user/:id.:format")
        XCTAssertEqual("123", methodFormat.findFirst(in: "/api/user/123.json")!.group(named: "id")!)
        XCTAssertEqual("json", methodFormat.findFirst(in: "/api/user/123.json")!.group(named: "format")!)
    } 
}

#if os(Linux)
extension PathToRegexTests {
	static var allTests : [(String, (PathToRegexTests) -> () throws -> Void)] {
		return [
			("testPaths", testPaths),
		]
	}
}
#endif
