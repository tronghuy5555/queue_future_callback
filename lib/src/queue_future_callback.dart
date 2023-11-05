import 'dart:collection';

import 'package:flutter/rendering.dart';

enum QueueCallbackStatus {
  initial,
  showing,
  pause,
  done,
}

Duration kDelayTime = const Duration(milliseconds: 100);

class QueueFutureCallback {
  static const String TAG = 'QueueFutureCallback';
  Duration? delayTime;

  QueueFutureCallback({
    this.delayTime,
  });

  final Queue<Future? Function()> futureCallbacks = Queue();
  QueueCallbackStatus _status = QueueCallbackStatus.initial;
  bool get isShowingPopUp => _status == QueueCallbackStatus.showing;

  void addFutureIntoQueue(Future? Function() futureCallBack) async {
    try {
      if (_status == QueueCallbackStatus.done ||
          _status == QueueCallbackStatus.initial) {
        futureCallbacks.add(futureCallBack);
        await _consumeCallbackWhenReady();
      } else {
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
    _status = QueueCallbackStatus.showing;
    while (futureCallbacks.isNotEmpty) {
      final latestCallback = futureCallbacks.removeFirst();
      await Future.delayed(delayTime ?? kDelayTime);
      if (_status == QueueCallbackStatus.pause) {
        //*Put latest callback in the first position and exit the loop
        futureCallbacks.addFirst(latestCallback);
        return;
      }
      await latestCallback.call();
      await Future.delayed(delayTime ?? kDelayTime);
    }
    _status = QueueCallbackStatus.done;
  }

  void pauseConsumingCallback() {
    _status = QueueCallbackStatus.pause;
  }

  void resumeConsumingCallback() {
    if (_status == QueueCallbackStatus.pause) {
      _consumeCallbackWhenReady();
    }
  }

  void dispose() {
    futureCallbacks.clear();
  }
}
