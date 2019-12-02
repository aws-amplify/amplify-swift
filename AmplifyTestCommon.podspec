#
#  Be sure to run `pod spec lint AmplifyTestCommon.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "AmplifyTestCommon"
  spec.version      = "0.9.0"
  spec.summary      = "Test resources used by different targets"
  spec.description  = "Provides different test resources and mock methods"

  spec.homepage     = "https://aws.amazon.com/amplify/"
  spec.license      = 'Apache License, Version 2.0'
  spec.author       = { 'Amazon Web Services' => 'amazonwebservices' }
  spec.platform     = :ios, '11.0'
  spec.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => spec.version}
  
  spec.requires_arc = true

  spec.source_files = 'AmplifyTestCommon/**/*.swift'
  spec.dependency 'Amplify', '0.9.0'

  spec.subspec 'AWSPluginsTestCommon' do |subspec|
    subspec.source_files = 'AmplifyPlugins/Core/AWSPluginsTestCommon/**/*.swift'
    spec.dependency 'AWSPluginsCore', '0.9.0'
  end
end
