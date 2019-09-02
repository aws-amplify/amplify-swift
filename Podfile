# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'Amplify' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Amplify

  target 'AmplifyTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'CwlPreconditionTesting', :git => 'https://github.com/mattgallagher/CwlPreconditionTesting.git'
    pod 'CwlCatchException', :git => 'https://github.com/mattgallagher/CwlCatchException.git'
  end

  # target 'AWSS3StoragePlugin' do
  #   inherit! :search_paths
  #   # Pods for testing
  #   pod 'AWSS3'
  # end

end

target 'AWSS3StoragePlugin' do
  use_frameworks!

  pod 'AWSS3'
  pod 'AWSCore'
  pod 'AWSMobileClient'

  target 'AWSS3StoragePluginTests' do
    inherit! :search_paths
    pod 'AWSS3'
    pod 'AWSCore'
    pod 'AWSMobileClient'
    # Pods for testing
    pod 'CwlPreconditionTesting', :git => 'https://github.com/mattgallagher/CwlPreconditionTesting.git'
    pod 'CwlCatchException', :git => 'https://github.com/mattgallagher/CwlCatchException.git'
  end

  target 'AWSS3StoragePluginIntegrationTests' do
    inherit! :search_paths
    pod 'AWSS3'
    pod 'AWSCore'
    pod 'AWSMobileClient'
    # Pods for testing
    pod 'CwlPreconditionTesting', :git => 'https://github.com/mattgallagher/CwlPreconditionTesting.git'
    pod 'CwlCatchException', :git => 'https://github.com/mattgallagher/CwlCatchException.git'
  end
end