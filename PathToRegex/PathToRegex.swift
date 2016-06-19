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

private extension Optional {
    func orElse(@autoclosure other:() -> Wrapped) -> Wrapped {
        guard let result = self else {
            return other()
        }
        return result
    }
}

public struct Options {
    public var strict:Bool = false
    public var end:Bool = true
}

public enum TokenName {
    case Literal(name:String)
    case Ordinal(index:Int)
}

public enum Token {
    case Simple(token:String)
    case Complex(name:TokenName, prefix:String, delimeter:String, optional:Bool, repeating:Bool, pattern:String)
}

/**
* Escape a regular expression string.
*
* @param  {string} str
* @return {string}
*/
func escapeString(str:String) -> String {
    let rr = try! Regex(pattern: "([.+*?=^!:${}()[\\\\]|\\/])")
    return rr.replaceAll(in: str, with: "\\\\$1")
}

/**
* Escape the capturing group by escaping special characters and meaning.
*
* @param  {string} group
* @return {string}
*/
func escapeGroup (group:String) -> String {
    return "([=!:$\\/()])".r!.replaceAll(in: group, with: "\\\\$1")
}

/**
* The main path matching regexp utility.
*
* @type {RegExp}
*/
let PATH_REGEXP:Regex = [
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

/**
* Parse a string for the raw tokens.
*
* @param  {string} str
* @return {!Array}
*/
public func parse (str:String) -> [Token] {
    var tokens = [Token]()
    var key = 0
    var index = str.startIndex
    var path = ""
//    var res
    
    let match = PATH_REGEXP.findAll(in: str)
    
    for res in match {
        let m = res.matched
        
        let offset = res.range.startIndex
        path += str.substring(with: index ..< offset)
        index = offset.advanced(by: m.characters.count)
        
        let escaped = res.group(at: 1)
        
        // Ignore already escaped sequences.
        if let escaped = escaped {
            let one = escaped.startIndex.advanced(by: 1)
            path += escaped.substring(with: one ..< one.advanced(by: 1))
            continue
        }
    
        // Push the current path onto the tokens.
        if !path.isEmpty {
            tokens.append(.Simple(token: path))
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
        let delimiter = prefix.orElse("/")
        let pattern = capture.orElse(group.orElse(asterisk.map{_ in ".*"}.orElse("[^" + delimiter + "]+?")))
        
        let patternEscaped = escapeGroup(pattern)
        let tokenName:TokenName = name.map { name in
            TokenName.Literal(name: name)
            //wierd construct
        }.orElse( {
            let result:TokenName = TokenName.Ordinal(index: key)
            key += 1
            return result
        }())
        
        tokens.append(.Complex(name: tokenName, prefix: prefix.orElse(""), delimeter: delimiter, optional: optional, repeating: repeating, pattern: patternEscaped))
    }
    
    // Match any characters still remaining.
    if (index < str.endIndex) {
        path += str.substring(from: index)
    }
    
    // If the path exists, push it onto the end.
    if !path.isEmpty {
        tokens.append(.Simple(token: path))
    }
    
    return tokens
}

/**
* Expose a function for taking tokens and returning a RegExp.
*
* @param  {!Array}  tokens
* @param  {Object=} options
* @return {!RegExp}
*/
func tokensToRegex (tokens:[Token], options:Options = Options()) throws -> Regex {
    let strict = options.strict
    let end = options.end
    var route = ""
    let lastToken = tokens.last
    let endsWithSlash = lastToken.map { lastToken in
        switch lastToken {
            case .Simple(token: let lastToken): return lastToken =~ "\\/$"
            default: return false
        }
    }.orElse(false)
    
    var groups = [String]()
    
    // Iterate over the tokens and create our regexp string.
    for token in tokens {
        switch token {
            case .Simple(token: let token): route += escapeString(token)
            case .Complex(name: let tokenName, prefix: let prefix, delimeter: _, optional: let optional, repeating: let repeating, pattern: let pattern):
                
                switch tokenName {
                    case .Literal(name: let name): groups.append(name)
                    case .Ordinal(index: let index): groups.append(String(index))
                }
                
                let prefix = escapeString(prefix)
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
                return route.substring(to: route.endIndex.advanced(by: -2))
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
    
    return try Regex(pattern: "^" + route, groupNames: groups)
}

public func pathToRegex(path:String) throws -> Regex {
    let tokens = parse(path)
    return try tokensToRegex(tokens)
}