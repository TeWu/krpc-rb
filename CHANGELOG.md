
v0.2.2  (30 Oct 2015)
========
+ Static methods now require `KRPC::Client` instance as first argument (Fix #4)
+ Improved parameters default value handling
+ Improved collections encoding
+ Fixed few minor bugs

v0.2.0  (26 Sep 2015)
========
+ **Added Streaming support**:
  + Stream creation by calling method with `_stream` suffix
+ **Improved in-REPL experience**:
  + Added documentation content received from kRPC server to in-REPL documentation output
  + Improved `to_s` and `inspect` methods in `KRPC::Gen::ClassBase` and `KRPC::Streaming::Stream` classes
+ Arguments of `KRPC::Client#initialize` method turned into keyword arguments
+ RPC methods are no longer bound to single `KRPC::Client` object (Fix #3)
+ Fixed arguments sometimes not correctly passed to RPC methods (due to Ruby 2.2.1 bug) (Fix #1)
+ Removed `required_params_count` parameter from `Client#build_request` method, and made that method public
+ `KRPC::TypeStore`'s methods changed, to be class level methods
+ Added dependency on *Nokogiri* and development dependency on *Pry* and *hanna-nouveau*
+ Minor improvements and fixes

v0.1.1  (9 Sep 2015)
========
+ Added `KRPC.connect` method
+ Added block argument to `Client#connect` and `Client#connect!` methods

v0.1.0  (6 Sep 2015)
========
+ Initial release

