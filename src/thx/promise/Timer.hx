package thx.promise;

import thx.Nil;

class Timer {
  public static function delay(delayms : Int) : Future<Nil>
    return delayValue(nil, delayms);

  public static function delayValue<T>(value : T, delayms : Int) : Future<T>
    return Future.create(function(callback : T -> Void)
      thx.Timer.delay(callback.bind(value), delayms));

  public static function immediate() : Future<Nil>
    return immediateValue(nil);

  public static function immediateValue<T>(value : T) : Future<T>
    return Future.create(function(callback : T -> Void)
      thx.Timer.immediate(callback.bind(value)));
}