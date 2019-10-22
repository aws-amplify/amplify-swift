# Uncomment the next line to define a global platform for your project
platform :ios, "11.0"

AWS_SDK_VERSION = "2.11.1"

target "Amplify" do
  # Comment the next line if you"re not using Swift and don"t want to use dynamic frameworks
  use_frameworks!

  pod 'SwiftFormat/CLI'
  pod 'SwiftLint'

  abstract_target "AmplifyTestConfigs" do
    pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
    pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"

    target "AmplifyTestCommon" do
    end

    target "AmplifyTests" do
    end

    target "AmplifyFunctionalTests" do
    end

  end
end

abstract_target "AWSPlugins" do
  use_frameworks!

  pod "AWSMobileClient", "~> #{AWS_SDK_VERSION}"

  pod 'SwiftFormat/CLI'
  pod 'SwiftLint'

  target "AWSAPICategoryPlugin" do
    inherit! :complete

    target "AWSAPICategoryPluginTests" do
      inherit! :complete
      pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
      pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"
    end

  end

  target "AWSPinpointAnalyticsPlugin" do
    inherit! :complete

    pod "AWSPinpoint", "~> #{AWS_SDK_VERSION}"

    target "AWSPinpointAnalyticsPluginTests" do
      inherit! :complete
      pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
      pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"
    end

  end

  target "AWSS3StoragePlugin" do
    inherit! :complete

    pod "AWSS3", "~> #{AWS_SDK_VERSION}"

    target "AWSS3StoragePluginTests" do
      inherit! :complete
      pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
      pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"
    end

  end

end

target "AmplifyTestApp" do
  use_frameworks!
  pod "AWSS3", "~> #{AWS_SDK_VERSION}"
  pod "AWSMobileClient", "~> #{AWS_SDK_VERSION}"
  pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
  pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"

  target "AWSAPICategoryPluginIntegrationTests" do
    inherit! :complete
  end

  target "AWSPinpointAnalyticsPluginIntegrationTests" do
    inherit! :complete
    pod "AWSPinpoint", "~> #{AWS_SDK_VERSION}"
  end

  target "AWSS3StoragePluginIntegrationTests" do
    inherit! :complete
    pod "AWSS3", "~> #{AWS_SDK_VERSION}"
  end

end