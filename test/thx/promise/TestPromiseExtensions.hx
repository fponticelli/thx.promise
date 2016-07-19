package thx.promise;

import haxe.ds.Option;
import thx.Either;
using thx.Eithers;
import thx.Nel;
using thx.Options;
import thx.Validation;
import thx.Validation.*;
import thx.Validation.VNel;
import thx.Validation.VNel.*;
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
    Promise.value((None : Option<String>))
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

  public function testEitherRecoverLeft_Right() {
    var done = Assert.createAsync();
    var promise : Promise<Either<Error, String>> = Promise.value(Right("hi"));
    promise.recoverLeft(function(l) return Promise.value("bye"))
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testEitherRecoverLeft_Left() {
    var done = Assert.createAsync();
    var promise : Promise<Either<Error, String>> = Promise.value(Left(new Error("hi")));
    promise.recoverLeft(function(l) return Promise.value("bye"))
      .success(function(value) { Assert.same("bye", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testEitherToPromise_Right() {
    var done = Assert.createAsync();
    var either : Either<Error, String> = Right("hi");
    either.toPromise()
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testEitherToPromise_Left() {
    var done = Assert.createAsync();
    var either : Either<String, String> = Left("failed");
    either.toPromise()
      .success(function(value) { Assert.fail(); done(); })
      .failure(function(e) { Assert.same("failed", e.message); done(); });
  }

  public function testVNelToPromise_Right() {
    var done = Assert.createAsync();
    var vnel : VNel<Error, String> = Right("hi");
    vnel.toPromise()
      .success(function(value) { Assert.same("hi", value); done(); })
      .failure(function(e) { Assert.fail(); done(); });
  }

  public function testVNelToPromise_Left() {
    var done = Assert.createAsync();
    var errors = Nel.fromArray([new Error("one"), new Error("two"), new Error("three")]).get();
    var vnel : VNel<Error, Int> = Left(errors);
    vnel.toPromise()
      .success(function(value) { Assert.fail(); done(); })
      .failure(function(e) { Assert.same("one, two, three", e.message); done(); });
  }

  public function testPromiseArrayFirst_Success() {
    var done = Assert.createAsync();
    Promise.value([1, 2, 3]).first().success(function(v) { Assert.same(1, v); done(); });
  }

  public function testPromiseArrayFirst_Failure() {
    var done = Assert.createAsync();
    Promise.value([]).first().failure(function(v) { Assert.pass(); done(); });
  }

  public function testPromiseArraySingle_Success() {
    var done = Assert.createAsync();
    Promise.value([1]).first().success(function(v) { Assert.same(1, v); done(); });
  }

  public function testPromiseArraySingle_Failure_Too_Many() {
    var done = Assert.createAsync();
    Promise.value([1, 2, 3]).single().failure(function(v) { Assert.pass(); done(); });
  }

  public function testPromiseArrayFirst_Failure_Empty() {
    var done = Assert.createAsync();
    Promise.value([]).single().failure(function(v) { Assert.pass(); done(); });
  }

  public function testPromiseArrayLast_Success() {
    var done = Assert.createAsync();
    Promise.value([1, 2, 3]).last().success(function(v) { Assert.same(3, v); done(); });
  }

  public function testPromiseArrayLast_Failure() {
    var done = Assert.createAsync();
    Promise.value([]).last().failure(function(v) { Assert.pass(); done(); });
  }
}
