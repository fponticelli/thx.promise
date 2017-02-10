package thx.promise;

using thx.promise.Deferred;
using thx.promise.Promise;
import thx.Error;
import utest.Assert;

class TestDeferred {
  public function new() {}

  public function testCreateDeferred() {
    var done = Assert.createAsync();
    var def = new Deferred();

    Assert.same(true, def.promise.isPending());


    def.promise.success(function (res) {
      Assert.equals(1, res);
    })
    .failure(function (e) {
      Assert.fail(e.message);
    }).always(done);

    def.resolve(1);
  }

  public function testFailureDeferred() {
    var done = Assert.createAsync();
    var def = new Deferred();

    Assert.same(true, def.promise.isPending());

    def.promise.success(function (res) {
      Assert.fail("Expected failure deferred");
    })
    .failure(function (e) {
      Assert.same("Failure", e.message);
    }).always(done);

    def.reject(new thx.Error("Failure"));
  }
}
