package thx.promise;

import thx.core.Error;

enum PromiseValue<T> {
  Failure(err : Error);
  Success(value : T);
}