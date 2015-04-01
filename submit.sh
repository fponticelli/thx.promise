#!/bin/sh
rm thx.promise.zip
zip -r thx.promise.zip hxml src test doc/ImportPromise.hx extraParams.hxml haxelib.json LICENSE README.md -x "*/\.*"
haxelib submit thx.promise.zip
