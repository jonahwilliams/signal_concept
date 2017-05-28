// Copyright (c) 2017, Jonah Williams. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Support for doing something awesome.
///
/// More dartdocs go here.
library property;

import 'dart:async';

/// A property is a value and it's changes over time.
abstract class Property<T> {
  /// Creates a [Property] with a constant value.
  factory Property.Constant(T value) => new _ConstantProperty._(value);

  Property._();

  /// The current value of the property.
  T get value;

  /// A stream of the updates to the property's value.
  Stream<T> get onValueUpdated;

  /// A stream of [Change]s to the property's value.
  Stream<Change<T>> get onValueChanged =>
      onValueChanged.transform(_changeTransform());

  /// Cleans up all interal streams and subscriptions.
  void dispose();
}

/// A property which can be changed.
class PropertyRef<T> extends Property<T> {
  final _controller = new StreamController<T>.broadcast();
  T _value;

  /// Creates a new [PropertyRef].
  PropertyRef([this._value]) : super._();

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
  String toString() => 'property($_value)';
}

class _ConstantProperty<T> extends Property<T> {
  T _value;

  _ConstantProperty._(this._value) : super._();

  @override
  T get value => _value;

  @override
  String toString() => 'property($_value)';

  @override
  Stream<T> get onValueUpdated => const Stream.empty();

  @override
  void dispose() {}
}

/// Create a new [Property] from an existing property and a function.
Property<B> computeOne<A, B>(Property<A> property, B f(A a)) =>
    _compute([property], f);

/// Create a new [Property] from two existing propertys and a function.
Property<C> computeTwo<A, B, C>(
  Property<A> propertyA,
  Property<B> propertyB,
  C f(A a, B b),
) =>
    _compute([propertyA, propertyB], f);

/// Create a new [Property] from three existing propertys and a function.
Property<D> computeThree<A, B, C, D>(
  Property<A> propertyA,
  Property<B> propertyB,
  Property<C> propertyC,
  C f(A a, B b, C c),
) =>
    _compute([propertyA, propertyB, propertyC], f);

/// Create a new [Property] from four existing propertys and a function.
Property<E> computeFour<A, B, C, D, E>(
  Property<A> propertyA,
  Property<B> propertyB,
  Property<C> propertyC,
  Property<D> propertyD,
  E f(A a, B b, C c, D d),
) =>
    _compute([propertyA, propertyB, propertyC, propertyD], f);

/// Create a new [Property] from five existing propertys and a function.
Property<E> computeFive<A, B, C, D, E, F>(
  Property<A> propertyA,
  Property<B> propertyB,
  Property<C> propertyC,
  Property<D> propertyD,
  Property<E> propertyE,
  F f(A a, B b, C c, D d, E e),
) =>
    _compute([propertyA, propertyB, propertyC, propertyD, propertyE], f);

/// Create a new [Property] from a list of propertys and a function.
Property<B> computeMany<A, B>(
        List<Property<A>> propertys, B f(List<A> values)) =>
    _compute(propertys, f);

Property<Object> _compute(
    List<Property<Object>> propertys, Function computation) {
  var allAreHot = propertys.every((property) => property.value != null);
  Object value;
  bool hasRunInMicrotask = false;

  if (allAreHot) {
    value = Function.apply(
        computation, propertys.map((property) => property.value).toList());
  }

  var ref = new PropertyRef<Object>(value);
  for (var property in propertys) {
    property.onValueUpdated.listen((_) {
      if (!allAreHot) {
        allAreHot = propertys.every((property) => property.value != null);
      }
      if (allAreHot) {
        if (!hasRunInMicrotask) {
          // defer update until the end of the current microtask queue,
          // prevent more than one update.
          hasRunInMicrotask = true;
          scheduleMicrotask(() {
            hasRunInMicrotask = false;
            ref.value = Function.apply(computation,
                propertys.map((property) => property.value).toList());
          });
        }
      }
    });
  }
  return ref;
}

/// Describes how a property value changes.
class Change<T> {
  /// The old value of the property.
  final T previous;

  /// The current value of the property.
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
