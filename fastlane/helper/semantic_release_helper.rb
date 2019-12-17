require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class SemanticReleaseHelper
      # class methods that you define here become available in your action
      # as `Helper::SemanticReleaseHelper.your_method`
      #
      def self.git_log(pretty, start)
        command = "git log --pretty='#{pretty}' --reverse #{start}..HEAD"
        Actions.sh(command, log: false).chomp
      end

      def self.parse_commit(params)
        commit_subject = params[:commit_subject].strip
        commit_body = params[:commit_body]
        releases = params[:releases]
        codepush_friendly = params[:codepush_friendly]
        pattern = /^(docs|fix|feat|chore|style|refactor|perf|test)(\((.*)\))?(!?)\: (.*)/
        breaking_change_pattern = /BREAKING CHANGES?: (.*)/
        codepush_pattern = /codepush?: (.*)/

        matched = commit_subject.match(pattern)
        result = {
          is_valid: false,
          subject: commit_subject,
          is_merge: !(commit_subject =~ /^Merge/).nil?,
          type: 'no_type'
        }

        unless matched.nil?
          type = matched[1]
          scope = matched[3]

          result[:is_valid] = true
          result[:type] = type
          result[:scope] = scope
          result[:has_exclamation_mark] = matched[4] == '!'
          result[:subject] = matched[5]

          unless releases.nil?
            result[:release] = releases[type.to_sym]
          end
          unless codepush_friendly.nil?
            result[:is_codepush_friendly] = codepush_friendly.include?(type)
          end

          unless commit_body.nil?
            breaking_change_matched = commit_body.match(breaking_change_pattern)
            codepush_matched = commit_body.match(codepush_pattern)

            unless breaking_change_matched.nil?
              result[:is_breaking_change] = true
              result[:breaking_change] = breaking_change_matched[1]
            end
            unless codepush_matched.nil?
              result[:is_codepush_friendly] = codepush_matched[1] == 'ok'
            end
          end
        end

        result
      end

      def self.semver_gt(first, second)
        first_major = (first.split('.')[0] || 0).to_i
        first_minor = (first.split('.')[1] || 0).to_i
        first_patch = (first.split('.')[2] || 0).to_i

        second_major = (second.split('.')[0] || 0).to_i
        second_minor = (second.split('.')[1] || 0).to_i
        second_patch = (second.split('.')[2] || 0).to_i

        # Check if next version is higher then last version
        if first_major > second_major
          return true
        elsif first_major == second_major
          if first_minor > second_minor
            return true
          elsif first_minor == second_minor
            if first_patch > second_patch
              return true
            end
          end
        end

        return false
      end

      def self.semver_lt(first, second)
        return !semver_gt(first, second)
      end
    end
  end
end