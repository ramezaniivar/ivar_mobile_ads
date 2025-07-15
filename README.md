<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->
# Ivar Mobile Ads

A Flutter package that provides a flexible and easy-to-use advertising solution for mobile applications. This package allows you to integrate and display various types of banner advertisements in your Flutter applications.

## Features

- 🚀 Easy initialization with app ID
- 📱 Multiple banner ad sizes support:
  - Standard (320x50)
  - Large (320x100)
  - Medium Rectangle (300x250)
- 🎯 Support for both textual and image-based banner ads
- ♻️ Auto-rotating banner carousel
- 📐 Responsive layout handling
- 🎨 Custom banner implementations

## Getting Started

### Installation

You can install this package in two ways:

#### 1. Using pub.dev

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  ivar_mobile_ads: ^latest_version
```

#### 2. Using GitHub

If you want to use the latest development version, you can install directly from GitHub:

```yaml
dependencies:
  ivar_mobile_ads:
    git:
      url: https://github.com/ramezaniivar/ivar_mobile_ads.git
      ref: latest_version
```

Then run:
```bash
flutter pub get
```

### Initialization

Initialize the ads service at app startup:

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Test App ID => "686bc09a8acfc04553c9f53a"
  // Initialize the ads service
  IvarMobileAds.instance.init('YOUR_APP_ID');

  runApp(const MyApp());
}
```
OR
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test App ID => "686bc09a8acfc04553c9f53a"
  // Initialize the ads service
  final adsInitialized = await IvarMobileAds.instance.init('YOUR_APP_ID');
  
  if (adsInitialized) {
    print('Ads service initialized successfully');
  }

  runApp(const MyApp());
}
```

## Usage

### Loading Banner Ads

```dart
// Load a standard banner ad
final bannerAd = await IvarMobileAds.instance.loadBannerAds(BannerAdSize.standard);

// Load a medium rectangle banner ad
final mediumRectangleAd = await IvarMobileAds.instance.loadBannerAds(BannerAdSize.mediumRectangle);
```

### Displaying Banner Ads

```dart
// Display the banner ad using the widget
if (bannerAd != null) {
  IvarBannerAdWidget(bannerAd)
}
```

### Available Banner Sizes

```dart
enum BannerAdSize {
  standard,        // 320x50
  large,          // 320x100
  mediumRectangle // 300x250
}
```

## Example

Here's a complete example of implementing a banner ad in your Flutter application:

```dart
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ad Example')),
      body: FutureBuilder<IvarBannerAd?>(
        future: IvarMobileAds.instance.loadBannerAds(BannerAdSize.standard),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return IvarBannerAdWidget(snapshot.data!);
          }
          return SizedBox();
        },
      ),
    );
  }
}
```

## Additional Information

### Support

For issues, feature requests, or general questions:
- Create an issue on our GitHub repository
- Contact our support team

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the LICENSE file for details.

### Best Practices

- Initialize the ads service as early as possible in your app lifecycle
- Handle null responses when loading ads
- Implement proper error handling
- Test different banner sizes in various screen configurations