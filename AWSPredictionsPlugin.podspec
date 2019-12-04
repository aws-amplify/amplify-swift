Pod::Spec.new do |s|

    s.name         = 'AWSPredictionsPlugin'
    s.version      = '0.9.0'
    s.summary      = 'Amazon Web Services Amplify for iOS.'
  
    s.description  = 'AWS Amplify for iOS provides a declarative library for application development using cloud services'
  
    s.homepage     = 'https://aws.amazon.com/amplify/'
    s.license      = 'Apache License, Version 2.0'
    s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
    s.platform     = :ios, '13.0'
    s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => s.version}
    
    s.requires_arc = true

    AWS_SDK_VERSION = '~> 2.12.2'
    AMPLIFY_VERSION = '0.9.0'
    
    s.source_files = 'AmplifyPlugins/Predictions/AWSPredictionsPlugin/**/*.swift'
    s.dependency 'AWSComprehend', AWS_SDK_VERSION
    s.dependency 'AWSPluginsCore', AMPLIFY_VERSION
    s.dependency 'AWSPolly', AWS_SDK_VERSION
    s.dependency 'AWSRekognition', AWS_SDK_VERSION
    s.dependency 'AWSTextract', AWS_SDK_VERSION
    s.dependency 'AWSTranscribe', AWS_SDK_VERSION
    s.dependency 'AWSTranslate', AWS_SDK_VERSION
    s.dependency 'CoreMLPredictionsPlugin', AMPLIFY_VERSION
  end