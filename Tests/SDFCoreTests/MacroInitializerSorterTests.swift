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

  @Test(
    "With an type that uses the macro that defines a nested type with an unsorted initializer. It sorts the outer init parameters",
    arguments: TestData.WithNestedDefinitions.allCases)
  func run_doesSortOuterWhenNestedPresent(content: TestData.WithNestedDefinitions) async throws {
    let expected = """
      init(a: Int, 
           b: String) {}
    """
    try await #expect(sut.run(onContent: content.rawValue).contains(expected))
  }

  @Test(
    "With an type that uses the macro that defines a nested type with an unsorted initializer. It does not sort the nested init parameters",
    arguments: TestData.WithNestedDefinitions.allCases)
  func run_doesNotSortNested(content: TestData.WithNestedDefinitions) async throws {
    let expected = """
        init(b: String,
             a: Int) {}
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

  enum WithNestedDefinitions: String, CaseIterable {
    case actorContent = """
    @TestMacro
    actor Outer {
      actor Some {
        init(b: String,
             a: Int) {}
      }
      init(b: String, 
           a: Int) {}
    }
    """
    case classContent = """
    @TestMacro
    class Outer {
      class Some {
        init(b: String,
             a: Int) {}
      }
      init(b: String, 
           a: Int) {}
    }
    """
    case structContent = """
    @TestMacro
    struct Outer {
      struct Some {
        init(b: String,
             a: Int) {}
      }
      init(b: String, 
           a: Int) {}
    }
    """
  }
}
