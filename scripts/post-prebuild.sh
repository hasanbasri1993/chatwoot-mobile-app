#!/bin/bash
# post-prebuild.sh - Apply patches after running npx expo prebuild
# The ios/Podfile is not tracked by git, so we need to reapply patches after each prebuild.

set -e

PODFILE="ios/Podfile"

if [ ! -f "$PODFILE" ]; then
  echo "Error: $PODFILE not found. Run 'npx expo prebuild' first."
  exit 1
fi

# Check if patch is already applied
if grep -q "patch_fmt_for_xcode26" "$PODFILE"; then
  echo "✓ fmt patch already applied to ios/Podfile"
else
  echo "Applying fmt patch to ios/Podfile..."
  
  # Add the patch function after "# @generated end setup"
  sed -i '' '/# @generated end setup/a\
\
# Xcode 26 workaround: patch fmt to disable consteval\
def patch_fmt_for_xcode26(installer)\
  fmt_base = File.join(installer.sandbox.root, '\''fmt'\'', '\''include'\'', '\''fmt'\'', '\''base.h'\'')\
  if File.exist?(fmt_base)\
    content = File.read(fmt_base)\
    unless content.include?('\''Xcode 26 workaround'\'')\
      patched = content.gsub(\
        /^(#elif defined\\(__cpp_consteval\\)\\n#  define FMT_USE_CONSTEVAL) 1/,\
        "// Xcode 26 workaround: disable consteval\\n\\\\1 0"\
      )\
      if patched != content\
        File.chmod(0644, fmt_base)\
        File.write(fmt_base, patched)\
      end\
    end\
  end\
end
' "$PODFILE"

  # Add the function call inside post_install block
  sed -i '' '/:ccache_enabled => podfile_properties/a\
    )\
\
    # Xcode 26.5 fix for fmt consteval compilation error\
    patch_fmt_for_xcode26(installer)\
\
    # This is necessary for Xcode 14
' "$PODFILE"

  # Remove the duplicate closing paren and comment that sed created
  sed -i '' '/^    )$/{ N; /\n\n    # Xcode 26.5 fix/{ s/^    )\n//; }; }' "$PODFILE"

  echo "✓ fmt patch applied to ios/Podfile"
fi

echo ""
echo "All post-prebuild patches applied successfully!"
echo "You can now run 'cd ios && pod install'"
