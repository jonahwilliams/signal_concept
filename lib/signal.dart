// Copyright (c) 2017, Jonah Williams. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library signal;

import 'dart:async';

/// A signal is a value and it's changes over time.
abstract class Signal<T> {
  /// Creates a [Signal] with a constant value.
  factory Signal.Constant(T value) => new _ConstantSignal._(value);

  Signal._();

  /// The current value of the signal.
  T get value;

  /// A stream of the updates to the Signal's value.
  Stream<T> get onValueUpdated;

  /// A stream of [Change]s to the Signal's value.
  Stream<Change<T>> get onValueChanged =>
      onValueChanged.transform(_changeTransform());

  /// Cleans up all interal streams and subscriptions.
  void dispose();
}

/// A signal which can be changed.
class SignalRef<T> extends Signal<T> {
  final _controller = new StreamController<T>.broadcast();
  T _value;

  /// Creates a new [SignalRef].
  ///
  /// Passing no [value] or `null` will create a `cold` signal.
  SignalRef([this._value]) : super._();

  @override
  T get value => _value;

  set value(T newValue) {
    if (newValue != null && newValue != _value) {
      _value = newValue;
      _controller.add(_value);
    }
  }

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Stream<T> get onValueUpdated => _controller.stream;

  @override
  String toString() => 'Signal($_value)';
}

class _ConstantSignal<T> extends Signal<T> {
  T _value;

  _ConstantSignal._(this._value) : super._();

  @override
  T get value => _value;

  @override
  String toString() => 'Signal($_value)';

  @override
  Stream<T> get onValueUpdated => const Stream.empty();

  @override
  void dispose() {}
}

/// Create a new [Signal] from an existing signal and a function.
Signal<B> computeOne<A, B>(Signal<A> signal, B f(A a)) => _compute([signal], f);

/// Create a new [Signal] from two existing signals and a function.
Signal<C> computeTwo<A, B, C>(
  Signal<A> signalA,
  Signal<B> signalB,
  C f(A a, B b),
) =>
    _compute([signalA, signalB], f);

/// Create a new [Signal] from three existing signals and a function.
Signal<D> computeThree<A, B, C, D>(
  Signal<A> signalA,
  Signal<B> signalB,
  Signal<C> signalC,
  C f(A a, B b, C c),
) =>
    _compute([signalA, signalB, signalC], f);

/// Create a new [Signal] from four existing signals and a function.
Signal<E> computeFour<A, B, C, D, E>(
  Signal<A> signalA,
  Signal<B> signalB,
  Signal<C> signalC,
  Signal<D> signalD,
  E f(A a, B b, C c, D d),
) =>
    _compute([signalA, signalB, signalC, signalD], f);

/// Create a new [Signal] from five existing signals and a function.
Signal<E> computeFive<A, B, C, D, E, F>(
  Signal<A> signalA,
  Signal<B> signalB,
  Signal<C> signalC,
  Signal<D> signalD,
  Signal<E> signalE,
  F f(A a, B b, C c, D d, E e),
) =>
    _compute([signalA, signalB, signalC, signalD, signalE], f);

/// Create a new [Signal] from a list of signals and a function.
Signal<B> computeMany<A, B>(List<Signal<A>> signals, B f(List<A> values)) =>
    _compute(signals, f);

Signal<Object> _compute(List<Signal<Object>> signals, Function computation) {
  var allAreHot = signals.every((signal) => signal.value != null);
  Object value;
  bool hasRunInMicrotask = false;

  if (allAreHot) {
    value = Function.apply(
        computation, signals.map((signal) => signal.value).toList());
  }

  var ref = new SignalRef<Object>(value);
  for (var signal in signals) {
    signal.onValueUpdated.listen((_) {
      if (!allAreHot) {
        allAreHot = signals.every((signal) => signal.value != null);
      }
      if (allAreHot) {
        if (!hasRunInMicrotask) {
          // defer update until the end of the current microtask queue,
          // prevent more than one update.
          hasRunInMicrotask = true;
          scheduleMicrotask(() {
            hasRunInMicrotask = false;
            ref.value = Function.apply(
                computation, signals.map((signal) => signal.value).toList());
          });
        }
      }
    });
  }
  return ref;
}

/// Describes how a Signal value changes.
class Change<T> {
  /// The old value of the signal.
  final T previous;

  /// The current value of the signal.
  final T current;

  /// Creates a new Change.
  Change(this.previous, this.current);

  @override
  String toString() => 'Change($previous => $current)';
}

StreamTransformer<T, Change<T>> _changeTransform<T>() {
  T oldValue;
  return new StreamTransformer.fromHandlers(handleData: (data, sink) {
    var change = new Change(oldValue, data);
    oldValue = data;
    sink.add(change);
  });
}
