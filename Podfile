# Uncomment the next line to define a global platform for your project
platform :ios, "11.0"

AWS_SDK_VERSION = "2.12.0"

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

  target "AWSPluginsCore" do
    inherit! :complete
    use_frameworks!

    pod "AWSMobileClient", "~> #{AWS_SDK_VERSION}"

    target "AWSAPICategoryPlugin" do
      inherit! :complete
    end

    target "AWSDataStoreCategoryPlugin" do
      inherit! :complete
      
      pod "SQLite.swift", "~> 0.12.0"
    end

    target "AWSPinpointAnalyticsPlugin" do
      inherit! :complete

      pod "AWSPinpoint", "~> #{AWS_SDK_VERSION}"
    end

    target "AWSS3StoragePlugin" do
      inherit! :complete

      pod "AWSS3", "~> #{AWS_SDK_VERSION}"
    end

    abstract_target "AWSPluginsTestConfigs" do
      pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
      pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"

      target "AWSPluginsTestCommon" do
      end

      target "AWSAPICategoryPluginTests" do
      end

      target "AWSDataStoreCategoryPluginTests" do
      end

      target "AWSPinpointAnalyticsPluginTests" do
      end

      target "AWSS3StoragePluginTests" do
      end

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
