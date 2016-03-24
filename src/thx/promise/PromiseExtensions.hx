package thx.promise;

using thx.Arrays;

class PromiseExtensions {
  public static function traverse<A, B>(arr : Array<A>, f: A -> Promise<B>): Promise<Array<B>> {
    return Promise.allSequence(arr.map(f));
  }

  public static function parTraverse<A, B>(arr: Array<A>, f: A -> Promise<B>): Promise<Array<B>> {
    return Promise.all(arr.map(f));
  }
}
