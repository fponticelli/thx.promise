# thx.promise

[![Build Status](https://travis-ci.org/fponticelli/thx.promise.svg)](https://travis-ci.org/fponticelli/thx.promise)

Simple reinterpretation of the Promise pattern for Haxe.

Note: The documentation needs to be updated to fit in the new implementation that uses [Future](http://thx-lib.org/api/thx/promise/Future.html) as the basic implementation.

## Introduction

thx.promise doesn't follow the [Promise/A+](https://promisesaplus.com/) specification or any other specification. The libraries simply tries to leverage the Haxe typing system without enforcing any type of obscure magic.

Promises always deal with just one value. If you need multiple values, you can use a [Tuple](http://thx-lib.org/api/thx/core/Tuple2.html) and if you don't need any value use [Nil](http://thx-lib.org/api/thx/core/Nil.html). This approach allows for a very simple API and implementation.
mark
A Promise is a representation of a value that will be available some time in the future. The value can be either any type in case of success or an instance of [Error](http://thx-lib.org/api/thx/core/Error.html) in case of failure. Notice that the Error case can only occur if the Promise has been explicitely rejected. Any error occurring in the promise handlers will not be automatically captured and will propagate normally.

A simple promise look something like this:

```haxe
var promise = Promise.create(function(resolve : String -> Void, reject : Error -> Void) {
    thx.core.Timer.delay(function() {
        if(Math.random() < 0.5)
            resolve("success");
        else
            reject(new Error("failure"));
    }, 100);
});
```

This promise resolve randomly to a success/failure 50% of the times.

Usage looks like:

```haxe
promise.success(function(value) trace('SUCCESS $value'));
```

In this case we decided to only deal with the success cases and to ignore all the rejected values. We can deal with those by doing:

```haxe
promise.failure(function(error) trace('ERROR $error'));
```

or

```haxe
promise.either(
    function(value) trace('SUCCESS $value'),
    function(error) trace('ERROR $error')
);
```

All these methods are convenience methods that use `.then()` internally. `.then()` method deals with [`PromiseValue<T>`](http://thx-lib.org/api/thx/promise/PromiseValue.html) directly.

All of the above methods return the same Promise instance to enable easy chaining. Notice that handlers are executed in the sequence they have been registered and an uncaught exception in one of the handlers will provoke a termination in the chain.

```haxe
promise.success(function(value) { /* ... */ })
    .success(function(value) { /* ... */ })
    .failure(function(error) { /* ... */ });
```

All of the above are handling the same Promise/Value pair.

## Values

If you already have a value (or an error) you can instantly fulfill a Promise by doing:

```haxe
Promise.value("some value");
Promise.error(new Error("It's not my fault"));
```

They both return a resolved instance of Promise.

## Transform/Map

It seems pretty obvious that a Promise should be easy to transform/map. To that effect you have `map` and the `map*` derivative methods. A `map` method must return a new Promise instance.

```haxe
Promise.value(3)
    // mapping to a new Promise with same type
    .mapSuccess(function(v) return Promise.value(v * 2))
    // mapping to a new Promise with a different type
    .mapSuccess(function(v) return Promise.value(StringTools.rpad('', 'x', v)))
    .success(function(s) trace(s)); // echoes 'xxxxxx'
```

In case of failure, `mapSuccess` will skip the success handler and push the failure down to the output Promise.

`mapFailure` is useful to be able to recover from an error. Let's suppose that if an error occurred I still want to be able to perform the promise handler with a default value:

```haxe
var promise : Promise<Int> = ...; // an integer generator of some sort

// in case of error I still want to return a promise that holds 0

promise = promise.mapFailure(function(err) return 0);
```

This promise will always succeed and return an integer result.

To complete the scenario you can also use `mapEither` that provides a way to map either the success or the failure with two independent handlers.

`map` works as the above except that deals directly with `PromiseValue`.

## Always

Sometimes you just want to be notified when a promise has been fulfilled regardless of the value itself. In this case you can use `always()` (terminal computation like `success`/`failure`) or `mapAlways()` (map method like `mapSuccess/mapFailure`). Obviously the handlers of these functions will take no arguments because we don't care about the value of the promise.

## More

Promise also provide the following methods for completeness: `isResolved()`, `isFailure()` and `isComplete()`. They all return a `Bool` value and their behavior seems pretty obvious.

## Vitamins

Extensions methods are available in the `thx.core.Promise` module. Using `using` you can access those directly as instance members of Promise.

### `log()`

Utility function to send the value of a Promise to `trace()`.

### `delay()`

Returns a new Promise that passes through the value of the original promise but with a time delay. If time is not specified, the delay will be the shortest allowed by the platform (for JavaScript developers that might be equivalent to 'setImmediate').

```haxe
var promise = Promise.value(7).delay(50);
```

The promise holds the value 7 but its availability is delayed by `50ms`.

### `join()`

Joins together two promises and returns a new Promise holding both values as members of a Tuple. You can easily 'unpack' the members of a Promise<TupleX> by using `tuple()`/`mapTuple()`.

```haxe
Promise.value(7)
    .join(Promise.value("test"))
    .success(function(tuple) {
        trace('${tuple._0} ${tuple._1}')
    });
```

Even more simple with the `tuple()` extension method:

```haxe
Promise.value(7)
    .join(Promise.value("test"))
    .join(Promise.value(true))
    .tuple(function(number : Int, text : String, flag : Bool) {
        // do something here
    });
```

To be clear the Promises joined together will run concurrently and the Promise<TupleX> result will be available as soon as all the Promises involved have been resolved.

## Install

From the command line just type:

```bash
haxelib install thx.promise
```

To use the `dev` version do:

```bash
haxelib git thx.promise https://github.com/fponticelli/thx.promise.git
```
