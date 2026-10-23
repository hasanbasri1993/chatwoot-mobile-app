const { createRunOncePlugin, withDangerousMod } = require('@expo/config-plugins');
const fs = require('fs');
const path = require('path');

// Podfile fixes that must also apply on EAS, which runs its own prebuild:
// - Pods default to RN's minimum iOS (15.1), but some (e.g. react-native-ios-context-menu)
//   use iOS 16 APIs without availability checks. Raise every pod to the app's minimum.
// - Xcode 26+ rejects fmt's consteval usage; disable it in fmt's base.h.
const MARKER = 'with-ios-pod-fixes';
const MIN_IOS_VERSION = '16.4';

const HELPERS = `
# ${MARKER}: Xcode 26 workaround: patch fmt to disable consteval
def patch_fmt_for_xcode26(installer)
  fmt_base = File.join(installer.sandbox.root, 'fmt', 'include', 'fmt', 'base.h')
  return unless File.exist?(fmt_base)
  content = File.read(fmt_base)
  return if content.include?('Xcode 26 workaround')
  patched = content.gsub(
    /^(#elif defined\\(__cpp_consteval\\)\\n#  define FMT_USE_CONSTEVAL) 1/,
    "// Xcode 26 workaround: disable consteval\\n\\\\1 0"
  )
  if patched != content
    File.chmod(0644, fmt_base)
    File.write(fmt_base, patched)
  end
end

# ${MARKER}: raise every pod to the app's minimum iOS version
def raise_pod_deployment_targets(installer, min_version = '${MIN_IOS_VERSION}')
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
`;

const CALLS = `

    # ${MARKER}
    patch_fmt_for_xcode26(installer)
    raise_pod_deployment_targets(installer)`;

function patchPodfile(podfilePath) {
  let contents = fs.readFileSync(podfilePath, 'utf8');
  if (contents.includes(`# ${MARKER}`)) {
    return;
  }

  // Helpers sit at the top level, before any target block.
  const targetIdx = contents.indexOf("\ntarget '");
  if (targetIdx === -1) {
    throw new Error(`${MARKER}: could not find a target block in Podfile`);
  }
  contents = contents.slice(0, targetIdx) + `\n${HELPERS}` + contents.slice(targetIdx);

  // Calls run after react_native_post_install so its settings don't override ours.
  const callRegex = /(react_native_post_install\([\s\S]*?\n    \))/;
  if (!callRegex.test(contents)) {
    throw new Error(`${MARKER}: could not find react_native_post_install in Podfile`);
  }
  contents = contents.replace(callRegex, `$1${CALLS}`);
  fs.writeFileSync(podfilePath, contents, 'utf8');
}

const withIosPodFixes = config =>
  withDangerousMod(config, [
    'ios',
    cfg => {
      patchPodfile(path.join(cfg.modRequest.platformProjectRoot, 'Podfile'));
      return cfg;
    },
  ]);

module.exports = createRunOncePlugin(withIosPodFixes, MARKER, '1.0.0');
