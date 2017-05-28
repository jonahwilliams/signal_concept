// Copyright (c) 2017, Jonah Williams. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:property/property.dart';

main() {
  var greeting = new PropertyRef("Hello");
  var timesToRepeat = new PropertyRef(2);
  var separator = new Property.Constant(' ');
  var sentence = computeThree(
      greeting, separator, timesToRepeat, (a, c, b) => (a + c) * b);
  print(sentence);

  greeting.value = "Goodbye";
  timesToRepeat.value = 10;

  print(sentence);
}
