import FrontEnd

extension AssociatedTypeDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = AssociatedTypeDocumentation 
}
extension AssociatedValueDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = AssociatedValueDocumentation 
}
extension TypeAliasDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = TypeAliasDocumentation 
}
extension BindingDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = BindingDocumentation 
}
extension OperatorDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = OperatorDocumentation 
}


extension FunctionDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = FunctionDocumentation 
}
extension MethodDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = MethodDeclDocumentation
}
extension MethodImpl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = MethodImplDocumentation
}
extension SubscriptDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = SubscriptDeclDocumentation
}
extension SubscriptImpl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = SubscriptImplDoc
}
extension InitializerDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = InitializerDocumentation
}


extension TranslationUnit : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = SourceFileAsset
}
extension ModuleDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = ModuleAsset
}
extension TraitDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = TraitDocumentation
}
extension ProductTypeDecl : HasAssociatedDocumentationTypes {
  public typealias DocumentationT = ProductTypeDocumentation
}
