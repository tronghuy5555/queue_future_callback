<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

[![GitHub Actions Build ✅](https://github.com/tronghuy5555/queue_future_callback/actions/workflows/dart.yml/badge.svg)](https://codecov.io/gh/tronghuy5555/queue_future_callback)
[![codecov](https://codecov.io/gh/tronghuy5555/queue_future_callback/graph/badge.svg?token=W12CC9R3ON)](https://codecov.io/gh/tronghuy5555/queue_future_callback)

This package is useful when you want to add multiple future callbacks sequentially

A specific use case: you want show popup sequentially to avoid multiple dialog, overlay banner show it at the same time.

## Usage

```dart
QueueFutureCallback queueFutureCallBack = QueueFutureCallback();
final popUp1 = Future.delay(Duration(second: 1));
final popUp2 = Future.delay(Duration(second: 1));
final popUp3 = Future.delay(Duration(second: 1));
queueFutureCallBack.addFutureIntoQueue(() => popUp1);
queueFutureCallBack.addFutureIntoQueue(() => popUp2);
queueFutureCallBack.addFutureIntoQueue(() => popUp2);
```