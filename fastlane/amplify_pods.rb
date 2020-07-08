module AmplifyPods
  @@pods = [
    {
      spec: "Amplify.podspec",
      constants: ['AMPLIFY_VERSION'],
      plist_paths: [
        "Amplify/Info.plist",
        "AmplifyTests/Info.plist",
        "AmplifyFunctionalTests/Info.plist",
        "AmplifyTestApp/Info.plist",
        "AmplifyTestCommon/Info.plist"
      ]
    },
    {
      spec: "AWSPluginsCore.podspec",
      constants: ['AMPLIFY_VERSION'],
      plist_paths: [
        "AmplifyPlugins/Core/AWSPluginsTestCommon/Info.plist",
        "AmplifyPlugins/Core/AWSPluginsCore/Info.plist",
        "AmplifyPlugins/Core/AWSPluginsCoreTests/Info.plist"
      ]
    },
    {
      spec: "CoreMLPredictionsPlugin.podspec",
      constants: ['AMPLIFY_VERSION'],
      plist_paths: [
        "AmplifyPlugins/Predictions/CoreMLPredictionsPlugin/Resources/Info.plist"
      ]
    },
    {
      spec: "AWSPredictionsPlugin.podspec",
      constants: ['AMPLIFY_VERSION'],
      plist_paths: [
        "AmplifyPlugins/Predictions/AWSPredictionsPlugin/Resources/Info.plist"
      ]
    },
    {
      spec: "AmplifyPlugins.podspec",
      constants: ['AMPLIFY_VERSION'],
      plist_paths: [
        "AmplifyPlugins/Analytics/AWSPinpointAnalyticsPlugin/Resources/Info.plist",
        "AmplifyPlugins/API/AWSAPICategoryPlugin/Info.plist",
        "AmplifyPlugins/Auth/AWSCognitoAuthPlugin/Resources/Info.plist",
        "AmplifyPlugins/DataStore/AWSDataStoreCategoryPlugin/Info.plist",
        "AmplifyPlugins/Storage/AWSS3StoragePlugin/Resources/Info.plist"
      ]
    },
    {
      spec: "AmplifyTestCommon.podspec",
      constants: ['AMPLIFY_VERSION'],
      plist_paths: [],
      no_push: true
    }
  ]
  @@plugins = ['API', 'Analytics', 'Auth', 'DataStore', 'Predictions', 'Storage']
  def self.pods
    @@pods
  end
  def self.plugins
    @@plugins
  end
end