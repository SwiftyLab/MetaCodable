Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.module_name = "HelperCoders"
  s.define
  s.dependency 'MetaCodableMacro', "= #{s.version}"
end
