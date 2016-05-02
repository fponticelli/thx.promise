package thx.promise;

using thx.Arrays;

class PromiseArrayExtensions {
  public static function traverse<A, B>(arr : Array<A>, f: A -> Promise<B>): Promise<Array<B>> {
    return Promise.sequence(arr.map(f));
  }
}
