package thx.promise;

import thx.core.Error;

enum PromiseValue<T> {
  Success(value : T);
  Failure(err : Error);
}