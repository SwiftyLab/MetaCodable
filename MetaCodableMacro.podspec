Pod::Spec.new do |s|
  require_relative 'Utils/spec'
  s.extend MetaCodable::Spec
  s.module_name = "MetaCodable"
  s.define

  sources_dir = 'Sources'
  plugin_module = 'MacroPlugin'
  manifest_file = 'Package.swift'
  plugin_core = 'PluginCore'

  preserved_sources = "{#{manifest_file},#{sources_dir}/{#{plugin_module},#{plugin_core}}/**/*.swift}"
  inputs = Dir.glob(preserved_sources).map { |path| "$(PODS_TARGET_SRCROOT)/#{path}" }
  build_path = "${PODS_BUILD_DIR}/#{plugin_module}"
  plugin_path = "#{build_path}/release/#{plugin_module}##{plugin_module}"
  plugin_output = "$(PODS_BUILD_DIR)/#{plugin_module}/release/#{plugin_module}"
  script = <<-SCRIPT.squish
  env -i HOME="$HOME" $METACODABLE_PLUGIN_BUILD_ENVIRONMENT
  "$SHELL" -l -c "swift build -c release --product #{plugin_module}
  --sdk \\"`xcrun --show-sdk-path`\\"
  --package-path \\"$PODS_TARGET_SRCROOT\\"
  --scratch-path \\"#{build_path}\\""
  SCRIPT

  s.preserve_paths = manifest_file, "#{sources_dir}/{#{plugin_module},#{plugin_core}}"
  s.script_phase = {
    :name => 'Build MetaCodable macro plugin',
    :script => script,
    :input_files => inputs, :output_files => [plugin_output],
    :execution_position => :before_compile
  }

  s.user_target_xcconfig = {
    'OTHER_SWIFT_FLAGS' => "-Xfrontend -load-plugin-executable -Xfrontend #{plugin_path}",
    'METACODABLE_PLUGIN_BUILD_ENVIRONMENT' => 'METACODABLE_BEING_USED_FROM_COCOAPODS=true'
  }
end
