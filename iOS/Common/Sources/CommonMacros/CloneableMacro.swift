import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public struct CloneableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // Ensure we are applying this to a class or struct
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            // You could also support StructDeclSyntax here if needed
            return []
        }

        let className = classDecl.name.text
        
        // Find all stored properties (variables with names)
        let members = declaration.memberBlock.members
        let variableNames = members.compactMap { member -> String? in
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { return nil }
            
            // Filter: Ignore computed properties and static properties
            // This is a simplified check; complex apps might check for accessors
            if varDecl.modifiers.contains(where: { $0.name.text == "static" }) { return nil }
            
            return varDecl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
        }

        // Generate: clone(into other: MyData)
        let cloneIntoMethod = try FunctionDeclSyntax("func clone(into other: \(raw: className))") {
            for name in variableNames {
                // Generate: other.name = self.name
                ExprSyntax("other.\(raw: name) = self.\(raw: name)")
            }
        }

        // Generate: cloned() -> Self
        // Note: This assumes a default init() exists.
        let clonedMethod = try FunctionDeclSyntax("func cloned() -> Self") {
            ExprSyntax("let copy = Self.init()")
            ExprSyntax("self.clone(into: copy)")
            ExprSyntax("return copy")
        }

        return [
            DeclSyntax(clonedMethod),
            DeclSyntax(cloneIntoMethod)
        ]
    }
    
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        return []
    }
}
