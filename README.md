# Ivar Mobile Ads

A Flutter package that provides a flexible and easy-to-use advertising solution for mobile applications.
This package allows you to integrate and display various types of **banner** and **interstitial** advertisements in your Flutter applications.

## Features

* 🚀 Easy initialization with app ID
* 📱 Multiple **banner ad** sizes support:

  * Standard (320x50)
  * Large (320x100)
  * Medium Rectangle (300x250)
* 🎯 Support for both textual and image-based banner ads
* ♻️ Auto-rotating banner carousel
* 📐 Responsive layout handling
* 🎨 Custom banner implementations
* 🖼️ **Interstitial ads support** (full-screen ads)

## Getting Started

### Installation

You can install this package in two ways:

#### 1. Using pub.dev

```yaml
dependencies:
  ivar_mobile_ads: ^latest_version
```

#### 2. Using GitHub

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
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test App ID => "686bc09a8acfc04553c9f53a"
  final adsInitialized = await IvarMobileAds.instance.init('YOUR_APP_ID');
  
  if (adsInitialized) {
    print('Ads service initialized successfully');
  }

  runApp(const MyApp());
}
```

## Usage

### Banner Ads

#### Loading Banner Ads

```dart
final bannerAd = await IvarMobileAds.instance.loadBannerAds(BannerAdSize.standard);
final mediumRectangleAd = await IvarMobileAds.instance.loadBannerAds(BannerAdSize.mediumRectangle);
```

#### Displaying Banner Ads

```dart
if (bannerAd != null) {
  IvarBannerAdWidget(bannerAd)
}
```

#### Available Banner Sizes

```dart
enum BannerAdSize {
  standard,        // 320x50
  large,           // 320x100
  mediumRectangle  // 300x250
}
```

### Interstitial Ads

#### Loading & Showing Interstitial Ads

```dart
final isLoaded = await IvarMobileAds.instance.loadInterstitialAd();

if (isLoaded && context.mounted) {
  IvarMobileAds.instance.showInterstitialAd(context);
}
```

## Example

```dart
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ad Example')),
      body: FutureBuilder<IvarBannerAd?>(
        future: IvarMobileAds.instance.loadBannerAds(BannerAdSize.standard),
        builder: (context, snapshot) {
          return Column(
            children: [
              if (snapshot.hasData && snapshot.data != null)
                IvarBannerAdWidget(snapshot.data!),
              ElevatedButton(
                onPressed: () async {
                  final isLoaded = await IvarMobileAds.instance.loadInterstitialAd();
                  if (isLoaded && context.mounted) {
                    IvarMobileAds.instance.showInterstitialAd(context);
                  }
                },
                child: const Text("Show Interstitial Ad"),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

## Additional Information

### Support

For issues, feature requests, or general questions:

* Create an issue on our GitHub repository
* Contact our support team

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the LICENSE file for details.

### Best Practices

* Initialize the ads service as early as possible in your app lifecycle
* Handle null responses when loading ads
* Implement proper error handling
* Test different banner sizes in various screen configurations
* Show interstitial ads only at natural breakpoints for a better user experience
