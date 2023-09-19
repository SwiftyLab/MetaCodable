Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.define

  macro_plugin = 'CodableMacroPlugin'
  s.dependency macro_plugin, "= #{s.version}"
  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => "-Xfrontend -load-plugin-library -Xfrontend ${BUILD_DIR}/${CONFIGURATION}/lib#{macro_plugin}.dylib"
  }

  s.test_spec do |ts|
    ts.source_files = "Tests/#{s.module_name}Tests/**/*.swift"
    ts.dependency 'SwiftSyntax/MacrosTestSupport', s.swift_syntax_constraint
  end
end
