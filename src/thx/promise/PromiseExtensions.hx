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
}

class PromiseArrayExtensions {
  public static function traverse<A, B>(arr : Array<A>, f: A -> Promise<B>): Promise<Array<B>> {
    return Promise.sequence(arr.map(f));
  }
}
