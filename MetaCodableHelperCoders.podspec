Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.module_name = "HelperCoders"
  s.define
  s.dependency 'MetaCodableMacro', "= #{s.version}"

  s.pod_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => "-Xfrontend -package-name -Xfrontend MetaCodable",
  }
end
