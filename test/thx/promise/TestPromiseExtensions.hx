package thx.promise;

import haxe.ds.Option;
using thx.Options;
import utest.Assert;
using thx.promise.PromiseExtensions;

class TestPromiseExtensions {
  public function new() {}

  public function testOptionToPromise_Success() {
    var done = Assert.createAsync();
    Some("hi").toPromise(new Error("no value"))
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testOptionToPromise_Failure() {
    var done = Assert.createAsync();
    None.toPromise(new Error("this thing failed"))
      .success(function(value) { Assert.fail(); done(); })
      .failure(function(e) { Assert.same("this thing failed", e.message); done(); });
  }

  public function testPromiseOption_MapNone_Some() {
    var done = Assert.createAsync();
    Promise.value(Some("hi"))
      .mapNone(function() { return "bye"; })
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testPromiseOption_MapNone_NoneToValue() {
    var done = Assert.createAsync();
    Promise.value(None)
      .mapNone(function() { return "bye"; })
      .success(function(value) { Assert.same("bye", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testPromiseOption_MapNone_NoneToException() {
    var done = Assert.createAsync();
    Promise.value(None)
      .mapNone(function() { throw new Error("failed"); })
      .success(function(value) { Assert.fail(); done(); })
      .failure(function(e) { Assert.same("failed", e.message); done(); });
  }

  public function testPromiseOption_MapNoneToValue_Some() {
    var done = Assert.createAsync();
    Promise.value(Some("hi"))
      .mapNoneToValue("bye")
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testPromiseOption_MapNoneToValue_None() {
    var done = Assert.createAsync();
    Promise.value(None)
      .mapNoneToValue("bye")
      .success(function(value) { Assert.same("bye", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testPromiseOption_MapNoneToError_Some() {
    var done = Assert.createAsync();
    Promise.value(Some("hi"))
      .mapNoneToError(new Error("failed"))
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testPromiseOption_MapNoneToError_None() {
    var done = Assert.createAsync();
    Promise.value(None)
      .mapNoneToError(new Error("failed"))
      .success(function(value) { Assert.fail(); done(); })
      .failure(function(e) { Assert.same("failed", e.message); done(); });
  }

  public function testPromiseOption_RecoverNone_Some() {
    var done = Assert.createAsync();
    Promise.value(Some("hi"))
      .recoverNone(function() { return Promise.value("bye"); })
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testPromiseOption_RecoverNone_NoneToResolved() {
    var done = Assert.createAsync();
    Promise.value(None)
      .recoverNone(function() { return Promise.value("bye"); })
      .success(function(value) { Assert.same("bye", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testPromiseOption_RecoverNone_NoneToRejected() {
    var done = Assert.createAsync();
    Promise.value(None)
      .recoverNone(function() { return Promise.error(new Error("dead")); })
      .success(function(value) { Assert.fail(); done(); })
      .failure(function(e) { Assert.same("dead", e.message); done(); });
  }

  public function testPromiseOption_RecoverNone_NoneToException() {
    var done = Assert.createAsync();
    Promise.value(None)
      .recoverNone(function() { throw new Error("dead"); })
      .success(function(value) { Assert.fail(); done(); })
      .failure(function(e) { Assert.same("dead", e.message); done(); });
  }
}
