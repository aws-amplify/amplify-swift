module Fastlane
  module Actions
    class PodspecConstantVersioningAction < Action
      def self.run(params)
        podspec = params[:podspec]
        constant = params[:constant]
        value = params[:value]
        
        podspec_contents = File.read(podspec)

        # TODO: improve RegEx
        if !podspec_contents.match(/(?<=#{constant})(\s*=\s*["'].*)/)
          UI.error("#{constant} not present or doesn't have an explicit value in #{podspec}")
          return
        end

        new_value = " = '#{value}'"
        
        podspec_new_contents = podspec_contents.gsub(/(?<=#{constant})(\s*=\s*["'].*)/, new_value)

        File.open(podspec, "w") { |file| file.puts podspec_new_contents }
        UI.success("successfully modified #{constant} to value #{value} in #{podspec}")
            
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "This action will modify the value of a constant in your podspec."
      end

      def self.available_options
        [
            FastlaneCore::ConfigItem.new(
                key: :podspec,
                env_name: "PODSPEC_PATH",
                description: "The path of the podspec you wish to modify",
                optional: false,
                type: String
            ),
            FastlaneCore::ConfigItem.new(
                key: :constant,
                env_name: "CONSTANT_NAME",
                description: "The constant you wish to modify",
                optional: false,
                type: String
            ),
            FastlaneCore::ConfigItem.new(
                key: :value,
                env_name: "CONSTANT_VALUE",
                description: "The new value to assign to the constant",
                optional: false,
                type: String
            )
        ]
      end

      def self.authors
        ["iartemiev"]
      end

      def self.is_supported?(platform)
        # you can do things like
        # 
        #  true
        # 
        #  platform == :ios
        # 
        #  [:ios, :mac].include?(platform)
        # 

        platform == :ios
      end
    end
  end
end
