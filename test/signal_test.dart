// Copyright (c) 2017, Jonah Williams. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:quiver/testing/async.dart';
import 'package:signal/signal.dart';
import 'package:test/test.dart';

void main() {
  group('SignalRef', () {
    test('is hot when it contains a non null value', () {
      var ref = new SignalRef(value: 2);

      expect(ref.isHot, true);
      expect(ref.value, 2);
    });

    test('is cold when it does not contain a non null value', () {
      var ref = new SignalRef();

      expect(ref.isCold, true);
      expect(ref.value, isNull);
    });

    test('does not become hot when passed a null value', () {
      var ref = new SignalRef();

      expect(ref.isCold, true);

      ref.value = null;

      expect(ref.isCold, true);
    });

    test(
        'does not update when passed a value which is equal '
        'to the existing value', () {
      var ref = new SignalRef(value: 2);
      var calledCount = 0;

      ref.onChange((_) {
        calledCount++;
      });

      expect(calledCount, 1);

      ref.value = 2;

      expect(calledCount, 1);
    });

    test('notifies subscribers when the value changes', () {
      var ref = new SignalRef();
      var callCount = 0;
      ref.onChange((_) {
        callCount++;
      });

      expect(callCount, 0);
      ref.value = 2;

      expect(callCount, 1);
    });
  });

  test('notifies subscribers of the current value if the signal is hot', () {
    var ref = new SignalRef(value: 2);
    var callCount = 0;

    ref.onChange((_) {
      callCount++;
    });

    expect(callCount, 1);
  });

  group('ComputeN', () {
    test('allows multiple signals to be combined into a single value', () {
      var refOne = new SignalRef(value: 2);
      var refTwo = new SignalRef(value: 3);
      var result = computeTwo(refOne, refTwo, (a, b) => a * b);

      expect(result.value, 6);
    });

    test('multiple synchronus changes only trigger a single update', () {
      return new FakeAsync().run((fakeAsync) {
        var refOne = new SignalRef(value: 2);
        var refTwo = new SignalRef(value: 3);
        var refThree = new SignalRef(value: 4);
        var result = computeThree(
          refOne,
          refTwo,
          refThree,
          (a, b, c) => a + b + c,
        );
        var calledCount = 0;
        result.onChange((_) {
          calledCount++;
        });
        fakeAsync.flushMicrotasks();

        expect(calledCount, 1);

        refOne.value = 1;
        refTwo.value = 2;
        refThree.value = 9;

        fakeAsync.flushMicrotasks();

        expect(calledCount, 2);
        expect(result.value, 12);
      });
    });
  });
}
