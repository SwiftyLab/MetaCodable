Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.define(false)
  s.default_subspec = 'Macro'

  s.subspec 'Macro' do |ms|
    ms.dependency 'MetaCodableMacro', "= #{s.version}"
  end

  s.subspec 'HelperCoders' do |ms|
    ms.dependency 'MetaCodableHelperCoders', "= #{s.version}"
  end

  s.test_spec do |ts|
    ts.source_files = "Tests/#{s.name}Tests/HelperCoders/**/*.swift"
    # ts.dependency 'MetaCodableMacroPluginCore', "= #{s.version}"
    # ts.dependency 'MetaCodableMacroPlugin', "= #{s.version}"
    ts.dependency 'MetaCodable/Macro', "= #{s.version}"
    ts.dependency 'MetaCodable/HelperCoders', "= #{s.version}"
    # ts.dependency 'SwiftSyntax/MacrosTestSupport', s.swift_syntax_constraint

    macro_spec = Pod::Specification.from_file(File.join(File.dirname(__FILE__), 'MetaCodableMacro.podspec'))
    ts.pod_target_xcconfig = macro_spec.attributes_hash['user_target_xcconfig']
  end
end
