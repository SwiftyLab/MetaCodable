#!/usr/bin/ruby

system('brew install tuist')
Dir.chdir('Examples') do
  system('tuist generate --no-open')
  system('pod install')

  platform = ARGV.empty? ? 'macOS' : ARGV[0]
  system("tuist build MetaCodable#{platform} -- -configuration Debug")
end
