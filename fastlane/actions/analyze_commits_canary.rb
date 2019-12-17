require_relative '../helper/semantic_release_helper'

# Matches any valid semver with optional v at the beginning e.g. 1.2.3, v1.2.3, 1.2.3-alpha.0, etc
SEMVER_REGEX = /^v?(?'MAJOR'0|[1-9]\d*)\.(?'MINOR'0|[1-9]\d*)\.(?'PATCH'0|[1-9]\d*)(?:-(?'PRE_RELEASE'(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?'BUILD'[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$/
# Matches semver prerelease, e.g. alpha.0
PRERELEASE_REGEX = /^(?'PREID'\w+)\.(?'PREVERSION'\d+)/
# Matches git describe suffix, e.g. 1-g93c6f0b
GITHASH_REGEX = /^\d+\-g[0-9a-f]{7}/

module Fastlane
  module Actions
    module SharedValues
      RELEASE_ANALYZED = :RELEASE_ANALYZED
      RELEASE_IS_NEXT_VERSION_HIGHER = :RELEASE_IS_NEXT_VERSION_HIGHER
      RELEASE_LAST_TAG_HASH = :RELEASE_LAST_TAG_HASH
      RELEASE_LAST_VERSION = :RELEASE_LAST_VERSION
      RELEASE_NEXT_MAJOR_VERSION = :RELEASE_NEXT_MAJOR_VERSION
      RELEASE_NEXT_MINOR_VERSION = :RELEASE_NEXT_MINOR_VERSION
      RELEASE_NEXT_PATCH_VERSION = :RELEASE_NEXT_PATCH_VERSION
      RELEASE_NEXT_VERSION = :RELEASE_NEXT_VERSION
      RELEASE_NEXT_PRERELEASE_VERSION = :RELEASE_NEXT_PRERELEASE_VERSION
      RELEASE_LAST_INCOMPATIBLE_CODEPUSH_VERSION = :RELEASE_LAST_INCOMPATIBLE_CODEPUSH_VERSION
    end

    class AnalyzeCommitsCanaryAction < Action
      def self.get_last_tag(params)
        # Try to find the tag
        command = "git describe --tags --match=#{params[:match]}"
        Actions.sh(command, log: false)
      rescue
        UI.message("Tag was not found for match pattern - #{params[:match]}")
        ''
      end

      def self.get_last_tag_hash(params)
        command = "git rev-list -n 1 refs/tags/#{params[:tag_name]}"
        Actions.sh(command, log: false).chomp
      end

      def self.get_commits_from_hash(params)
        commits = Helper::SemanticReleaseHelper.git_log('%s|%b|>', params[:hash])
        commits.split("|>")
      end

      def self.break_apart_tag(params)
        tagmatch = params[:tag].match(SEMVER_REGEX)

        if !tagmatch
          UI.user_error!("The last tag is not semver")
        end

        major, minor, patch, preandgit = tagmatch.captures
      
        returnObj = {
          'major': major.to_i,
          'minor': minor.to_i,
          'patch': patch.to_i
        }
      
        prerelease_match = preandgit.match(PRERELEASE_REGEX)
      
        if prerelease_match
          preid, pre_ver = prerelease_match.captures
      
          returnObj['preid'] = preid
          returnObj['pre_ver'] = pre_ver.to_i
        end
      
        returnObj
      end

      # TODO: this method needs to utilize break apart tag similarly to the _canary method
      # Fix before using the stable release lane
      def self.is_releasable(params)
        # Hash of the commit where is the last version
        # If the tag is not found we are taking HEAD as reference
        hash = 'HEAD'
        # Default last version
        version = '0.0.0'

        tag = get_last_tag(match: params[:match])

        if tag.empty?
          UI.message("First commit of the branch is taken as a begining of next release")
          # If there is no tag found we taking the first commit of current branch
          hash = Actions.sh('git rev-list --max-parents=0 HEAD', log: false).chomp
        else
          # Tag's format is v2.3.4-5-g7685948
          # See git describe man page for more info
          tag_name = tag.split('-')[0].strip
          parsed_version = tag_name.match(params[:tag_version_match])

          if parsed_version.nil?
            UI.user_error!("Error while parsing version from tag #{tag_name} by using tag_version_match - #{params[:tag_version_match]}. Please check if the tag contains version as you expect and if you are using single brackets for tag_version_match parameter.")
          end

          version = parsed_version[0]
          # Get a hash of last version tag
          # pass the whole tag with canary version
          hash = get_last_tag_hash(tag_name: tag_name)

          UI.message("Found a tag #{tag_name} associated with version #{version}")
        end

        # converts last version string to the int numbers
        next_major = (version.split('.')[0] || 0).to_i
        next_minor = (version.split('.')[1] || 0).to_i
        next_patch = (version.split('.')[2] || 0).to_i

        # Get commits log between last version and head
        splitted = get_commits_from_hash(hash: hash)

        UI.message("Found #{splitted.length} commits since last release")
        releases = params[:releases]

        splitted.each do |line|
          # conventional commits are in format
          # type: subject (fix: app crash - for example)
          commit = Helper::SemanticReleaseHelper.parse_commit(
            commit_subject: line.split("|")[0],
            commit_body: line.split("|")[1],
            releases: releases
          )

          unless commit[:scope].nil?
            # if this commit has a scope, then we need to inspect to see if that is one of the scopes we're trying to exclude
            scope = commit[:scope]
            scopes_to_ignore = params[:ignore_scopes]
            # if it is, we'll skip this commit when bumping versions
            next if scopes_to_ignore.include?(scope) #=> true
          end

          if commit[:release] == "major" || commit[:is_breaking_change]
            next_major += 1
            next_minor = 0
            next_patch = 0
          elsif commit[:release] == "minor"
            next_minor += 1
            next_patch = 0
          elsif commit[:release] == "patch"
            next_patch += 1
          end

          next_version = "#{next_major}.#{next_minor}.#{next_patch}"
          UI.message("#{next_version}: #{line}")
        end

        next_version = "#{next_major}.#{next_minor}.#{next_patch}"

        is_next_version_releasable = Helper::SemanticReleaseHelper.semver_gt(next_version, version)

        Actions.lane_context[SharedValues::RELEASE_ANALYZED] = true
        Actions.lane_context[SharedValues::RELEASE_IS_NEXT_VERSION_HIGHER] = is_next_version_releasable
        # Last release analysis
        Actions.lane_context[SharedValues::RELEASE_LAST_TAG_HASH] = hash
        Actions.lane_context[SharedValues::RELEASE_LAST_VERSION] = version
        # Next release analysis
        Actions.lane_context[SharedValues::RELEASE_NEXT_MAJOR_VERSION] = next_major
        Actions.lane_context[SharedValues::RELEASE_NEXT_MINOR_VERSION] = next_minor
        Actions.lane_context[SharedValues::RELEASE_NEXT_PATCH_VERSION] = next_patch
        Actions.lane_context[SharedValues::RELEASE_NEXT_VERSION] = next_version

        success_message = "Next version (#{next_version}) is higher than last version (#{version}). This version should be released."
        UI.success(success_message) if is_next_version_releasable

        is_next_version_releasable
      end

      def self.is_releasable_canary(params)
        # Hash of the commit where is the last version
        # If the tag is not found we are taking HEAD as reference
        hash = 'HEAD'
        # Default last version
        version = '0.1.0'

        # Tag's format is 2.3.4-alpha.0-5-g7685948
        # See git describe man page for more info
        tag = get_last_tag(match: params[:match])

        if tag.empty?
          UI.message("First commit of the branch is taken as a begining of next release")
          # If there is no tag found we taking the first commit of current branch
          hash = Actions.sh('git rev-list --max-parents=0 HEAD', log: false).chomp
        else
          major, minor, patch, preid, pre_ver = break_apart_tag(tag: tag).values

          tag_name = "#{major}.#{minor}.#{patch}"

          if !preid.nil?
            tag_name += "-#{preid}.#{pre_ver}"
          end

          parsed_version = tag_name.match(params[:tag_version_match])

          if parsed_version.nil?
            UI.user_error!("Error while parsing version from tag #{tag_name} by using tag_version_match - #{params[:tag_version_match]}. Please check if the tag contains version as you expect and if you are using single brackets for tag_version_match parameter.")
          end

          # Get a hash of last version tag
          hash = get_last_tag_hash(tag_name: tag_name)

          UI.message("Found a tag #{tag} associated with version #{tag_name}")
        end

        version = tag_name

        next_major = major
        next_minor = minor
        next_patch = patch

        if preid.nil?
          next_patch += 1
          next_preid = params[:preid]
          next_pre_ver = 0
        else
          # different preid exists on tag than the one that was passed in
          if preid != params[:preid]
            next_preid = params[:preid]
            next_pre_ver = 0
          else
            # if preid exists and matches the one that was passed in, increment the prerelease version
            next_preid = preid
            next_pre_ver = pre_ver + 1
          end
        end

        next_version = "#{next_major}.#{next_minor}.#{next_patch}-#{next_preid}.#{next_pre_ver}"

        is_next_version_releasable = true

        Actions.lane_context[SharedValues::RELEASE_ANALYZED] = true
        Actions.lane_context[SharedValues::RELEASE_IS_NEXT_VERSION_HIGHER] = is_next_version_releasable
        # Last release analysis
        Actions.lane_context[SharedValues::RELEASE_LAST_TAG_HASH] = hash
        Actions.lane_context[SharedValues::RELEASE_LAST_VERSION] = version
        # Next release analysis
        Actions.lane_context[SharedValues::RELEASE_NEXT_MAJOR_VERSION] = next_major
        Actions.lane_context[SharedValues::RELEASE_NEXT_MINOR_VERSION] = next_minor
        Actions.lane_context[SharedValues::RELEASE_NEXT_PATCH_VERSION] = next_patch
        Actions.lane_context[SharedValues::RELEASE_NEXT_VERSION] = next_version
        Actions.lane_context[SharedValues::RELEASE_NEXT_PRERELEASE_VERSION] = "#{next_preid}.#{next_pre_ver}"

        success_message = "Next version (#{next_version}) is higher than last version (#{version}). This version should be released."
        UI.success(success_message) if is_next_version_releasable

        is_next_version_releasable
      end

      def self.is_codepush_friendly(params)
        # Begining of the branch is taken for codepush analysis
        hash = Actions.sh('git rev-list --max-parents=0 HEAD', log: false).chomp
        next_major = 0
        next_minor = 0
        next_patch = 0
        last_incompatible_codepush_version = '0.0.0'

        # Get commits log between last version and head
        splitted = get_commits_from_hash(hash: hash)
        releases = params[:releases]
        codepush_friendly = params[:codepush_friendly]

        splitted.each do |line|
          # conventional commits are in format
          # type: subject (fix: app crash - for example)
          commit = Helper::SemanticReleaseHelper.parse_commit(
            commit_subject: line.split("|")[0],
            commit_body: line.split("|")[1],
            releases: releases,
            codepush_friendly: codepush_friendly
          )

          if commit[:release] == "major" || commit[:is_breaking_change]
            next_major += 1
            next_minor = 0
            next_patch = 0
          elsif commit[:release] == "minor"
            next_minor += 1
            next_patch = 0
          elsif commit[:release] == "patch"
            next_patch += 1
          end

          unless commit[:is_codepush_friendly]
            last_incompatible_codepush_version = "#{next_major}.#{next_minor}.#{next_patch}"
          end
        end

        Actions.lane_context[SharedValues::RELEASE_LAST_INCOMPATIBLE_CODEPUSH_VERSION] = last_incompatible_codepush_version
      end

      def self.run(params)
        if params[:canary]
          is_next_version_releasable = is_releasable_canary(params)
          return is_next_version_releasable
        end
          
        is_next_version_releasable = is_releasable(params)
        is_codepush_friendly(params)
        is_next_version_releasable
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Finds a tag of last release and determinates version of next release"
      end

      def self.details
        "This action will find a last release tag and analyze all commits since the tag. It uses conventional commits. Every time when commit is marked as fix or feat it will increase patch or minor number (you can setup this default behaviour). After all it will suggest if the version should be released or not."
      end

      def self.available_options
        # Define all options your action supports.

        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(
            key: :match,
            description: "Match parameter of git describe. See man page of git describe for more info",
            verify_block: proc do |value|
              UI.user_error!("No match for analyze_commits action given, pass using `match: 'expr'`") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :releases,
            description: "Map types of commit to release (major, minor, patch)",
            default_value: { fix: "patch", feat: "minor" },
            type: Hash
          ),
          FastlaneCore::ConfigItem.new(
            key: :codepush_friendly,
            description: "These types are consider as codepush friendly automatically",
            default_value: ["chore", "test", "docs"],
            type: Array,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :tag_version_match,
            description: "To parse version number from tag name",
            default_value: '\d+\.\d+\.\d+'
          ),
          FastlaneCore::ConfigItem.new(
            key: :ignore_scopes,
            description: "To ignore certain scopes when calculating releases",
            default_value: [],
            type: Array,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :canary,
            description: "Canary deployment",
            type: Boolean,
            default_value: false
          ),
          FastlaneCore::ConfigItem.new(
            key: :preid,
            description: "Canary pre-release id",
            type: String,
            default_value: "alpha"
          )
        ]
      end

      def self.output
        # Define the shared values you are going to provide
        # Example
        [
          ['RELEASE_ANALYZED', 'True if commits were analyzed.'],
          ['RELEASE_IS_NEXT_VERSION_HIGHER', 'True if next version is higher then last version'],
          ['RELEASE_LAST_TAG_HASH', 'Hash of commit that is tagged as a last version'],
          ['RELEASE_LAST_VERSION', 'Last version number - parsed from last tag.'],
          ['RELEASE_NEXT_MAJOR_VERSION', 'Major number of the next version'],
          ['RELEASE_NEXT_MINOR_VERSION', 'Minor number of the next version'],
          ['RELEASE_NEXT_PATCH_VERSION', 'Patch number of the next version'],
          ['RELEASE_NEXT_VERSION', 'Next version string in format (major.minor.patch)'],
          ['RELEASE_NEXT_PRERELEASE_VERSION', 'Next prerelease version string in format (preid.pre_ver)'],
          ['RELEASE_LAST_INCOMPATIBLE_CODEPUSH_VERSION', 'Last commit without codepush']
        ]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
        "Returns true if the next version is higher then the last version"
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["xotahal"]
      end

      def self.is_supported?(platform)
        # you can do things like
        true
      end
    end
  end
end