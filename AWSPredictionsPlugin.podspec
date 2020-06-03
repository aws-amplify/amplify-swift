Pod::Spec.new do |s|
  AMPLIFY_VERSION = '1.0.0'
  AWS_SDK_VERSION = '~> 2.13.4'

  s.name         = 'AWSPredictionsPlugin'

  s.version      = AMPLIFY_VERSION
  s.summary      = 'Amazon Web Services Amplify for iOS.'

  s.description  = 'AWS Amplify for iOS provides a declarative library for application development using cloud services'

  s.homepage     = 'https://aws.amazon.com/amplify/'
  s.license      = 'Apache License, Version 2.0'
  s.author       = { 'Amazon Web Services' => 'amazonwebservices' }
  s.source       = { :git => 'https://github.com/aws-amplify/amplify-ios.git', :tag => s.version}

  s.platform     = :ios, '13.0'
  s.swift_version = '5.0'

  s.source_files = 'AmplifyPlugins/Predictions/AWSPredictionsPlugin/**/*.swift'

  s.dependency 'AWSComprehend', AWS_SDK_VERSION
  s.dependency 'AWSPluginsCore', AMPLIFY_VERSION
  s.dependency 'AWSPolly', AWS_SDK_VERSION
  s.dependency 'AWSRekognition', AWS_SDK_VERSION
  s.dependency 'AWSTextract', AWS_SDK_VERSION
  s.dependency 'AWSTranscribeStreaming', AWS_SDK_VERSION
  s.dependency 'AWSTranslate', AWS_SDK_VERSION
  s.dependency 'CoreMLPredictionsPlugin', AMPLIFY_VERSION

  # This is technically redundant, but adding it here allows Xcode to find it
  # during initial indexing and prevent build errors after a fresh install
  s.dependency 'AWSCore', AWS_SDK_VERSION

end