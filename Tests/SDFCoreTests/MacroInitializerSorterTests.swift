import Foundation
import Testing
@testable import SDFCore

final class MacroInitializerSorterTests {
  let sut = MacroInitializerSorter(macroName: "TestMacro")
  
  @Test(
    "With an initializer without the macro, it does not modify the source",
    arguments: TestData.NoMacro.allCases)
  func run_doesNotSort(content: TestData.NoMacro) async throws {
    try await #expect(sut.run(onContent: content.rawValue) == content.rawValue)
  }
  
  @Test(
    "With a type that uses the macro, it sorts the init parameters",
    arguments: TestData.WithMacro.allCases)
  func run_doesSort(content: TestData.WithMacro) async throws {
    try await #expect(sut.run(onContent: content.rawValue).contains("init(a: Int, b: String"))
  }
  
  @Test(
    "With an type that uses the macro and has a multi line initializer. It sorts the init parameters",
    arguments: TestData.WithMacroMultiline.allCases)
  func run_doesSortMultiLine(content: TestData.WithMacroMultiline) async throws {
    let expected = """
      init(a: Int, 
           b: String) {}
    """
    try await #expect(sut.run(onContent: content.rawValue).contains(expected))
  }
}

struct TestData {
  enum NoMacro: String, CaseIterable {
    case actorContent = """
    actor Some {
      init(b: String, a: Int) {}
    }
    """
    case classContent = """
    class Some {
      init(b: String, a: Int) {}
    }
    """
    case structContent = """
      struct Some {
        init(b: String, a: Int) {}
      }
    """
  }
  
  enum WithMacro: String, CaseIterable {
    case actorContent = """
    @TestMacro
    actor Some {
      init(b: String, a: Int) {}
    }
    """
    case classContent = """
    @TestMacro
    class Some {
      init(b: String, a: Int) {}
    }
    """
    case structContent = """
    @TestMacro
      struct Some {
        init(b: String, a: Int) {}
      }
    """
  }
  
  enum WithMacroMultiline: String, CaseIterable {
    case actorContent = """
    @TestMacro
    actor Some {
      init(b: String, 
           a: Int) {}
    }
    """
    case classContent = """
    @TestMacro
    class Some {
      init(b: String, 
           a: Int) {}
    }
    """
    case structContent = """
    @TestMacro
    struct Some {
      init(b: String, 
           a: Int) {}
    }
    """
  }
}
