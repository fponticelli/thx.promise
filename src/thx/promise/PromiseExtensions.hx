package thx.promise;

import haxe.ds.Option;
using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Error;
using thx.Options;

class PromiseOptionExtensions {
/**
Converts an `Option<T>` into a `Promise<T>`.  `Some(value)` will result in a resolved promise of `value`,
and `None` will result in a rejected promise with the given (optional) `errormessage`.
**/
  public static function toPromise<T>(option : Option<T>, error: Error) : Promise<T> {
    return option.cata(Promise.error(error), Promise.value);
  }

/**
Mapping function for `Promise<Option<T>>` that allows you to intercept and handle a resolved value of `None` by
returning a new value of type `T`.

Similar to `Promise` `mapNull`

If you need to convert `None` into an error rather than a new value of `T`, use `flatMapNone` or `mapNoneToError` instead.
**/
  public static function mapNone<T>(promise : Promise<Option<T>>, f : Void -> T) : Promise<T> {
    return recoverNone(promise, function() {
      return Promise.value(f());
    });
  }

/**
Map function for `Promise<Option<T>>` that converts a resolved value of `None` into a resolved `Promise<T>`
of the given `value`.
**/
  public static function mapNoneToValue<T>(promise : Promise<Option<T>>, value : T) : Promise<T> {
    return recoverNone(promise, function() {
      return Promise.value(value);
    });
  }

/**
Map function for `Promise<Option<T>>` that converts a resolved value of `None` into a rejected `Promise<T>`
of the given `Error`.
**/
  public static function mapNoneToError<T>(promise : Promise<Option<T>>, error : Error) : Promise<T> {
    return recoverNone(promise, function() {
      return Promise.error(error);
    });
  }

/**
Mapping function for `Promise<Option<T>>` that allows you to intercept and handle a resolved value of `None` by
returning a new `Promise<T>` (success or failure).
**/
  public static function recoverNone<T>(promise : Promise<Option<T>>, f : Void -> Promise<T>) : Promise<T> {
    return promise.flatMap(function(opt : Option<T>) {
      return switch opt {
        case Some(value) if (value != null) : Promise.value(value);
        case _ : f();
      };
    });
  }

}

class PromiseArrayExtensions {
  public static function traverse<A, B>(arr : Array<A>, f: A -> Promise<B>): Promise<Array<B>> {
    return Promise.sequence(arr.map(f));
  }
}
