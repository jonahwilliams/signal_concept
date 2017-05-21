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

  /// The current value of the signal.
  T get value;

  bool get isSync;

  /// Does the signal currently have a value?
  bool get isHot;

  /// Does the signal currently not have a value?
  bool get isCold;

  /// Coerces the updates from a signal into a [Stream].
  Stream<T> toStream();

  /// A callback which fires everytime the signal value updates.
  ///
  /// [ignoreFirst] defaults to false and skips any initial updates, since
  /// they can be read from Signal#value.
  StreamSubscription onChange(void f(T newValue), {bool ignoreFirst: false});

  /// Cleans up all interal streams and subscriptions.
  void dispose();
}

/// A signal which can be changed.
abstract class SignalRef<T> implements Signal<T> {
  /// Creates a new [SignalRef].
  ///
  /// Passing no [value] or `null` will create a `cold` signal.
  factory SignalRef({T value, sync = false}) {
    if (sync) {
      return new _SyncSignalRef._(value);
    }
    return new _AsyncSignalRef._(value);
  }

  /// Set the value of the signal, triggering updates.
  set value(T newValue);
}

class _SyncSignalRef<T> implements SignalRef<T> {
  final _controller = new StreamController<T>.broadcast(sync: true);

  bool _hasInitialized;
  T _value;

  _SyncSignalRef._(this._value) : _hasInitialized = _value != null;

  @override
  T get value => _value;

  @override
  bool get isSync => true;

  @override
  set value(T newValue) {
    if (newValue != null && newValue != _value) {
      _hasInitialized = true;
      _value = newValue;
      _controller.add(_value);
    }
  }

  @override
  bool get isHot => _hasInitialized == true;

  @override
  bool get isCold => _hasInitialized == false;

  @override
  StreamSubscription onChange(void f(T newValue), {bool ignoreFirst: false}) {
    if (_hasInitialized && !ignoreFirst) {
      f(_value);
    }
    return _controller.stream.listen(f);
  }

  @override
  void dispose() {
    _controller.close();
  }

  @override
  Stream<T> toStream() => _controller.stream;

  @override
  String toString() => 'Signal(${_hasInitialized ? _value : "Uninitialized"})';
}

class _AsyncSignalRef<T> implements SignalRef<T> {
  final _controller = new StreamController<T>.broadcast();

  bool _hasInitialized;
  T _value;

  _AsyncSignalRef._(this._value) : _hasInitialized = _value != null;

  @override
  T get value => _value;

  @override
  bool get isSync => false;

  @override
  bool get isHot => _hasInitialized == true;

  @override
  bool get isCold => _hasInitialized == false;

  @override
  set value(T newValue) {
    if (newValue != null && newValue != _value) {
      _hasInitialized = true;
      _value = newValue;
      _controller.add(_value);
    }
  }

  @override
  StreamSubscription onChange(void f(T value), {bool ignoreFirst: false}) {
    if (_hasInitialized && !ignoreFirst) {
      f(_value);
    }
    return _controller.stream.listen(f);
  }

  @override
  Signal<T> toSignal() => this;

  @override
  Stream<T> toStream() => _controller.stream;

  @override
  String toString() => 'Signal(${_hasInitialized ? _value : "Uninitialized"})';

  @override
  void dispose() {
    _controller.close();
  }
}

class _ConstantSignal<T> implements Signal<T> {
  T _value;

  _ConstantSignal._(this._value);

  @override
  T get value => _value;

  @override
  bool get isSync => true;

  @override
  bool get isHot => _value != null;

  @override
  bool get isCold => _value != null;

  @override
  StreamSubscription onChange(f, {bool ignoreFirst}) {
    return new Stream.empty().listen(f);
  }

  @override
  String toString() => 'Stream($_value)';

  @override
  Stream<T> toStream() => new Stream.empty();

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
    _compute([signalA, signalB], f);

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
  var isSync = signals.every((signal) => signal.isSync);
  var allAreHot = signals.every((signal) => signal.isHot);
  Object value;

  if (allAreHot) {
    value = Function.apply(
        computation, signals.map((signal) => signal.value).toList());
  }

  var ref = new SignalRef<Object>(value: value, sync: isSync);
  for (var signal in signals) {
    signal.onChange((_) {
      if (!allAreHot) {
        allAreHot = signals.every((signal) => signal.isHot);
      }
      if (allAreHot) {
        ref.value = Function.apply(
            computation, signals.map((signal) => signal.value).toList());
      }
    }, ignoreFirst: true);
  }
  return ref;
}
