import ArgumentParser

public struct SortInitializerCommand: ParsableCommand {
  public init() {}
  
  public static let configuration = CommandConfiguration(
    commandName: "sort",
    abstract: "Sorts the initializers of the provided macro alphabetically")
}
