// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
//===--- Package.swift ------------------------------------------------===//
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

import PackageDescription

let package = Package(
    name: "PathToRegex",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "PathToRegex",
            targets: ["PathToRegex"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/crossroadlabs/Regex.git",
            from: "1.2.0")
    ],
    targets: [
        .target(
            name: "PathToRegex",
            dependencies: []),
        .testTarget(
            name: "PathToRegexTests",
            dependencies: ["PathToRegex"])
    ]
)
