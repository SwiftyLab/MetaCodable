Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.define

  s.dependency 'OrderedCollections', '~> 1.0.4'

  s.dependency 'SwiftSyntax/Lib',            s.swift_syntax_constraint
  s.dependency 'SwiftSyntax/Macros',         s.swift_syntax_constraint
  s.dependency 'SwiftSyntax/Builder',        s.swift_syntax_constraint
  s.dependency 'SwiftSyntax/Diagnostics',    s.swift_syntax_constraint
  s.dependency 'SwiftSyntax/CompilerPlugin', s.swift_syntax_constraint
end
