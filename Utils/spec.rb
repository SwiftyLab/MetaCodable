require 'json'

module MetaCodable
  module Spec
    def define(has_files = true)
      podspec_path = caller.find do |trace|
        File.extname(trace.split(":")[0]).eql?('.podspec')
      end.split(":")[0]

      podspec = File.basename(podspec_path, File.extname(podspec_path))
      package = JSON.parse(File.read('package.json'), {object_class: OpenStruct})

      self.name              = podspec
      self.version           = package.version.to_s
      self.homepage          = package.homepage
      self.summary           = package.summary
      self.description       = package.description
      self.license           = { :type => package.license, :file => 'LICENSE' }
      self.social_media_url  = package.author.url
      self.readme            = "#{self.homepage}/blob/main/README.md"
      self.changelog         = "#{self.homepage}/blob/main/CHANGELOG.md"
      self.documentation_url = "https://swiftylab.github.io/MetaCodable/#{self.version}/documentation/#{self.module_name.downcase}/"

      self.source            = {
        package.repository.type.to_sym => package.repository.url,
        :tag => "v#{self.version}"
      }

      self.authors           = {
        package.author.name => package.author.email
      }

      self.swift_version             = '5.0'
      self.ios.deployment_target     = '13.0'
      self.macos.deployment_target   = '10.15'
      self.tvos.deployment_target    = '13.0'
      self.watchos.deployment_target = '6.0'
      self.osx.deployment_target     = '10.15'

      if has_files
        self.preserve_paths = "{Sources,Tests}/#{self.module_name}*/**/*", "*.md"
        self.source_files   = "Sources/#{self.module_name}/**/*.*"
      end
    end

    def swift_syntax_constraint
      return '~> 509.0.0-swift-DEVELOPMENT-SNAPSHOT-2023-06-05-a'
    end
  end
end
