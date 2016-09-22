package thx.promise;

import haxe.ds.Option;
using thx.Arrays;
import thx.Either;
using thx.Eithers;
import thx.Error;
using thx.Functions;
import thx.Nel;
using thx.Options;
import thx.Validation;
import thx.Validation.*;
import thx.Validation.VNel;
import thx.Validation.VNel.*;

class PromiseOptionExtensions {
/**
Converts an `Option<T>` into a `Promise<T>`.  `Some(value)` will result in a resolved promise of `value`,
and `None` will result in a rejected promise with the given (optional) `errormessage`.
**/
  public static function toPromise<T>(option : Option<T>, error: Error) : Promise<T> {
    return option.cata(Promise.error(error), Promise.value);
  }

/**
Mapping function for `Promise<Option<T>>` that allows the caller to intercept and handle a resolved value of `None` by
returning a new value of type `T`.

Similar to `Promise` `mapNull`

If the caller needs to convert `None` into an error rather than a new value of `T`, use `mapNoneToError` or `recoverNone` instead.
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
Mapping function for `Promise<Option<T>>` that allows the caller to intercept and handle a resolved value of `None` by
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

class PromiseEitherExtensions {
/**
Converts an `Either<E, T>` to a `Promise<T>`, where the `Left` side is considered the error state,
and is converted to a `thx.Error` using the `leftToError` function provided by the caller.
**/
  public static function toPromise<E, T>(either : Either<E, T>, leftToError : E -> Error) : Promise<T> {
    return either.cata(Promise.error.compose(leftToError), Promise.value);
  }

/**
Mapping function for `Promise<Either<E, T>>` that allows the caller to recover from a `Left` value in
the resolved promise, to return a new `Promise<T>`.
**/
  public static function recoverLeft<E, T>(promise : Promise<Either<E, T>>, f : E -> Promise<T>) : Promise<T> {
    return promise.flatMap(function(either : Either<E, T>) {
      return switch either {
        case Left(l) : f(l);
        case Right(r) : Promise.value(r);
      };
    });
  }
}

class PromiseEitherErrorOrValueExtensions {
/**
Converts an `Either<Error, T>` to a `Promise<T>`, where the `Left` side is considered the error state.
**/
  public static function toPromise<T>(either : Either<Error, T>) : Promise<T> {
    return PromiseEitherExtensions.toPromise(either, Functions.identity);
  }
}

class PromiseEitherStringOrValueExtensions {
/**
Converts an `Either<String, T>` to a `Promise<T>`, where the `Left` side is considered the error state,
and is converted to a `thx.Error` using `new Error(str)`.
**/
  public static function toPromise<T>(either : Either<String, T>) : Promise<T> {
    return PromiseEitherExtensions.toPromise(either, function(str) return new Error(str));
  }
}

class PromiseVNelExtensions {
/**
Converts a `VNel<E, T>` to a `Promise<T>`.  If the `VNel` is `Left`, the left items are combined using the given
`leftSemigroup`, and the combined value is converted to a `thx.Error` using `leftToError`.
**/
  public static function toPromise<E, T>(vnel : VNel<E, T>, leftSemigroup : Semigroup<E>, leftToError : E -> Error) : Promise<T> {
    return vnel.either.cata(function(errors : Nel<E>) : Promise<T> {
      return Promise.error(leftToError(errors.fold(leftSemigroup)));
    }, Promise.value);
  }
}

class PromiseVNelErrorOrValueExtensions {
/**
Converts a `VNel<Error, T>` to a `Promise<T>`.  If the `VNel` is `Left`, the left `Error`s are combined using
a semigroup that joins the error messages with ", ", and converted into a new `thx.Error` with the combined error messages.

Stack traces for individual errors are not preserved.
**/
  public static function toPromise<T>(vnel : VNel<Error, T>) : Promise<T> {
    return PromiseVNelExtensions.toPromise(vnel, function(e1, e2) {
      return new Error([e1.message, e2.message].join(", "));
    }, Functions.identity);
  }
}

class PromiseVNelStringOrValueExtensions {
/**
Converts a `VNel<String, T>` to a `Promise<T>`.  If the `VNel` is `Left`, the left `String`s are combined using
a semigroup that joins them with ", ", and converted into a new `thx.Error` with the combined error messages.
**/
  public static function toPromise<T>(vnel : VNel<String, T>) : Promise<T> {
    return PromiseVNelExtensions.toPromise(vnel, function(s1, s2) {
      return [s1, s2].join(", ");
    }, function(str) return new Error(str));
  }
}

class PromiseArrayExtensions {
  public static function traverse<A, B>(arr : ReadonlyArray<A>, f: A -> Promise<B>): Promise<Array<B>> {
    return Promise.sequence(arr.map(f));
  }

  public static function first<T>(promise : Promise<Array<T>>) : Promise<T> {
    return promise.flatMap(function(values: Array<T>) : Promise<T> {
      return if (values == null) {
        Promise.error(new Error('Resolved Array was null - unable to get first value'));
      } else if (values.length == 0) {
        Promise.error(new Error('Resolved Array was empty - unable to get first value'));
      } else {
        Promise.value(values[0]);
      };
    });
  }

  public static function single<T>(promise : Promise<Array<T>>) : Promise<T> {
    return promise.flatMap(function(values: Array<T>) : Promise<T> {
      return if (values == null) {
        Promise.error(new Error('Resolved Array was null - unable to get single value'));
      } else if (values.length != 1) {
        Promise.error(new Error('Resolved Array did not contain exactly one item - unable to get single value'));
      } else {
        Promise.value(values[0]);
      };
    });
  }

  public static function last<T>(promise : Promise<Array<T>>) : Promise<T> {
    return promise.flatMap(function(values: Array<T>) : Promise<T> {
      return if (values == null) {
        Promise.error(new Error('Resolved Array was null - unable to get last value'));
      } else if (values.length == 0) {
        Promise.error(new Error('Resolved Array was empty - unable to get last value'));
      } else {
        Promise.value(Arrays.last(values));
      };
    });
  }
}
