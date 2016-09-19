package thx.promise;

import thx.Error;
import utest.Assert;
using thx.Arrays;
using thx.Tuple;

class TestPromiseR {
  public function new() {}

  public function testFlatMap() {
    var done = Assert.createAsync();
    var action: PromiseR<Int, Int> = PromiseR.pure(2).flatMap(
      function(v) return PromiseR.ask().flatMap(
        function(r) return PromiseR.pure(r * v * 2)
      )
    );
      
    action.run(2).success(function(v) {
      Assert.equals(8, v);
      done();
    });
  }
}

