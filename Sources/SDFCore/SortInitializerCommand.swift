import ArgumentParser
import Foundation

@main
public struct SortInitializerCommand: AsyncParsableCommand {
  public init() {}
  
  public static let configuration = CommandConfiguration(
    commandName: "sort",
    abstract: "Sorts the initializers of the provided macro alphabetically")
  
  @Option(help: "The name of the macro to sort.")
  var macro: String = "Instantiable"
  
  @Argument(
    help: "The path to a Swift file or directory containing Swift files",
    transform: URL.init(fileURLWithPath:))
  var path: URL
  
  public mutating func run() async throws {
    let swiftFiles = FileManager.default.swiftFiles(at: path)
    
    guard !swiftFiles.isEmpty else {
      throw CleanExit.message("No .swift files found at \(path.path). Exiting.")
    }
    
    for file in swiftFiles {
      let sorter = MacroInitializerSorter(macroName: macro)
      try await sorter.run(on: file)
    }
  }
}
