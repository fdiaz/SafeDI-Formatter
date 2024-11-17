import SwiftOperators
import SwiftSyntax

private typealias Assignment = (
  leftOperand: String, item: CodeBlockItemSyntax, group: AssignmentGroupType
)

/// Filters the nodes to visit. It only visits structures that have the provided macro, ignores all others.
final class MacroFilteringRewriter: SyntaxRewriter {
  private let rewriter: MacroInitializerRewriter

  init(macroName: String) {
    self.rewriter = MacroInitializerRewriter(macroName: macroName)
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard node.attributes.hasMacroNamed(rewriter.macroName) else {
      return super.visit(node)
    }
    return rewriter.visit(node)
  }

  override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    guard node.attributes.hasMacroNamed(rewriter.macroName) else {
      return super.visit(node)
    }
    return rewriter.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard node.attributes.hasMacroNamed(rewriter.macroName) else {
      return super.visit(node)
    }
    return rewriter.visit(node)
  }
}

extension AttributeListSyntax {
  /// Finds if the attribute list contains an macro with a given name
  /// - Parameter macroName: The name of the macro
  /// - Returns: True if the macro name was being used. False otherwise
  fileprivate func hasMacroNamed(_ macroName: String) -> Bool {
    return contains { attribute in
      guard
        let attributeNode = attribute.as(AttributeSyntax.self),
        let attributeNameSyntax = attributeNode.attributeName.as(
          IdentifierTypeSyntax.self)
      else {
        return false
      }

      return attributeNameSyntax.name.text == macroName
    }
  }
}

/// Sorts the initializers
private final class MacroInitializerRewriter: SyntaxRewriter {
  fileprivate let macroName: String
  private var typeDeclsEncountered = 0

  init(macroName: String) {
    self.macroName = macroName
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard typeDeclsEncountered == 1 else {
      return super.visit(node)
    }

    let updatedInitializerNode = sortParameters(node)
    guard let body = updatedInitializerNode.body else {
      return DeclSyntax(updatedInitializerNode)
    }

    let updatedBody = sortBodyAssignment(body)
    return DeclSyntax(updatedInitializerNode.with(\.body, updatedBody))
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    typeDeclsEncountered += 1
    return super.visit(node)
  }

  override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    typeDeclsEncountered += 1
    return super.visit(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    typeDeclsEncountered += 1
    return super.visit(node)
  }

  override func visitPost(_ node: Syntax) {
    if StructDeclSyntax(node) != nil || ActorDeclSyntax(node) != nil
      || ClassDeclSyntax(node) != nil
    {
      typeDeclsEncountered -= 1
    }
    super.visitPost(node)
  }

  private func sortParameters(_ node: InitializerDeclSyntax)
    -> InitializerDeclSyntax
  {
    typealias OrderedTrivia = (
      leadingTrivia: Trivia, trailingComma: TokenSyntax?
    )
    let originalParameterMetatada: [OrderedTrivia] = node.signature
      .parameterClause.parameters.map { ($0.leadingTrivia, $0.trailingComma) }

    let sortedParameters = node.signature.parameterClause.parameters.sorted {
      $0.firstName.text < $1.firstName.text
    }.enumerated().map { index, element in
      let original = originalParameterMetatada[index]
      return
        element
        .with(\.leadingTrivia, original.leadingTrivia)
        .with(\.trailingComma, original.trailingComma)
    }

    // Rewrite the nodes
    let functionParameterListNode = FunctionParameterListSyntax(
      sortedParameters)
    let parameterClauseNode = node.signature.parameterClause.with(
      \.parameters, functionParameterListNode)
    let signatureNode = node.signature.with(
      \.parameterClause, parameterClauseNode)

    return node.with(\.signature, signatureNode)
  }

  private func sortBodyAssignment(_ body: CodeBlockSyntax) -> CodeBlockSyntax {
    var groupedAssignments = GroupedAssignments()

    // We need to fold the operators to get better information about the SequenceExpr node.  https://github.com/swiftlang/swift-syntax/blob/df28b99b5942bcf78b337bd15eafd8c80508d258/Sources/SwiftOperators/SwiftOperators.docc/SwiftOperators.md#quickstart
    let opPrecedence = OperatorTable.standardOperators

    for statement in body.statements {
      // Group all statements that start with `self.` in an array
      if let item = SequenceExprSyntax(statement.item),
        let foldedNode = try? opPrecedence.foldSingle(item),
        let infixOperand = InfixOperatorExprSyntax(foldedNode),
        infixOperand.leftOperand.trimmed.description.starts(with: "self.")
      {
        let assignment = Assignment(
          leftOperand: infixOperand.leftOperand.description,
          item: statement,
          group: .selfAssignments)
        groupedAssignments.insert(assignment)
      } else {
        let assignment = Assignment(
          leftOperand: "",
          item: statement,
          group: .otherAssignments)
        groupedAssignments.insert(assignment)
      }
    }

    let codeBlockItemSyntaxArray = groupedAssignments.toCodeBlockSyntasItemArray()

    let codeBlockListSyntax = CodeBlockItemListSyntax(codeBlockItemSyntaxArray)
    return body.with(\.statements, codeBlockListSyntax)
  }
}

private struct GroupedAssignments {
  private var lastInsertedType: AssignmentGroupType = .none
  private(set) var assignments: [[Assignment]] = []

  mutating func insert(_ assignment: Assignment) {
    switch lastInsertedType {
    case .none:
      assignments.append([assignment])
    default:
      let currentArray: [Assignment]
      if lastInsertedType == assignment.group {
        currentArray = assignments.removeLast() + [assignment]
      } else {
        currentArray = [assignment]
      }

      assignments.append(currentArray)
    }

    lastInsertedType = assignment.group
  }

  func toCodeBlockSyntasItemArray() -> [CodeBlockItemSyntax] {
    assignments.reduce([]) { partialResult, assignment in
      guard let group = assignment.first?.group, group == .selfAssignments else {
        return partialResult + assignment.map(\.item)
      }
      return partialResult
        + assignment
        .sorted { $0.leftOperand < $1.leftOperand }
        .map(\.item)
    }
  }
}

private enum AssignmentGroupType: Equatable {
  case none
  case selfAssignments
  case otherAssignments
}
