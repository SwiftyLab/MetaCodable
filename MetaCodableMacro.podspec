Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.module_name = "MetaCodable"
  s.define

  sources_dir = 'Sources'
  plugin_module = 'MacroPlugin'
  manifest_file = 'Package.swift'
  plugin_core = 'PluginCore'

  script_path = 'Utils/macro_plugin_build.sh'
  config = ENV['METACODABLE_COCOAPODS_LINT'] ? "debug" : "release"
  preserved_sources = "{#{manifest_file},#{sources_dir}/{#{plugin_module},#{plugin_core}}/**/*.swift,#{script_path}}"
  inputs = Dir.glob(preserved_sources).map { |path| "$(PODS_TARGET_SRCROOT)/#{path}" }
  build_path = "${PODS_BUILD_DIR}/Macros/#{plugin_module}"
  plugin_path = "#{build_path}/#{config}/#{plugin_module}##{plugin_module}"
  plugin_output = "$(PODS_BUILD_DIR)/Macros/#{plugin_module}/#{config}/#{plugin_module}"
  script = <<-SCRIPT
  echo "env -i PATH=\\"$PATH\\" SRCROOT=\\"$PODS_TARGET_SRCROOT\\" BUILD_DIR=\\"$PODS_BUILD_DIR\\" TOOLCHAIN=\\"$DT_TOOLCHAIN_DIR\\" CONFIG=#{config} $METACODABLE_PLUGIN_BUILD_ENVIRONMENT \\"${PODS_TARGET_SRCROOT}/#{script_path}\\""
  env -i PATH="$PATH" SRCROOT="$PODS_TARGET_SRCROOT" BUILD_DIR="$PODS_BUILD_DIR" TOOLCHAIN="$DT_TOOLCHAIN_DIR" CONFIG=#{config} $METACODABLE_PLUGIN_BUILD_ENVIRONMENT "${PODS_TARGET_SRCROOT}/#{script_path}"
  SCRIPT

  s.preserve_paths = "*.md", "LICENSE", manifest_file, "#{sources_dir}/{#{plugin_module},#{plugin_core}}", script_path
  s.script_phase = {
    :name => 'Build MetaCodable macro plugin',
    :script => script,
    :input_files => inputs, :output_files => [plugin_output],
    :execution_position => :before_compile
  }

  xcconfig = {
    'OTHER_SWIFT_FLAGS' => "-Xfrontend -load-plugin-executable -Xfrontend #{plugin_path}",
    'METACODABLE_PLUGIN_BUILD_ENVIRONMENT' => 'METACODABLE_BEING_USED_FROM_COCOAPODS=true'
  }
  s.user_target_xcconfig = xcconfig
  s.pod_target_xcconfig = xcconfig
end
