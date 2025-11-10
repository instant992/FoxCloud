[![ru](https://img.shields.io/badge/lang-ru-blue)](https://github.com/this-xkit/Flowvy/blob/main/README.md)
[![en](https://img.shields.io/badge/lang-en-red)](https://github.com/this-xkit/Flowvy/blob/main/README.en.md)
[![Downloads](https://img.shields.io/github/downloads/this-xkit/Flowvy/total?style=flat-square&logo=github)](https://github.com/this-xkit/Flowvy/releases/)
[![Last Version](https://img.shields.io/github/release/this-xkit/Flowvy/all.svg?style=flat-square)](https://github.com/this-xkit/Flowvy/releases/)

# Flowvy

<p align="center">
  <img src="https://github.com/this-xkit/Flowvy/blob/main/assets/images/icon_bg_white.png" alt="Flowvy Logo" width="100">
</p>

<p align="center">
  <strong>A modern cross-platform Mihomo client</strong>
  <br>
  With a focus on improved user experience and integration with modern <a href="https://github.com/remnawave/panel">Remnawave</a> panel.
</p>

<p align="center">
  <img src="https://github.com/this-xkit/Flowvy/blob/main/assets/images/screenshot/Flowvy_Dark_Light.png" alt="Flowvy Screenshot" width="800">
</p>

## About The Project

**Flowvy** is a multi-platform proxy client based on the FlClash project — simple, easy to use, open-source, and ad-free. Currently supports Windows and Android.

---

## ✨ Features

* **Enhanced Remnawave integration:** Support for **HWID**, Auto-update interval, Support link, Announce.
* **Dynamic notifications:** Receive important messages from your provider.
* Traffic: system notifications at 80%, 90%, and 100% of traffic usage.
* Subscription: system notifications 7, 3, 1 day before subscription expires. To customize notifications, use headers: expiry-notification-title (notification title), expiry-notification-body (notification body), renew-url (if specified, the notification will have a "Renew" button), expiry-notification-title-expired (title for expired subscription notification).
* **Smart default settings:** Pre-configured parameters for quick start without extra configuration.
* **Core settings override from config:** if the config specifies parameters: log-level, keep-alive-interval, ipv6, mixed-port, allow-lan, unified-delay, find-process-mode — the client will use settings from the config, not its own.
* **Russian localization:** Full translation of the interface and installer to Russian.
* **Redesign:** Numerous UI/UX changes compared to the original.
* **New widget on Home screen:** Metainfo widget displays subscription information directly on the home page.
* **Bug fixes from the original client**

---

## 🚀 Getting Started

Pre-built binaries for all platforms are available on the [**Releases**](https://github.com/this-xkit/Flowvy/releases) page.

---

<details>
<summary>🛠️ Building From Source</summary>

If you want to build the project yourself, follow these steps.

### 1. Prerequisites

Ensure you have all the necessary tools installed:

* [**Flutter SDK**](https://flutter.dev/docs/get-started/install)
* [**Go**](https://go.dev/dl/)
* [**Rust**](https://www.rust-lang.org/tools/install)
* **Git**

As well as the tools for your target platform:

* **For Windows:** [**Visual Studio**](https://visualstudio.microsoft.com/downloads/) with the **"Desktop development with C++"** workload and [**Inno Setup**](https://jrsoftware.org/isinfo.php).
* **For Android:** **Android SDK** and **Android NDK**.
* **For Linux:** `libayatana-appindicator3-dev` and `libkeybinder-3.0-dev` packages.

### 2. Cloning the Repository

```bash
# Clone the repository
git clone https://github.com/this-xkit/Flowvy.git

# Navigate to the project directory
cd Flowvy

# Download the Clash.Meta core and other dependencies. Do not skip this step!
git submodule update --init --recursive
```

### 3. Install Project Dependencies

Before the first build, you need to fetch all Dart packages:

```bash
flutter pub get
```

### 4. Running the Build

Use the built-in `setup.dart` script to build for a specific platform. For most modern PCs, you will need the `amd64` architecture.

#### Windows

```bash
dart .\setup.dart windows --arch <arm64 | amd64>
```

#### Linux

```bash
dart .\setup.dart linux --arch <arm64 | amd64>
```

#### macOS

```bash
dart .\setup.dart macos --arch <arm64 | amd64>
```

#### Android

Ensure the `ANDROID_NDK` environment variable is set.

```bash
dart .\setup.dart android
```

</details>
