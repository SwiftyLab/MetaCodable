Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.module_name = "MacroPlugin"
  s.define
  s.dependency 'MetaCodableMacroPluginCore', "= #{s.version}"
  s.dependency 'SwiftSyntax/Lib', s.swift_syntax_constraint
  s.dependency 'SwiftSyntax/Macros', s.swift_syntax_constraint
  s.dependency 'SwiftSyntax/CompilerPlugin', s.swift_syntax_constraint
end
