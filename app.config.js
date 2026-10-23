/** @type {import('expo/config').ExpoConfig} */
module.exports = ({ config }) => ({
  name: 'Chatwoot Dulido',
  slug: process.env.EXPO_PUBLIC_APP_SLUG || 'chatwoot-mobile',
  version: '4.9.11',
  orientation: 'portrait',
  icon: './assets/icon.png',
  userInterfaceStyle: 'light',
  scheme: 'chatwootapp',
  ios: {
    supportsTablet: true,
    buildNumber: '52',
    bundleIdentifier: 'com.daarululuumlido.chatwoot',
    infoPlist: {
      NSCameraUsageDescription: 'This app requires access to the camera to upload images and videos.',
      NSPhotoLibraryUsageDescription: 'This app requires access to the photo library to upload images.',
      NSMicrophoneUsageDescription: 'This app requires access to the microphone to record audio.',
      NSAppleMusicUsageDescription: 'This app does not use Apple Music, but a system API may require this permission.',
      UIBackgroundModes: ['fetch', 'remote-notification'],
      ITSAppUsesNonExemptEncryption: false,
    },
    googleServicesFile: './GoogleService-Info.plist',
    entitlements: {
      'aps-environment': 'production',
    },
    associatedDomains: ['applinks:chatwoot.daarululuumlido.com'],
  },
  android: {
    adaptiveIcon: { foregroundImage: './assets/adaptive-icon.png', backgroundColor: '#ffffff' },
    package: 'com.daarululuumlido.chatwoot',
    versionCode: 52,
    permissions: [
      'android.permission.CAMERA',
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.RECORD_AUDIO',
      'android.permission.READ_MEDIA_IMAGES',
      'android.permission.POST_NOTIFICATIONS',
    ],
    googleServicesFile: './google-services.json',
    intentFilters: [
      {
        action: 'VIEW',
        autoVerify: true,
        data: [
          {
            scheme: 'https',
            host: 'chatwoot.daarululuumlido.com',
            pathPrefix: '/app/accounts/',
            pathPattern: '/*/conversations/*',
          },
        ],
        category: ['BROWSABLE', 'DEFAULT'],
      },
      {
        action: 'VIEW',
        data: [{ scheme: 'chatwootapp' }],
        category: ['BROWSABLE', 'DEFAULT'],
      },
    ],
  },
  extra: {
    eas: {
      projectId: 'cdf619a0-5a45-448c-acf2-41213cc19781',
      storybookEnabled: process.env.EXPO_STORYBOOK_ENABLED,
    },
  },
  owner: 'hasanbasri93',
  plugins: [
    'expo-font',
    'expo-image',
    'expo-status-bar',
    [
      'expo-splash-screen',
      {
        image: './assets/splash.png',
        resizeMode: 'contain',
        backgroundColor: '#ffffff',
        enableFullScreenImage_legacy: true,
      },
    ],
    [
      'react-native-permissions',
      { iosPermissions: ['Camera', 'PhotoLibrary', 'MediaLibrary', 'Notifications'] },
    ],
    [
      '@sentry/react-native',
      {
        url: 'https://sentry.io/',
        project: 'chatwoot',
        organization: 'hasan93',
      },
    ],
    'expo-web-browser',
    '@react-native-community/datetimepicker',
    '@react-native-firebase/app',
    '@react-native-firebase/messaging',
    [
      'expo-build-properties',
      {
        android: {
          minSdkVersion: 24,
          compileSdkVersion: 36,
          targetSdkVersion: 36,
          enableProguardInReleaseBuilds: true,
        },
      },
    ],
    './with-ffmpeg-pod.js',
    './with-android-notification-channel.js',
    './with-notifee-maven-repo.js',
    './with-ios-modular-headers.js',
    './with-ios-pod-fixes.js',
  ],
  androidNavigationBar: { backgroundColor: '#ffffff' },
});