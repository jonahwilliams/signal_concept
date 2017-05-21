// Copyright (c) 2017, Jonah Williams. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:signal/signal.dart';
import 'package:test/test.dart';
import 'package:quiver/testing/async.dart';

void main() {
  for (var isSync in [true, false]) {
    var name = isSync ? 'SignalRef.Sync' : 'SignalRef.Async';

    group(name, () {
      test('is hot when it contains a non null value', () {
        var ref = new SignalRef(value: 2, sync: isSync);

        expect(ref.isHot, true);
        expect(ref.value, 2);
      });

      test('is cold when it does not contain a non null value', () {
        var ref = new SignalRef(sync: isSync);

        expect(ref.isCold, true);
        expect(ref.value, isNull);
      });

      test('does not become hot when passed a null value', () {
        var ref = new SignalRef(sync: isSync);

        expect(ref.isCold, true);

        ref.value = null;

        expect(ref.isCold, true);
      });

      test(
          'does not update when passed a value which is equal '
          'to the existing value', () {
        var ref = new SignalRef(value: 2, sync: isSync);
        var calledCount = 0;

        ref.onChange((_) {
          calledCount++;
        });

        expect(calledCount, 1);

        ref.value = 2;

        expect(calledCount, 1);
      });

      test('notifies subscribers when the value changes', () {
        new FakeAsync().run((fakeAsync) {
          var ref = new SignalRef(sync: isSync);
          var callCount = 0;
          ref.onChange((_) {
            callCount++;
          });

          expect(callCount, 0);
          ref.value = 2;

          if (isSync) {
            expect(callCount, 1);
          } else {
            expect(callCount, 0);
            fakeAsync.flushMicrotasks();
            expect(callCount, 1);
          }
        });
      });

      test('notifies subscribers of the current value if the signal is hot',
          () {
        var ref = new SignalRef(value: 2, sync: isSync);
        var callCount = 0;

        ref.onChange((_) {
          callCount++;
        });

        expect(callCount, 1);
      });
    });

    group('ComputeN', () {
      test('allows multiple signals to be combined into a single value', () {
        var refOne = new SignalRef(value: 2);
        var refTwo = new SignalRef(value: 3);
        var result = computeTwo(refOne, refTwo, (a, b) => a * b);

        expect(result.value, 6);
      });
    });
  }
}
