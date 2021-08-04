#
#  Be sure to run `pod spec lint AmplifyTestCommon.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

# Version definitions
$AMPLIFY_VERSION = '1.13.0'
$AMPLIFY_RELEASE_TAG = "v#{$AMPLIFY_VERSION}"

$AWS_SDK_VERSION = '2.24.0'
$OPTIMISTIC_AWS_SDK_VERSION = "~> #{$AWS_SDK_VERSION}"

Pod::Spec.new do |s|
  s.name         = "AmplifyTestCommon"
  s.version      = $AMPLIFY_VERSION
  s.summary      = "Test resources used by different targets"

  s.description  = "Provides different test resources and mock methods"

  s.homepage     = "hhttps://github.com/aws-amplify/amplify-ios"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
  s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => $AMPLIFY_RELEASE_TAG }

  s.platform     = :ios, '11.0'
  s.swift_version = '5.0'

  s.source_files = 'AmplifyTestCommon/**/*.swift'

  s.dependency 'Amplify', $AMPLIFY_VERSION

  s.subspec 'AWSPluginsTestCommon' do |ss|
    ss.source_files = 'AmplifyPlugins/Core/AWSPluginsTestCommon/**/*.swift'
    ss.dependency 'AWSPluginsCore', $AMPLIFY_VERSION
    ss.dependency 'AWSMobileClient', $OPTIMISTIC_AWS_SDK_VERSION
    ss.dependency 'AWSCore', $OPTIMISTIC_AWS_SDK_VERSION
  end

end
