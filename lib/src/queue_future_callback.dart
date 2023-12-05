import 'dart:collection';

import 'package:flutter/rendering.dart';

enum QueueCallbackStatus {
  initial,
  consuming,
  pause,
  resume,
  consumeSuccess,
  disposed,
}

Duration kDelayTime = const Duration(milliseconds: 100);
typedef FutureCallBack = Future? Function();

class QueueFutureCallback {
  static const String tag = 'QueueFutureCallback';
  final Duration? delayTime;

  /// Wrap try/catch when consume latest future callback to avoid any errors
  final bool safetyConsume;

  final ValueChanged<QueueCallbackStatus>? onStatusChanged;

  QueueFutureCallback({
    this.delayTime,
    this.onStatusChanged,
    this.safetyConsume = true,
  });

  final Queue<FutureCallBack> futureCallbacks = Queue();

  QueueCallbackStatus _status = QueueCallbackStatus.initial;
  QueueCallbackStatus get status => _status;

  bool get isConsumingCallback => _status == QueueCallbackStatus.consuming;

  bool shouldConsumeCallBack() {
    return _status == QueueCallbackStatus.consumeSuccess ||
        _status == QueueCallbackStatus.initial ||
        _status == QueueCallbackStatus.resume;
  }

  Future? addFutureIntoQueue(FutureCallBack futureCallBack) async {
    if (shouldConsumeCallBack()) {
      futureCallbacks.add(futureCallBack);
      debugPrint(
          '[$tag] - add future callback success ${futureCallBack.hashCode}');
      await _consumeCallbackWhenReady();
    } else if (status != QueueCallbackStatus.disposed) {
      futureCallbacks.add(futureCallBack);
    }
  }

  Future? _consumeCallbackWhenReady() async {
    if (!shouldConsumeCallBack()) {
      return;
    }
    _onStatusChanged(QueueCallbackStatus.consuming);
    while (futureCallbacks.isNotEmpty) {
      final latestCallback = futureCallbacks.removeFirst();
      await Future.delayed(delayTime ?? kDelayTime);
      if (_status == QueueCallbackStatus.pause) {
        //*Put latest callback in the first position and exit the loop
        debugPrint(
            '[$tag] - Consuming - pause future callback and put latest callback into first position ${latestCallback.hashCode}');
        futureCallbacks.addFirst(latestCallback);
        return;
      }
      if (_status == QueueCallbackStatus.disposed) {
        debugPrint('[$tag] - Consuming - disposed future callback');
        return;
      }
      debugPrint(
          '[$tag]- Consuming - consume future callback success ${latestCallback.hashCode}');
      await _tryCatchFutureCallBack(latestCallback);
      await Future.delayed(delayTime ?? kDelayTime);
    }
    _onStatusChanged(QueueCallbackStatus.consumeSuccess);
  }

  Future? _tryCatchFutureCallBack(FutureCallBack futureCallBack) async {
    try {
      await futureCallBack.call();
    } catch (e) {
      debugPrint(
          '[$tag]- Consuming - future callback error ${futureCallBack.hashCode}');
      if (!safetyConsume) {
        _onStatusChanged(QueueCallbackStatus.consumeSuccess);
        rethrow;
      }
    }
  }

  void pauseConsumingCallback() {
    _onStatusChanged(QueueCallbackStatus.pause);
  }

  Future resumeConsumingCallback() async {
    if (_status == QueueCallbackStatus.pause) {
      _onStatusChanged(QueueCallbackStatus.resume);
      await _consumeCallbackWhenReady();
    }
  }

  void _onStatusChanged(QueueCallbackStatus status) {
    if (_status != status) {
      debugPrint('[$tag] - status changed: $_status ----> $status');
      _status = status;
      onStatusChanged?.call(status);
    }
  }

  void dispose() {
    debugPrint('[$tag] - disposed queue');
    _onStatusChanged(QueueCallbackStatus.disposed);
    futureCallbacks.clear();
  }
}
