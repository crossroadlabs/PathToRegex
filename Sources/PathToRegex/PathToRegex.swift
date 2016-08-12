//===--- PathToRegex.swift ------------------------------------------------===//
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

import Foundation
import Boilerplate
import Regex

public struct Options : OptionSet {
    public let rawValue: UInt
    
    public init(rawValue: UInt) { self.rawValue = rawValue }
    
    public static let strict = Options(rawValue: 1)
    public static let end = Options(rawValue: 2)
    public static let `default`:Options = [.end]
}

public enum TokenID {
    case literal(name:String)
    case ordinal(index:Int)
}

public enum Token {
    case simple(token:String)
    case complex(id:TokenID, prefix:String, delimeter:String, optional:Bool, repeating:Bool, pattern:String)
}

public extension Regex {
    private convenience init(patternGroups:PatternGroups, options:RegexOptions) throws {
        try self.init(pattern: patternGroups.pattern, options: options, groupNames: patternGroups.groups)
    }
    
    public convenience init(pathTokens:[Token], options:RegexOptions = [], pathOptions:Options = .`default`) throws {
        try self.init(patternGroups: tokensToPatternGroups(pathTokens, options: pathOptions), options: options)
    }
    
    public convenience init(path: String, options:RegexOptions = [], pathOptions:Options = .`default`) throws {
        try self.init(pathTokens: path.parsePath(), options: options, pathOptions: pathOptions)
    }
}

public extension String {
    /**
     * Parse a string for the raw tokens.
     *
     * @param  {string} str
     * @return {!Array}
     */
    public func parsePath() -> [Token] {
        var tokens = [Token]()
        var key = 0
        var index = self.startIndex
        var path = ""
        //    var res
        
        let match = PATH_REGEXP.findAll(in: self)
        
        for res in match {
            let m = res.matched
            
            let offset = res.range.lowerBound
            path += self.substring(with: index ..< offset)
            index = self.index(offset, offsetBy: m.characters.count)
            
            let escaped = res.group(at: 1)
            
            // Ignore already escaped sequences.
            if let escaped = escaped {
                let one = escaped.index(escaped.startIndex, offsetBy: 1)
                let end = escaped.index(one, offsetBy: 1)
                path += escaped.substring(with: one ..< end)
                continue
            }
            
            // Push the current path onto the tokens.
            if !path.isEmpty {
                tokens.append(.simple(token: path))
                path = ""
            }
            
            let prefix = res.group(at: 2)
            let name = res.group(at: 3)
            let capture = res.group(at: 4)
            let group = res.group(at: 5)
            let suffix = res.group(at: 6)
            let asterisk = res.group(at: 7)
            
            let repeating = suffix == "+" || suffix == "*"
            let optional = suffix == "?" || suffix == "*"
            let delimiter = prefix ?? "/"
            let pattern = capture.getOr(else: group.getOr(else: asterisk.map{_ in ".*"}.getOr(else: "[^" + delimiter + "]+?")))
            
            let patternEscaped = escape(group: pattern)
            let tokenName:TokenID = name.map { name in
                .literal(name: name)
                //wierd construct
                }.getOr {
                    let result:TokenID = .ordinal(index: key)
                    key += 1
                    return result
            }
            
            tokens.append(.complex(id: tokenName, prefix: prefix ?? "", delimeter: delimiter, optional: optional, repeating: repeating, pattern: patternEscaped))
        }
        
        // Match any characters still remaining.
        if (index < self.endIndex) {
            path += self.substring(from: index)
        }
        
        // If the path exists, push it onto the end.
        if !path.isEmpty {
            tokens.append(.simple(token: path))
        }
        
        return tokens
    }
}

/**
* Escape a regular expression string.
*
* @param  {string} str
* @return {string}
*/
private func escape(string str:String) -> String {
    let rr = try! Regex(pattern: "([.+*?=^!:${}()[\\\\]|\\/])")
    return rr.replaceAll(in: str, with: "\\\\$1")
}

/**
* Escape the capturing group by escaping special characters and meaning.
*
* @param  {string} group
* @return {string}
*/
private func escape(group grp:String) -> String {
    return "([=!:$\\/()])".r!.replaceAll(in: grp, with: "\\\\$1")
}

/**
* The main path matching regexp utility.
*
* @type {RegExp}
*/
private let PATH_REGEXP:Regex = [
    // Match escaped characters that would otherwise appear in future matches.
    // This allows the user to escape special characters that won't transform.
    "(\\\\.)",
    // Match Express-style parameters and un-named parameters with a prefix
    // and optional suffixes. Matches appear as:
    //
    // "/:test(\\d+)?" => ["/", "test", "\d+", undefined, "?", undefined]
    // "/route(\\d+)"  => [undefined, undefined, undefined, "\d+", undefined, undefined]
    // "/*"            => ["/", undefined, undefined, undefined, undefined, "*"]
    "([\\/.])?(?:(?:\\:(\\w+)(?:\\(((?:\\\\.|[^()])+)\\))?|\\(((?:\\\\.|[^()])+)\\))([+*?])?|(\\*))"
    ].joined(separator: "|").r!

private typealias PatternGroups = (pattern:String, groups:[String])

/**
* Expose a function for taking tokens and returning a RegExp.
*
* @param  {!Array}  tokens
* @param  {Object=} options
* @return {!RegExp}
*/
private func tokensToPatternGroups (_ tokens:[Token], options:Options) -> PatternGroups {
    let strict = options.contains(.strict)
    let end = options.contains(.end)
    
    var route = ""
    let lastToken = tokens.last
    let endsWithSlash = lastToken.map { lastToken in
        switch lastToken {
            case .simple(token: let lastToken): return lastToken =~ "\\/$"
            default: return false
        }
    }.getOr(else: false)
    
    var groups = [String]()
    
    // Iterate over the tokens and create our regexp string.
    for token in tokens {
        switch token {
            case .simple(token: let token): route += escape(string: token)
            case .complex(id: let tokenName, prefix: let prefix, delimeter: _, optional: let optional, repeating: let repeating, pattern: let pattern):
                
                switch tokenName {
                    case .literal(name: let name): groups.append(name)
                    case .ordinal(index: let index): groups.append(String(index))
                }
                
                let prefix = escape(string: prefix)
                var capture = pattern
                
                if repeating {
                    capture += "(?:" + prefix + capture + ")*"
                }
            
                if optional {
                    if prefix.isEmpty {
                        capture = "(" + capture + ")?"
                    } else {
                        capture = "(?:" + prefix + "(" + capture + "))?"
                    }
                } else {
                    capture = prefix + "(" + capture + ")"
                }
                route += capture
        }
    }
    
    // In non-strict mode we allow a slash at the end of match. If the path to
    // match already ends with a slash, we remove it for consistency. The slash
    // is valid at the end of a path match, not in the middle. This is important
    // in non-ending mode, where "/test/" shouldn't match "/test//route".
    if !strict {
        route = {
            if endsWithSlash {
                return route.substring(to: route.index(route.endIndex, offsetBy: -2))
            } else {
                return route
            }
        }() + "(?:\\/(?=$))?"
    }
    
    if end {
        route += "$"
    } else if strict && endsWithSlash {
        // In non-ending mode, we need the capturing groups to match as much as
        // possible by using a positive lookahead to the end or next path segment.
        route += "(?=\\/|$)"
    }
    
    return PatternGroups(pattern: "^" + route, groups: groups)
}
