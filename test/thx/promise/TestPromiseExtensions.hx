package thx.promise;

import haxe.ds.Option;
using thx.Options;
import utest.Assert;
using thx.promise.PromiseExtensions;

class TestPromiseExtensions {
  public function new() {}

  public function testToOptionSuccess() {
    var done = Assert.createAsync();
    Promise.value("hi").toOption()
      .success(function(value) {
        switch value {
          case Some(val) : Assert.same("hi", val); done();
          case None : Assert.fail(); done();
        }
      })
      .failure(function(e) {
        Assert.fail(); done();
      });
  }

  public function testToOptionFailure() {
    var done = Assert.createAsync();
    Promise.error(new Error("failed")).toOption()
      .success(function(value) {
        switch value {
          case Some(val) : Assert.fail(); done();
          case None : Assert.pass(); done();
        }
      })
      .failure(function(e) {
        Assert.fail(); done();
      });
  }

  public function testToPromiseSuccess() {
    var done = Assert.createAsync();
    Some("hi").toPromise()
      .success(function(value) {
        Assert.same("hi", value); done();
      })
      .failure(function(e) {
        Assert.fail(); done();
      });
  }

  public function testToPromiseFailure() {
    var done = Assert.createAsync();
    None.toPromise("this thing failed")
      .success(function(value) {
        Assert.fail(); done();
      })
      .failure(function(e) {
        Assert.same("this thing failed", e.message); done();
      });
  }
}
