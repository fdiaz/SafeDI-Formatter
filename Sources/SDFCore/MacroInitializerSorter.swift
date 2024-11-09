import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftParser

struct MacroInitializerSorter {
  let macroName: String
  
  init(macroName: String) {
    self.macroName = macroName
  }
  
  ///  Runs the sorter on the provided Swift file, sorting the initializer parameters alphabetically
  ///
  /// - Parameter fileURL: The path to the Swift file
  /// - Returns: A source accurate description of the Swift file at the fileURL
  @discardableResult
  func run(on fileURL: URL) async throws -> String {
    // TODO: Potentially optimize performance by discarding Swift files that do not use the macro.
    
    let original = try String(contentsOfFile: fileURL.path, encoding: .utf8)
    let updated = try await run(onContent: original)
    
    guard original != updated else { return  original }
    
    try updated.write(to: fileURL, atomically: false, encoding: .utf8)
    return updated
    
  }
  
  @discardableResult
  func run(onContent content: String) async throws -> String {
    let sourceFile = Parser.parse(source: content)
    let rewriter = MacroFilteringRewriter(macroName: macroName)
    let sourceFileNode = rewriter.visit(sourceFile)
    return sourceFileNode.description
  }
}
