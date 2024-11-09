import SwiftSyntax

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

fileprivate extension AttributeListSyntax {
  /// Finds if the attribute list contains an macro with a given name
  /// - Parameter macroName: The name of the macro
  /// - Returns: True if the macro name was being used. False otherwise
  func hasMacroNamed(_ macroName: String) -> Bool {
    return contains { attribute in
      guard
        let attributeNode = attribute.as(AttributeSyntax.self),
        let attributeNameSyntax = attributeNode.attributeName.as(IdentifierTypeSyntax.self)
      else {
        return false
      }
      
      return attributeNameSyntax.name.text == macroName
    }
  }
}

/// Sorts the initializers
fileprivate final class MacroInitializerRewriter: SyntaxRewriter {
  fileprivate let macroName: String
  
  init(macroName: String) {
    self.macroName = macroName
  }
  
  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    typealias OrderedTrivia = (leadingTrivia: Trivia, trailingComma: TokenSyntax?)
    let originalParameterMetatada: [OrderedTrivia] = node.signature.parameterClause.parameters.map { ($0.leadingTrivia, $0.trailingComma) }
    
    let sortedParameters = node.signature.parameterClause.parameters.sorted {
      $0.firstName.text < $1.firstName.text
    }.enumerated().map { index, element in
      let original = originalParameterMetatada[index]
      return element
        .with(\.leadingTrivia, original.leadingTrivia)
        .with(\.trailingComma, original.trailingComma)
    }
    
    // Rewrite the nodes
    let functionParameterListNode = FunctionParameterListSyntax(sortedParameters)
    let parameterClauseNode = node.signature.parameterClause.with(\.parameters, functionParameterListNode)
    let signatureNode = node.signature.with(\.parameterClause, parameterClauseNode)
    
    let initializerNode = node.with(\.signature, signatureNode)
    return DeclSyntax(initializerNode)
  }
}
