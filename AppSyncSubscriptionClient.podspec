Pod::Spec.new do |s|

    s.name         = 'AppSyncSubscriptionClient'
    s.version      = '0.0.1'
    s.summary      = 'Amazon Web Services AppSync Subscription Client for iOS.'
  
    s.description  = 'AWS Amplify for iOS provides a declarative library for application development using cloud services'
  
    s.homepage     = 'https://aws.amazon.com/amplify/'
    s.license      = 'Apache License, Version 2.0'
    s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
    s.platform     = :ios, '9.0'
    s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => s.version}
    
    s.requires_arc = true

    AWS_SDK_VERSION = '~> 2.12.6'
    AMPLIFY_VERSION = '0.10.0'
    
    s.source_files = 'AppSyncSubscriptionClient/AppSyncSubscriptionClient/**/*.swift'
    s.dependency 'Starscream', '~> 3.0.2'
  end