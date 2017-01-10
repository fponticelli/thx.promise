package thx.promise;

import utest.Assert;

import thx.Either;
using thx.promise.PromiseRFExtensions;

class TestPromiseRFExtensions {
  public function new() {}

  public function testTraverse() {
    var done = Assert.createAsync();
    [1, 1, 1].traverse(
      function(i: Int) return {
        PromiseRF.ask().map(function(j: Int) return i + j);
      }
    ).run(2).success(
      function(xs) {
        Assert.same(Right([3, 3, 3]), xs);
        done();
      }
    );
  }
}

