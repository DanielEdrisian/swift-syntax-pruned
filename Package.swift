// swift-tools-version:5.9

import Foundation
import PackageDescription

let package = Package(
  name: "swift-syntax",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .macCatalyst(.v13),
  ],
  products: [
    .library(name: "SwiftCompilerPlugin", targets: ["SwiftCompilerPlugin"]),
    .library(name: "SwiftSyntaxBuilder", targets: ["SwiftSyntaxBuilder"]),
    .library(name: "SwiftSyntaxMacros", targets: ["SwiftSyntaxMacros"]),
  ],
  targets: [
    // MARK: - Internal helper targets
    .target(
      name: "_SwiftSyntaxCShims"
    ),

    // MARK: - Library targets
    // Formatting style:
    //  - One section for each target and its test target
    //  - Sections are sorted alphabetically
    //  - Each target argument takes exactly one line, unless there are external dependencies.
    //    In that case package and internal dependencies are on different lines.
    //  - All array elements are sorted alphabetically

    // MARK: SwiftBasicFormat

    .target(
      name: "SwiftBasicFormat",
      dependencies: ["SwiftSyntax"],
      exclude: ["CMakeLists.txt"]
    ),

    // MARK: SwiftCompilerPlugin

    .target(
      name: "SwiftCompilerPlugin",
      dependencies: ["SwiftCompilerPluginMessageHandling", "SwiftSyntaxMacros"],
      exclude: ["CMakeLists.txt"]
    ),

    // MARK: SwiftCompilerPluginMessageHandling

    .target(
      name: "SwiftCompilerPluginMessageHandling",
      dependencies: [
        "_SwiftSyntaxCShims",
        "SwiftDiagnostics",
        "SwiftOperators",
        "SwiftParser",
        "SwiftSyntax",
        "SwiftSyntaxMacros",
        "SwiftSyntaxMacroExpansion",
      ],
      exclude: ["CMakeLists.txt"]
    ),

    // MARK: SwiftDiagnostics

    .target(
      name: "SwiftDiagnostics",
      dependencies: ["SwiftSyntax"],
      exclude: ["CMakeLists.txt"]
    ),
    
    // MARK: SwiftSyntax

    .target(
      name: "SwiftSyntax",
      dependencies: ["_SwiftSyntaxCShims", "SwiftSyntax509", "SwiftSyntax510", "SwiftSyntax600"],
      exclude: ["CMakeLists.txt"],
      swiftSettings: swiftSyntaxSwiftSettings
    ),

    // MARK: Version marker modules

    .target(
      name: "SwiftSyntax509",
      path: "Sources/VersionMarkerModules/SwiftSyntax509"
    ),

    .target(
      name: "SwiftSyntax510",
      path: "Sources/VersionMarkerModules/SwiftSyntax510"
    ),

    .target(
      name: "SwiftSyntax600",
      path: "Sources/VersionMarkerModules/SwiftSyntax600"
    ),

    // MARK: SwiftSyntaxBuilder

    .target(
      name: "SwiftSyntaxBuilder",
      dependencies: ["SwiftBasicFormat", "SwiftParser", "SwiftDiagnostics", "SwiftParserDiagnostics", "SwiftSyntax"],
      exclude: ["CMakeLists.txt"],
      swiftSettings: swiftSyntaxBuilderSwiftSettings
    ),

    // MARK: SwiftSyntaxMacros

    .target(
      name: "SwiftSyntaxMacros",
      dependencies: ["SwiftDiagnostics", "SwiftParser", "SwiftSyntax", "SwiftSyntaxBuilder"],
      exclude: ["CMakeLists.txt"]
    ),

    // MARK: SwiftSyntaxMacroExpansion

    .target(
      name: "SwiftSyntaxMacroExpansion",
      dependencies: ["SwiftSyntax", "SwiftSyntaxBuilder", "SwiftSyntaxMacros", "SwiftDiagnostics", "SwiftOperators"],
      exclude: ["CMakeLists.txt"]
    ),

    // MARK: SwiftParser

    .target(
      name: "SwiftParser",
      dependencies: ["SwiftSyntax"],
      exclude: ["CMakeLists.txt", "README.md"],
      swiftSettings: swiftParserSwiftSettings
    ),

    // MARK: SwiftParserDiagnostics

    .target(
      name: "SwiftParserDiagnostics",
      dependencies: ["SwiftBasicFormat", "SwiftDiagnostics", "SwiftParser", "SwiftSyntax"],
      exclude: ["CMakeLists.txt"]
    ),

    // MARK: SwiftOperators

    .target(
      name: "SwiftOperators",
      dependencies: ["SwiftDiagnostics", "SwiftParser", "SwiftSyntax"],
      exclude: [
        "CMakeLists.txt"
      ]
    ),
  ],
  swiftLanguageVersions: [.v5, .version("6")]
)

// This is a fake target that depends on all targets in the package.
// We need to define it manually because the `SwiftSyntax-Package` target doesn't exist for `swift build`.

package.targets.append(
  .target(
    name: "SwiftSyntax-all",
    dependencies: package.targets.compactMap {
      if $0.type == .test {
        return nil
      } else {
        return .byName(name: $0.name)
      }
    }
  )
)

// MARK: - Parse build arguments

func hasEnvironmentVariable(_ name: String) -> Bool {
  return ProcessInfo.processInfo.environment[name] != nil
}

/// Set when building swift-syntax using swift-syntax-dev-utils or in Swift CI in general.
///
/// Modifies the build in the following ways
///  - Enables assertions even in release builds
///  - Removes the dependency of swift-syntax on os_log
var buildScriptEnvironment: Bool { hasEnvironmentVariable("SWIFT_BUILD_SCRIPT_ENVIRONMENT") }

/// Check that the layout of the syntax tree is correct.
///
/// See CONTRIBUTING.md for more information
var rawSyntaxValidation: Bool { hasEnvironmentVariable("SWIFTSYNTAX_ENABLE_RAWSYNTAX_VALIDATION") }

/// Mutate the input of `assertParse` test cases.
///
/// See CONTRIBUTING.md for more information
var alternateTokenIntrospection: Bool { hasEnvironmentVariable("SWIFTPARSER_ENABLE_ALTERNATE_TOKEN_INTROSPECTION") }

/// Assume that swift-argument-parser is checked out next to swift-syntax and use that instead of fetching a remote dependency.
var useLocalDependencies: Bool { hasEnvironmentVariable("SWIFTCI_USE_LOCAL_DEPS") }

// MARK: - Compute custom build settings

// These build settings apply to the target and the corresponding test target.
var swiftSyntaxSwiftSettings: [SwiftSetting] {
  var settings: [SwiftSetting] = []
  if buildScriptEnvironment {
    settings.append(.define("SWIFTSYNTAX_ENABLE_ASSERTIONS"))
  }
  if rawSyntaxValidation {
    settings.append(.define("SWIFTSYNTAX_ENABLE_RAWSYNTAX_VALIDATION"))
  }
  return settings
}
var swiftSyntaxBuilderSwiftSettings: [SwiftSetting] {
  if buildScriptEnvironment {
    return [.define("SWIFTSYNTAX_NO_OSLOG_DEPENDENCY")]
  } else {
    return []
  }
}
var swiftParserSwiftSettings: [SwiftSetting] {
  if alternateTokenIntrospection {
    return [.define("SWIFTPARSER_ENABLE_ALTERNATE_TOKEN_INTROSPECTION")]
  } else {
    return []
  }
}
