# Version definitions

# Amplify release version
$AMPLIFY_VERSION = '1.29.2'

# GitHub tag name for Amplify releases
$AMPLIFY_RELEASE_TAG = "#{$AMPLIFY_VERSION}"

# AWS SDK version
# http://guides.cocoapods.org/using/the-podfile.html#specifying-pod-versions
$AWS_SDK_VERSION = '2.30.1'
$OPTIMISTIC_AWS_SDK_VERSION = "~> #{$AWS_SDK_VERSION}"

# Include common tooling
def include_build_tools!
  # Pin to 0.44.17 until we resolve closing braces
  pod 'SwiftFormat/CLI', '0.44.17'
  # Pin to 0.49.1 until we update config and code
  pod 'SwiftLint', '0.49.1'
end

# Include common test dependencies
def include_test_utilities!
  pod 'CwlPreconditionTesting',
    git: 'https://github.com/mattgallagher/CwlPreconditionTesting.git',
    tag: '2.1.0'
end
