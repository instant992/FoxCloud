[![ru](https://img.shields.io/badge/lang-ru-blue)](https://github.com/this-xkit/Flowvy/blob/main/README.md)
[![en](https://img.shields.io/badge/lang-en-red)](https://github.com/this-xkit/Flowvy/blob/main/README.en.md)
[![Last Version](https://img.shields.io/github/release/this-xkit/Flowvy/all.svg?style=flat-square&cacheSeconds=3600)](https://github.com/this-xkit/Flowvy/releases/)
[![Downloads](https://img.shields.io/github/downloads/this-xkit/Flowvy/total?style=flat-square&logo=github&cacheSeconds=3600)](https://github.com/this-xkit/Flowvy/releases/)

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

### 🔗 Enhanced Remnawave Integration

* **HWID Support** — device authentication via unique hardware identifier
* **Auto-update interval** — automatic profile updates on schedule from panel
* **Support link** — direct link to provider's support
* **Announce** — receive important messages from your provider

### 🔔 Notification System

#### Traffic Notifications
System notifications when reaching **80%**, **90%**, and **100%** of traffic usage with progress indicator.

#### Subscription Notifications
Reminders **7**, **3**, and **1** day before subscription expiration, as well as when expired.

**Customize notifications via HTTP headers:**

| Header | Description | Format |
|--------|-------------|--------|
| `expiry-notification-title` | Title for upcoming expiration notification | **Required** `base64:...` |
| `expiry-notification-body` | Body for upcoming expiration notification | **Required** `base64:...` |
| `expiry-notification-title-expired` | Title for expired subscription notification | **Required** `base64:...` |
| `renew-url` | URL for renewal (adds "Renew" button) | **Required** `base64:...` |

> **Important:** All values must be base64-encoded with `base64:` prefix (non-ASCII characters are not supported in HTTP headers).

**Example:**
```
expiry-notification-title: base64:0KDQsNGB0YjQuNGA0LXQvdC90YvQuSDQtNC+0YHRgtGD0L8g0LjRgdGC0ZHQug==
expiry-notification-body: base64:0JLQsNGIINC/0YDQvtCy0LDQudC00LXRgCDQvtGC0LrQu9GO0YfQuNGCINC/0L7QtNC/0LjRgdC60YMg0YfQtdGA0LXQtyAzINC00L3Rjw==
renew-url: base64:aHR0cHM6Ly9leGFtcGxlLmNvbS9yZW5ldw==
```

### ⚙️ Flexible Configuration

#### Smart Default Settings
Pre-configured parameters for quick start without complex configuration.

#### Core Settings Override from Config
The client automatically uses parameters from subscription config when specified:

* `log-level` — logging level
* `keep-alive-interval` — keep-alive interval
* `ipv6` — IPv6 support
* `mixed-port` — mixed proxy port
* `allow-lan` — LAN access
* `unified-delay` — unified delay
* `find-process-mode` — process detection mode
* `stack` — TUN stack (e.g., `gvisor`)

### 🎨 Improved Interface

* **Russian localization** — complete translation of interface and installer
* **Metainfo widget** — subscription information display on home page
* **UI/UX redesign** — numerous improvements compared to original FlClash
* **Bug fixes** — resolved issues from original client

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
