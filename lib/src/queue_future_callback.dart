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

class QueueFutureCallback {
  static const String TAG = 'QueueFutureCallback';
  final Duration? delayTime;
  final ValueChanged<QueueCallbackStatus>? onStatusChanged;

  QueueFutureCallback({
    this.delayTime,
    this.onStatusChanged,
  });

  final Queue<Future? Function()> futureCallbacks = Queue();
  QueueCallbackStatus _status = QueueCallbackStatus.initial;
  QueueCallbackStatus get status => _status;

  bool get isConsumingCallback => _status == QueueCallbackStatus.consuming;

  bool shouldConsumeCallBack() {
    return _status == QueueCallbackStatus.consumeSuccess ||
        _status == QueueCallbackStatus.initial ||
        _status == QueueCallbackStatus.resume;
  }

  Future? addFutureIntoQueue(Future? Function() futureCallBack) async {
    try {
      if (shouldConsumeCallBack()) {
        futureCallbacks.add(futureCallBack);
        debugPrint(
            '[$TAG] - add future callback success ${futureCallBack.hashCode}');
        await _consumeCallbackWhenReady();
      } else if (status != QueueCallbackStatus.disposed) {
        futureCallbacks.add(futureCallBack);
      }
    } catch (e, _) {
      futureCallBack.call();
      debugPrint(
        '[$TAG] - Somethings wrong was wrong, consume popup immediately to avoiding freezing app',
      );
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
            '[$TAG] - Consuming - pause future callback and put latest callback into first position ${latestCallback.hashCode}');
        futureCallbacks.addFirst(latestCallback);
        return;
      }
      if (_status == QueueCallbackStatus.disposed) {
        debugPrint('[$TAG] - Consuming - disposed future callback');
        return;
      }
      debugPrint(
          '[$TAG]- Consuming - consume future callback success ${latestCallback.hashCode}');
      await latestCallback.call();
      await Future.delayed(delayTime ?? kDelayTime);
    }
    _onStatusChanged(QueueCallbackStatus.consumeSuccess);
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
      debugPrint('[$TAG] - status changed: $_status ----> $status');
      _status = status;
      onStatusChanged?.call(status);
    }
  }

  void dispose() {
    debugPrint('[$TAG] - disposed queue');
    _onStatusChanged(QueueCallbackStatus.disposed);
    futureCallbacks.clear();
  }
}
