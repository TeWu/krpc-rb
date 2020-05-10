v0.4.1  (10 May 2020)
========
+ Add rate control for streams
+ Test against kRPC TestServer 0.4.7

v0.4.0  (24 Oct 2017)
========
+ **Updated to make kRPC-rb compatible with kRPC server version 0.4.0**:
  + **Updated communication protocol in line with server changes** (for details see [krpc #325](https://github.com/krpc/krpc/pull/325))
  + Updated `RPCError` handling logic, to properly handle `Error` protobuf message
  + Updated `core` service
+ Added `KRPC::Version` module, to support more granular version checks
+ Improved `Encoder` - strings are now transcoded to UTF-8 before being encoded as value of protobuf message field. This allows non-UTF-8 encoded strings to be passed to RPC methods, e.g.:

```ruby
client.space_center.active_vessel.name = "µ-craft".encode('ISO-8859-1')
```

+ Improved reliability - added many new specs and refactored existing ones for better maintainability and performance
+ Many minor bug fixes, refactorings and performance improvements
+ *See also changes introduced in v0.3.2, which were backported from v0.4.0.beta3*

v0.3.2  (3 Aug 2017)
========
+ Changes introduced in this version are backported form v0.4.0.beta3
+ **Changes to `krpc` and `core` services**:
  + Renamed hardcoded `krpc` service to `core`
  + Allowed `krpc` service to be dynamically generated during services API generation
  + Updated `core` service
+ Started testing against Ruby v2.3 and Ruby v2.4
+ Turned runtime dependency on *hanna-nouveau* into development dependency
+ Cleaned up Git repository - moved generated HTML API docs, and TestServer binaries out of the repository

v0.3.1  (18 Jun 2016)
========
+ Fixed receiving of chunked responses
+ Updated protocol buffers schema

v0.3.0  (15 Feb 2016)
========
+ **Updated to work with kRPC server version 0.2.x** (#6):
  + Using *google-protobuf* gem instead of *ruby_protobuf*, for protocol buffers version 3
+ Turned development dependency on *hanna-nouveau* into runtime dependency (Fix #5)

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

