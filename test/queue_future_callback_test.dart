import 'package:flutter_test/flutter_test.dart';

import 'package:queue_future_callback/queue_future_callback.dart';

void main() {
  test('test_AddCallBack_Success', () async {
    futureCallBack() async {
      return Future.delayed(const Duration(seconds: 1));
    }

    QueueFutureCallback queueFutureCallback = QueueFutureCallback();
    queueFutureCallback.pauseConsumingCallback();
    await queueFutureCallback.addFutureIntoQueue(futureCallBack);
    expect(queueFutureCallback.futureCallbacks.last, futureCallBack);
  });

  test('test_ConsumeCallBack_Success', () async {
    futureCallBack() async {
      return Future.delayed(const Duration(seconds: 1));
    }

    QueueFutureCallback queueFutureCallback = QueueFutureCallback();
    await queueFutureCallback.addFutureIntoQueue(futureCallBack);
    await queueFutureCallback.addFutureIntoQueue(futureCallBack);
    await queueFutureCallback.addFutureIntoQueue(futureCallBack);
    expect(queueFutureCallback.status, QueueCallbackStatus.consumeSuccess);
    expect(queueFutureCallback.futureCallbacks.isEmpty, true);
  });

  test('test_ConsumeCallBack_When_A_FutureThrowError', () async {
    final exception = Exception('Future_Error');
    futureThrowError() async {
      return throw exception;
    }

    QueueFutureCallback queueFutureCallback = QueueFutureCallback(
      safetyConsume: false,
    );
    queueFutureCallback.pauseConsumingCallback();
    queueFutureCallback.addFutureIntoQueue(futureThrowError);
    expect(queueFutureCallback.resumeConsumingCallback(), throwsA(exception));
  });

  test('test_pauseResumeCallBack_Success', () async {
    Future<int> futureCallBack1() async {
      return 1;
    }

    Future<int> futureCallBack2() async {
      return 2;
    }

    QueueFutureCallback queueFutureCallback = QueueFutureCallback();
    await queueFutureCallback.addFutureIntoQueue(futureCallBack1);
    queueFutureCallback.pauseConsumingCallback();
    await queueFutureCallback.addFutureIntoQueue(futureCallBack2);
    expect(queueFutureCallback.status, QueueCallbackStatus.pause);
    await queueFutureCallback.resumeConsumingCallback();
    expect(queueFutureCallback.status, QueueCallbackStatus.consumeSuccess);
  });

  test('test_disposeFutureCallback_Success', () async {
    futureCallBack() async {
      return 1;
    }

    QueueFutureCallback queueFutureCallback = QueueFutureCallback();
    await queueFutureCallback.addFutureIntoQueue(futureCallBack);
    queueFutureCallback.addFutureIntoQueue(futureCallBack);
    queueFutureCallback.addFutureIntoQueue(futureCallBack);
    queueFutureCallback.dispose();
    expect(queueFutureCallback.status, QueueCallbackStatus.disposed);
    expect(queueFutureCallback.futureCallbacks.isEmpty, true);
  });
}
