#
#  Be sure to run `pod spec lint AWSS3StoragePlugin.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

# Version definitions
$AMPLIFY_VERSION = '1.2.1'
$AMPLIFY_RELEASE_TAG = "v#{$AMPLIFY_VERSION}"

$AWS_SDK_VERSION = '2.17.0'
$OPTIMISTIC_AWS_SDK_VERSION = "~> #{$AWS_SDK_VERSION}"

Pod::Spec.new do |s|
  s.name         = 'AmplifyPlugins'
  s.version      = $AMPLIFY_VERSION
  s.summary      = 'Amazon Web Services Amplify for iOS.'

  s.description  = 'AWS Amplify for iOS provides a declarative library for application development using cloud services'

  s.homepage     = 'https://github.com/aws-amplify/amplify-ios'
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
  s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => $AMPLIFY_RELEASE_TAG }

  s.platform = :ios, '11.0'
  s.swift_version = '5.0'

  s.dependency 'AWSPluginsCore', $AMPLIFY_VERSION

  # This is technically redundant, but adding it here allows Xcode to find it
  # during initial indexing and prevent build errors after a fresh install
  s.dependency 'AWSCore', $OPTIMISTIC_AWS_SDK_VERSION

  s.subspec 'AWSAPIPlugin' do |ss|
    ss.source_files = 'AmplifyPlugins/API/AWSAPICategoryPlugin/**/*.swift'
    ss.dependency 'ReachabilitySwift', '~> 5.0.0'
    ss.dependency 'AppSyncRealTimeClient', "~> 1.4.0"
  end

  s.subspec 'AWSCognitoAuthPlugin' do |ss|
    ss.source_files = 'AmplifyPlugins/Auth/AWSCognitoAuthPlugin/**/*.swift'
    ss.dependency 'AWSMobileClient', $OPTIMISTIC_AWS_SDK_VERSION

    # This is technically redundant, but adding it here allows Xcode to find it
    # during initial indexing and prevent build errors after a fresh install
    ss.dependency 'AWSAuthCore', $OPTIMISTIC_AWS_SDK_VERSION
    ss.dependency 'AWSCognitoIdentityProvider', $OPTIMISTIC_AWS_SDK_VERSION
    #ss.dependency 'AWSCognitoIdentityProviderASF', '1.1.0'

    # AWSCognitoIdentityProviderASF: Exclude arm64 when building for simulator on Xcode 12
    ss.pod_target_xcconfig = {
      # Xcode 12 Beta 3
      'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_12A8169g' => 'arm64 arm64e armv7 armv7s armv6 armv8',

      # Xcode 12 beta 4
      'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_12A8179i' => 'arm64 arm64e armv7 armv7s armv6 armv8',

      # Xcode 12 beta 5
      'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_12A8189h' => 'arm64 arm64e armv7 armv7s armv6 armv8',

      # Xcode 12 beta 6
      'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_12A8189n' => 'arm64 arm64e armv7 armv7s armv6 armv8',

      # Xcode 12 GM (12A7208)
      'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_12A7208' => 'arm64 arm64e armv7 armv7s armv6 armv8',

      # Xcode 12 GM (12A7209)
      'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_12A7209' => 'arm64 arm64e armv7 armv7s armv6 armv8',

      'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200' => '$(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200__BUILD_$(XCODE_PRODUCT_BUILD_VERSION))',

      'EXCLUDED_ARCHS' => '$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT)__XCODE_$(XCODE_VERSION_MAJOR))'
    }
  end

  s.subspec 'AWSDataStorePlugin' do |ss|
    ss.source_files = 'AmplifyPlugins/DataStore/AWSDataStoreCategoryPlugin/**/*.swift'
    ss.dependency 'SQLite.swift', '~> 0.12.0'
  end

  s.subspec 'AWSPinpointAnalyticsPlugin' do |ss|
    ss.source_files = 'AmplifyPlugins/Analytics/AWSPinpointAnalyticsPlugin/**/*.swift'
    ss.dependency 'AWSPinpoint', $OPTIMISTIC_AWS_SDK_VERSION
  end

  s.subspec 'AWSS3StoragePlugin' do |ss|
    ss.source_files = 'AmplifyPlugins/Storage/AWSS3StoragePlugin/**/*.swift'
    ss.dependency 'AWSS3', $OPTIMISTIC_AWS_SDK_VERSION
  end

end
