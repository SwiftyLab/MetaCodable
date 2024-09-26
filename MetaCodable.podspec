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

  s.test_spec 'HelperCodersTests' do |ts|
    ts.source_files = "Tests/#{s.name}Tests/**/*.swift"
    ts.exclude_files = "Tests/#{s.name}Tests/DynamicCodable/**/*.swift"
    ts.dependency 'MetaCodableMacroPluginCore', "= #{s.version}"
    ts.dependency 'MetaCodableMacroPlugin', "= #{s.version}"
    ts.dependency 'MetaCodable/Macro', "= #{s.version}"
    ts.dependency 'MetaCodable/HelperCoders', "= #{s.version}"
    ts.dependency 'SwiftSyntax/MacrosTestSupport', *s.swift_syntax_constraint

    macro_spec = Pod::Specification.from_file(File.join(File.dirname(__FILE__), 'MetaCodableMacro.podspec'))
    xcconfig = macro_spec.attributes_hash['user_target_xcconfig']
    xcconfig['OTHER_SWIFT_FLAGS'] = "#{xcconfig['OTHER_SWIFT_FLAGS']} -Xfrontend -package-name -Xfrontend MetaCodable -Xfrontend -swift-version -Xfrontend 6"
    ts.pod_target_xcconfig = xcconfig
  end
end
