#
#  Be sure to run `pod spec lint AmplifyTestCommon.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "AmplifyTestCommon"
  s.version      = "0.9.0"
  s.summary      = "Test resources used by different targets"
  s.description  = "Provides different test resources and mock methods"

  s.homepage     = "https://aws.amazon.com/amplify/"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
  s.platform     = :ios, '11.0'
  s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => s.version}
  
  s.requires_arc   = true
  s.swift_versions = '5.1'

  AMPLIFY_VERSION = '0.9.0'
  AMPLIFY_PLUGINS_CORE_VERSION = '0.9.0'

  s.source_files = 'AmplifyTestCommon/**/*.swift'
  s.dependency 'Amplify', AMPLIFY_VERSION

  s.subspec 'AWSPluginsTestCommon' do |ss|
    ss.source_files = 'AmplifyPlugins/Core/AWSPluginsTestCommon/**/*.swift'
    s.dependency 'AWSPluginsCore', AMPLIFY_PLUGINS_CORE_VERSION
  end
end