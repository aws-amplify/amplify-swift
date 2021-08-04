# Version definitions

# Amplify release version
$AMPLIFY_VERSION = '1.13.0'

# GitHub tag name for Amplify releases
$AMPLIFY_RELEASE_TAG = "v#{$AMPLIFY_VERSION}"

# AWS SDK version
# http://guides.cocoapods.org/using/the-podfile.html#specifying-pod-versions
$AWS_SDK_VERSION = '2.24.0'
$OPTIMISTIC_AWS_SDK_VERSION = "~> #{$AWS_SDK_VERSION}"

# Include common tooling
def include_build_tools!
  # Pin to 0.44.17 until we resolve closing braces
  pod 'SwiftFormat/CLI', '0.44.17'
  pod 'SwiftLint'
end

# Include common test dependencies
def include_test_utilities!
  pod 'CwlPreconditionTesting',
    git: 'https://github.com/mattgallagher/CwlPreconditionTesting.git',
    tag: '1.2.0'
  pod 'CwlCatchException',
    git: 'https://github.com/mattgallagher/CwlCatchException.git',
    tag: '1.2.0'
end
