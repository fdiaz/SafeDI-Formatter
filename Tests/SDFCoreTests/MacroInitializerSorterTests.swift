import Foundation
import Testing

@testable import SDFCore

final class MacroInitializerSorterTests {
  struct PropertiesTests {
    let sut = MacroInitializerSorter(macroName: "TestMacro")

    @Test(
      "With an initializer without the macro, it does not modify the source",
      arguments: TestData.NoMacro.allCases)
    func run_doesNotSort(content: TestData.NoMacro) async throws {
      try await #expect(
        sut.run(onContent: content.rawValue) == content.rawValue)
    }

    @Test(
      "With a type that uses the macro, it sorts the init parameters",
      arguments: TestData.WithMacro.allCases)
    func run_doesSort(content: TestData.WithMacro) async throws {
      try await #expect(
        sut.run(onContent: content.rawValue).contains("init(a: Int, b: String"))
    }

    @Test(
      "With a type that uses the macro and has a multi line initializer. It sorts the init parameters",
      arguments: TestData.WithMacroMultiline.allCases)
    func run_doesSortMultiLine(content: TestData.WithMacroMultiline)
      async throws
    {
      let expected = """
          init(a: Int, 
               b: String) {}
        """
      try await #expect(sut.run(onContent: content.rawValue).contains(expected))
    }

    @Test(
      "With a type that uses the macro that defines a nested type with an unsorted initializer. It sorts the outer init parameters",
      arguments: TestData.WithNestedDefinitions.allCases)
    func run_doesSortOuterWhenNestedPresent(
      content: TestData.WithNestedDefinitions
    ) async throws {
      let expected = """
          init(a: Int, 
               b: String) {}
        """
      try await #expect(sut.run(onContent: content.rawValue).contains(expected))
    }

    @Test(
      "With a type that uses the macro that defines a nested type with an unsorted initializer. It does not sort the nested init parameters",
      arguments: TestData.WithNestedDefinitions.allCases)
    func run_doesNotSortNested(content: TestData.WithNestedDefinitions)
      async throws
    {
      let expected = """
            init(d: String,
                 c: Int) {}
        """
      try await #expect(sut.run(onContent: content.rawValue).contains(expected))
    }

    @Test(
      "With a type that uses the macro inside of another type. It sorts the inner init parameters",
      arguments: TestData.WithNestedDefinitionMacroInside.allCases)
    func run_doesSortInnerWhenNested(
      content: TestData.WithNestedDefinitionMacroInside
    ) async throws {
      let expected = "    init(c: Int, d: String) {}"
      try await #expect(sut.run(onContent: content.rawValue).contains(expected))
    }

    @Test(
      "With a type that uses the macro inside of another type. It does not sort the outer init parameters",
      arguments: TestData.WithNestedDefinitionMacroInside.allCases)
    func run_doesNotSortOuterNested(
      content: TestData.WithNestedDefinitionMacroInside
    ) async throws {
      let expected = "  init(b: String, a: Int) {}"
      try await #expect(sut.run(onContent: content.rawValue).contains(expected))
    }

  }

  struct AssignmentTests {
    let sut = MacroInitializerSorter(macroName: "TestMacro")

    @Test(
      "With a self assignments in the intitializer. It sorts them",
      arguments: TestData.types
    )
    func run_sortsAssignments(type: String) async throws {
      let content = """
        @TestMacro
        \(type) Some {
          init(a: Int, b: String) {
            self.b = b
            self.a = a
          }
        }
        """
      let expected = """
            self.a = a
            self.b = b
        """
      #expect(try await sut.run(onContent: content).contains(expected))
    }

    @Test(
      "With self assignments and other values in the intitializer. It sorts them with all the self assignments on top",
      arguments: TestData.types
    )
    func run_sortsAssignmentsWithOther(type: String) async throws {
      let content = """
        @TestMacro
        \(type) Some {
          init(a: Int) {
            b = Type()
            self.a = a
          }
        }
        """
      let expected = """
            self.a = a
            b = Type()
        """
      #expect(try await sut.run(onContent: content).contains(expected))
    }

    @Test(
      "With self assignments and block statements in the intitializer. It sorts them with all the self assignments on top",
      arguments: TestData.types
    )
    func run_sortsAssignmentsWithBlockStatements(type: String) async throws {
      let content = """
        @TestMacro
        \(type) Some {
          init(a: Int) {
            b = Type { some in
              some.doSomething()
            }
            self.a = a
          }
        }
        """
      let expected = """
            self.a = a
            b = Type { some in
              some.doSomething()
            }
        """
      #expect(try await sut.run(onContent: content).contains(expected))
    }
  }
}

struct TestData {
  static let types: [String] = ["actor", "class", "struct"]

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
          init(d: String,
               c: Int) {}
        }
        init(b: String, 
             a: Int) {}
      }
      """
    case classContent = """
      @TestMacro
      class Outer {
        class Some {
          init(d: String,
               c: Int) {}
        }
        init(b: String, 
             a: Int) {}
      }
      """
    case structContent = """
      @TestMacro
      struct Outer {
        struct Some {
          init(d: String,
               c: Int) {}
        }
        init(b: String, 
             a: Int) {}
      }
      """
  }

  enum WithNestedDefinitionMacroInside: String, CaseIterable {
    case actorContent = """
      actor Outer {
        @TestMacro
        actor Inner {
          init(d: String, c: Int) {}
        }
        init(b: String, a: Int) {}
      }
      """
    case classContent = """
      class Outer {
        @TestMacro
        class Inner {
          init(d: String, c: Int) {}
        }
        init(b: String, a: Int) {}
      }
      """
    case structContent = """
      struct Outer {
        @TestMacro
        struct Inner {
          init(d: String, c: Int) {}
        }
        init(b: String, a: Int) {}
      }
      """
  }
}
