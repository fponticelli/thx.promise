package thx.promise;

import haxe.ds.Option;
using thx.Arrays;
import thx.Either;
using thx.Eithers;
using thx.Options;

class PromiseOptionExtensions {
/**
Converts an `Option<T>` into a `Promise<T>`.  `Some(value)` will result in a resolved promise of `value`,
and `None` will result in a rejected promise with the given (optional) `errormessage`.
**/
  public static function toPromise<T>(option : Option<T>, ?errorMessage : String = "Optional value was None") : Promise<T> {
    return option.cata(Promise.error(new Error(errorMessage)), Promise.value);
  }

/**
Converts a `Promise<T>` to a `Promise<Option<T>>`.  If the input promise is resolved with `value`, the result `Promise`
will contain `Some(value)`.  If the input promise is rejected, the result `Promise` is not rejected, but instead resolved
with a value of `None`.

The result promise should never be rejected - just resolved with `Option<T>`.
**/
  public static function toOption<T>(promise : Promise<T>) : Promise<Option<T>> {
    return promise.map(Some).recover(function(_) {
      return Promise.value(None);
    });
  }
}

class PromiseArrayExtensions {
  public static function traverse<A, B>(arr : Array<A>, f: A -> Promise<B>): Promise<Array<B>> {
    return Promise.sequence(arr.map(f));
  }
}
