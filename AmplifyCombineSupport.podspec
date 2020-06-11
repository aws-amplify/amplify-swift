#
#  Be sure to run `pod spec lint AWSS3StoragePlugin.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  AMPLIFY_VERSION = '1.0.1'

  s.name         = 'AmplifyCombineSupport'
  s.version      = AMPLIFY_VERSION
  s.summary      = 'Amazon Web Services Amplify for iOS.'

  s.description  = 'AWS Amplify for iOS provides a declarative library for application development using cloud services'

  s.homepage     = 'https://aws.amazon.com/amplify/'
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
  s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => "v#{s.version}" }

  s.platform = :ios, '13.0'
  s.swift_version = '5.0'

  s.dependency 'Amplify', AMPLIFY_VERSION

  s.source_files = 'AmplifyCombineSupport/**/*.swift'

end
