package thx.promise;

import thx.Functions.identity;
using thx.promise.PromiseExtensions;

class PromiseRExtensions {
  public static function liftR<R, A>(p: Promise<A>): PromiseR<R, A> {
    return (function(r: R) return p);
  }

  public static function join<R, A>(p: PromiseR<R,PromiseR<R, A>>): PromiseR<R, A> {
    return p.flatMap(identity);
  }
}

class PromiseRArrayExtensions {
  public static function traverse<R, A, B>(arr : Array<A>, f: A -> PromiseR<R, B>): PromiseR<R, Array<B>> {
    return PromiseR.ask().flatMap(
      function(r: R) return PromiseRExtensions.liftR(arr.traverse(function(a: A) return f(a).run(r)))
    );
  }
}
