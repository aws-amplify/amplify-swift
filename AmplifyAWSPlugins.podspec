#
#  Be sure to run `pod spec lint AWSS3StoragePlugin.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = 'AmplifyAWSPlugins'
  s.version      = '0.0.1'
  s.summary      = 'Amazon Web Services Amplify for iOS.'

  s.description  = 'AWS Amplify for iOS provides a declarative library for application development using cloud services'
  
  s.homepage     = 'http://aws.amazon.com/mobile/sdk'
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
  s.platform     = :ios, '11.0'
  s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => s.version}
  
  s.requires_arc = true 

  AWS_SDK_VERSION = '~> 2.12.0'
  AMPLIFY_VERSION = '0.0.1'
  
  s.subspec 'AWSAPICategoryPlugin' do |ss|
    ss.source_files = 'AWSPlugins/API/AWSAPICategoryPlugin/**/*.swift'
    ss.dependency 'AWSPluginsCore', AMPLIFY_VERSION
  end

  s.subspec 'AWSDataStoreCategoryPlugin' do |ss|
    ss.source_files = 'AWSPlugins/DataStore/AWSDataStoreCategoryPlugin/**/*.swift'
    ss.dependency 'AWSPluginsCore', AMPLIFY_VERSION
    ss.dependency 'SQLite.swift', '~> 0.12.0'
  end

  s.subspec 'AWSPinpointAnalyticsPlugin' do |ss|
    ss.source_files = 'AWSPlugins/Analytics/AWSPinpointAnalyticsPlugin/**/*.swift'
    ss.dependency 'AWSPluginsCore', AMPLIFY_VERSION
    ss.dependency 'AWSPinpoint', AWS_SDK_VERSION
  end

  s.subspec 'AWSS3StoragePlugin' do |ss|
    ss.source_files = 'AWSPlugins/Storage/AWSS3StoragePlugin/**/*.swift'
    ss.dependency 'AWSPluginsCore', AMPLIFY_VERSION
    ss.dependency 'AWSS3', AWS_SDK_VERSION
  end

end
