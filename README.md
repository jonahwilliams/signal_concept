# signal

A proof of concept for a Signal (value + changes over time) implementation in Dart.

## Usage

A SignalRef allows you to change the value of a Signal.  A SignalRef can be
cooerced into a Signal (SignalRef extends Signal).  This distinction is useful because it allows the developer to control what parts of the code can read/write a signal value, and which parts can only read it.

```dart
var ref = new SignalRef(value: 2);
ref.value = 3;

Signal<int> signal = ref;
```

New signals can be dervied from existing ones using computeN functions.  Any time the
value of one of the signal changes, the function will be reevaulated.

```dart
var refOne = new SignalRef(value: 3);
var refTwo = new SignalRef(value: 'Hello');
var sentence = computeTwo(refOne, refTwo, (a, b) => a * b);

print(sentence.value);
// => 'HelloHelloHello';
```

A Signal without an initial value (or a value of null) is marked as "cold", and will
not trigger updates in computations.  As a result, Null cannot be used as a regular value inside of signals.  However, setting one to null will once again mark it as "cold".

```dart
var refOne = new SignalRef();
var refTwo = new SignalRef(value: 2);

var timesResult = computeTwo(refOne, refTwo, (a, b) => a * b);
print(timesResult.value);
// => Null

refOne.value = 3;
print(timesResult.value);
// => 6

```

If a new value is set which is equal to the old value (using `==`), then the signal does not trigger updates.

```dart
var calledCount = 0;
var refOne = new SignalRef(value: 2);

refOne.onChange((_) {
  calledCount++;
});

refOne.value = 2;
refOne.value = 2;

print(calledCount);
// => 0;
```
