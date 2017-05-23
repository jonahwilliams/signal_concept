# signal

A proof of concept for a Signal (value + changes over time) implementation in Dart.

## Usage

A SignalRef allows you to change the value of a Signal.  A SignalRef can be
cooerced into a Signal (SignalRef extends Signal).  This distinction is useful because it allows the developer to control what parts of the code can read/write a signal value and which parts can only read it.

```dart
var ref = new SignalRef<int>(2);
ref.value = 3;

Signal<int> signal = ref;
```

New signals can be dervied from existing ones using computeN functions.  Any time the
value of one of the signal changes the function will be reevaulated.

```dart
var refOne = new SignalRef(3);
var refTwo = new SignalRef('Hello');
var sentence = computeTwo(refOne, refTwo, (a, b) => a * b);

print(sentence.value);
// => 'HelloHelloHello';
```

Also, here is a neat trick for computations.  Updates to computed values are defered to the
end of the current microtask queue, allowing us to ensure a maximum of a single update per
computed value.

```dart
var refOne = new SignalRef(2);
var refTwo = new SignalRef(3);
var refThree = new SignalRef(4);
var refFour = new SignalRef(5);
var changeCount = 0;

var computed = computeFour(
  refOne,
  refTwo,
  refThree,
  refFour,
  (a, b, c, d) => a + b + c + d,
);

computed.onChange((_) {
  changeCount++;
});

// microtasks are elapsed...

print(changeCount);
// => 1

refOne.value = 3;
refTwo.value = -1;
refThree.value = 9;
refFour.value = 10;

// microtasks are elapsed...

print(computed.value);
// => 21

print(changeCount);
// => 2
```

A Signal without an initial value or a value of null is marked as "cold", and will
not trigger updates in computations.  As a result, null cannot be used as a regular value inside of signals.

```dart
var refOne = new SignalRef();
var refTwo = new SignalRef(2);

var timesResult = computeTwo(refOne, refTwo, (a, b) => a * b);
print(timesResult.value);
// => null

refOne.value = 3;
print(timesResult.value);
// => 6

```

If a signal value is set to something which is equal to the previous value, then the signal does not trigger updates.

```dart
var calledCount = 0;
var refOne = new SignalRef(2);

refOne.onChange((_) {
  calledCount++;
});

refOne.value = 2;
refOne.value = 2;

print(calledCount);
// => 0;
```
