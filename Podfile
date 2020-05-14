# Uncomment the next line to define a global platform for your project
platform :ios, "11.0"

AWS_SDK_VERSION = "2.13.0"

target "Amplify" do
  # Comment the next line if you"re not using Swift and don"t want to use dynamic frameworks
  use_frameworks!

  pod "SwiftFormat/CLI"
  pod "SwiftLint"

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

    pod "AWSCore", "~> #{AWS_SDK_VERSION}"

    abstract_target "AWSPluginsTestConfigs" do
      pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
      pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"

      target "AWSPluginsCoreTests" do
      end

      target "AWSPluginsTestCommon" do
      end
    end

  end

end

target "AmplifyTestApp" do
  use_frameworks!
  pod "CwlPreconditionTesting", :git => "https://github.com/mattgallagher/CwlPreconditionTesting.git", :tag => "1.2.0"
  pod "CwlCatchException", :git => "https://github.com/mattgallagher/CwlCatchException.git", :tag => "1.2.0"
end
