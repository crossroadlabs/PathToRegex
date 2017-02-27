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
    targets: [
        Target(
            name: "PathToRegex"
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/crossroadlabs/Regex.git", "1.0.0-alpha.1"),
        .Package(url: "https://github.com/crossroadlabs/Boilerplate.git", "1.0.0"),
    ]
)
