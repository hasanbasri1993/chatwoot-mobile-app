#!/usr/bin/env ruby
# post-prebuild.rb - Apply patches to ios/Podfile after running npx expo prebuild
# Run this script after 'npx expo prebuild' to patch the generated Podfile.
#
# Usage: ruby scripts/post-prebuild.rb

PODFILE = File.join(__dir__, '..', 'ios', 'Podfile')

unless File.exist?(PODFILE)
  puts "Error: #{PODFILE} not found. Run 'npx expo prebuild' first."
  exit 1
end

content = File.read(PODFILE)

# Check if patch is already applied
if content.include?('patch_fmt_for_xcode26') && content.include?('raise_pod_deployment_targets')
  puts "✓ patches already applied to ios/Podfile"
  exit 0
end

puts "Applying patches to ios/Podfile..."

# 1. Add the patch function after "# @generated end setup"
patch_function = <<~RUBY

  # Xcode 26 workaround: patch fmt to disable consteval
  def patch_fmt_for_xcode26(installer)
    fmt_base = File.join(installer.sandbox.root, 'fmt', 'include', 'fmt', 'base.h')
    if File.exist?(fmt_base)
      content = File.read(fmt_base)
      unless content.include?('Xcode 26 workaround')
        patched = content.gsub(
          /^(#elif defined\\(__cpp_consteval\\)\\n#  define FMT_USE_CONSTEVAL) 1/,
          "// Xcode 26 workaround: disable consteval\\n\\\\1 0"
        )
        if patched != content
          File.chmod(0644, fmt_base)
          File.write(fmt_base, patched)
        end
      end
    end
  end

  # Pods default to RN's minimum (15.1), but some (e.g. react-native-ios-context-menu)
  # use iOS 16 APIs without availability checks. Match the app's 16.4 minimum.
  def raise_pod_deployment_targets(installer, min_version = '16.4')
    # Pods may be split into one Xcode project per pod, so cover every generated project.
    projects = installer.respond_to?(:generated_projects) ? installer.generated_projects : [installer.pods_project]
    projects.each do |project|
      project.targets.each do |target|
        target.build_configurations.each do |build_config|
          current = build_config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
          if current.nil? || Gem::Version.new(current) < Gem::Version.new(min_version)
            build_config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = min_version
          end
        end
      end
      project.save
    end
  end
RUBY

content.sub!(/(# @generated end setup)/, "\\1#{patch_function}")

# 2. Add the function calls inside post_install block, after react_native_post_install
patched = content.sub!(
  /(react_native_post_install\(.*?\n    \))/m,
  "\\1\n\n    # Xcode 26.5 fix for fmt consteval compilation error\n    patch_fmt_for_xcode26(installer)" \
  "\n    raise_pod_deployment_targets(installer)"
)
unless patched
  puts "Error: could not find react_native_post_install in #{PODFILE}"
  exit 1
end

File.write(PODFILE, content)
puts "✓ fmt and deployment target patches applied to ios/Podfile"
puts ""
puts "All post-prebuild patches applied successfully!"
puts "You can now run 'cd ios && pod install'"
