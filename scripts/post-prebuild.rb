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
if content.include?('patch_fmt_for_xcode26')
  puts "✓ fmt patch already applied to ios/Podfile"
  exit 0
end

puts "Applying fmt patch to ios/Podfile..."

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
RUBY

content.sub!(/(# @generated end setup)/, "\\1#{patch_function}")

# 2. Add the function call inside post_install block, after react_native_post_install
content.sub!(
  /(:ccache_enabled => podfile_properties\['apple\.ccacheEnabled'\] == 'true',\n    \))/,
  "\\1\n\n    # Xcode 26.5 fix for fmt consteval compilation error\n    patch_fmt_for_xcode26(installer)"
)

File.write(PODFILE, content)
puts "✓ fmt patch applied to ios/Podfile"
puts ""
puts "All post-prebuild patches applied successfully!"
puts "You can now run 'cd ios && pod install'"
