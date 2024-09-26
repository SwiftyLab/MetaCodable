#!/usr/bin/env ruby

SDK = `xcrun --show-sdk-path`.strip!
CONFIGURATION = ENV['CONFIGURATION'].downcase
TOOLCHAIN = ENV['TOOLCHAIN']
SRCROOT = ENV['SRCROOT']
BUILD_DIR = ENV['BUILD_DIR']

puts "swift build --configuration #{CONFIGURATION} --product MacroPlugin --sdk \"#{SDK}\" --toolchain \"#{TOOLCHAIN}\" --package-path \"#{SRCROOT}\" --scratch-path \"#{BUILD_DIR}/Macros/MacroPlugin\""

system("swift build --configuration #{CONFIGURATION} --product MacroPlugin --sdk \"#{SDK}\" --toolchain \"#{TOOLCHAIN}\" --package-path \"#{SRCROOT}\" --scratch-path \"#{BUILD_DIR}/Macros/MacroPlugin\"")
