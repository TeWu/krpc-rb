kRPC-rb [![Gem Version](https://badge.fury.io/rb/krpc.svg)](http://badge.fury.io/rb/krpc) [![Build Status](https://travis-ci.org/TeWu/krpc-rb.svg?branch=master)](https://travis-ci.org/TeWu/krpc-rb)
=======

kRPC-rb is a Ruby client library for [kRPC][krpc-github], a [Kerbal Space Program][ksp-home] mod that allows you to control KSP from external scripts running outside of the game.

![kRPC-rb image](http://tewu.github.io/krpc-rb/krpc-rb_top.png "This is kRPC-rb!")

Installation
-------

    gem install krpc

or install the latest pre-release version (if [available][rubygems-all-versions]): `gem install krpc --pre`

Basic usage
-------

```ruby
require 'krpc'
client = KRPC.connect(name: "client name here")
vessel = client.space_center.active_vessel
ctrl = vessel.control
ctrl.sas = true
ctrl.sas_mode = :stability_assist
ctrl.throttle = 1
puts "Launching #{vessel.name}!"
ctrl.activate_next_stage
client.close
```

Most of the API is *very* similar to what can be found in (official) Python client library.
So official documentation at http://krpc.github.io/krpc/ is definitely a good read.
The rest of this file describes few differences there are between Ruby and Python client libraries.

Connecting and disconnecting
-------
When you are in REPL, you can connect to kRPC server in this way:

```ruby
client = KRPC.connect(name: {name for the client}, host: {kRPC server host}, rpc_port: {kRPC server rpc port}, stream_port: {kRPC server stream port})
# use client here...
client.close
```

All of the `KRPC.connect`'s arguments are optional, so `client = KRPC.connect` might be enough for you.
Alternatively you can be more explicit (yet still obtain the same result):

```ruby
client = KRPC::Client.new( {The same argument list as KRPC.connect has} ).connect!
# use client here...
client.close
```

If you are writing a script, you can pass a block into `KRPC.connect`, `Client#connect` or `Client#connect!` methods. Connection to kRPC server is closed at the end of the block.

```ruby
KRPC.connect do |client|
# do something with client here...
end # closes connection
```

Data structures mapping
-------
kRPC server (and KSP itself) is written in C#. This means that during communication with the server there must be some data structure mapping being done. Most of the mappings are pretty obvious: numbers are mapped to `Float`s and `Integer`s, Strings to `String`s, Lists to `Array`s, Dictionaries to `Hash`es etc.

It may be less obvious that Enum values are mapped to `Symbol`s:

```ruby
client.space_center.active_vessel.situation # => :orbiting
client.space_center.active_vessel.control.sas_mode = :prograde
```

To see all values for enum, you can call method that expects enum argument or returns enum value with `_doc` suffix.
Alternatively you can print the hash that represents given enum:

```ruby
puts KRPC::Gen::SpaceCenter::SASMode # => {:stability_assist=>0, :maneuver=>1, :prograde=>2, :retrograde=>3, :normal=>4, :anti_normal=>5, :radial=>6, :anti_radial=>7, :target=>8, :anti_target=>9}
```

Tuples are mapped to `Array`s:

```ruby
client.space_center.active_vessel.flight.center_of_mass # => [-0.0015846538639403215, 0.0005474663704413168, 0.000849766220449432]
```

Get your fingers dirty
-------
The best way to explore the API is to run REPL and try what each method does for yourself.
I highly recommend using [Pry](https://github.com/pry/pry) as REPL. This way you can `ls` any object you receive and see what methods you can call on it. When you want to know more about specific method, then just stuck `_doc` at the end of it's name and press enter:

```ruby
[29] pry(main)> client.space_center.transform_position_doc
SpaceCenter.transform_position(
	position :Array[Float, Float, Float], - Position vector in reference frame from.
	from :ReferenceFrame, - The reference frame that the position vector is in.
	to :ReferenceFrame - The reference frame to covert the position vector to.
) :Array[Float, Float, Float] - The corresponding position vector in reference frame to.

 Converts a position vector from one reference frame to another.
=> nil
```

I recommend ending the line with `;` to suppress printing return value (the `=> nil` line at the end).
If you want doc for method whose name ends with a `=` sign, you can put `_doc` before the `=`. Alternatively use `Object#send`, like in: `client.space_center.send "active_vessel=_doc"`.

Combination of `ls`s and `_doc`s should teach you API in no time (also don't be surprised if you have a lot of fun with it too :))

![kRPC-rb in-REPL documentation example](http://tewu.github.io/krpc-rb/krpc-rb_inREPL_doc.png "kRPC-rb in-REPL documentation example")

Streaming
-------
A stream repeatedly executes a function on the server, with a fixed set of argument values. It provides a more efficient way of repeatedly getting the result of calling function on the server, without having to invoke it directly – which incurs communication overheads.

To create a stream, call a method with `_stream` suffix. This will return `KRPC::Streaming::Stream` instance. You can call `get` (or `value`) on the `Stream` instance to get the recent value received by this stream. To deactivate the stream call `remove` (or `close`) on the `Stream` instance.

Example without streaming:
```ruby
vessel = client.space_center.active_vessel
refframe = vessel.orbit.body.reference_frame
loop do
  puts vessel.position(refframe)
end
```
Equivalent example with streaming:
```ruby
vessel = client.space_center.active_vessel
refframe = vessel.orbit.body.reference_frame
pos_stream = vessel.position_stream(refframe)
loop do
  puts pos_stream.get
end
pos_stream.remove #note: dead code - just as an example
```

Want to know more?
-------
* Read official **kRPC documentation** at https://krpc.github.io/krpc, with many great [tutorials and examples](https://krpc.github.io/krpc/tutorials.html).
* Refer to **kRPC-rb API documentation** at https://tewu.github.io/krpc-rb-apidocs
* See official **[kRPC forum thread][krpc-forum]**
* @nateberkopec [gave a talk at RubyConf 2017](https://www.youtube.com/watch?v=VMxct9B5S1A) about the guidance and architecture used in the Saturn V and the Apollo Guidance Computer using `krpc-rb` to illustrate.


[krpc-github]: https://github.com/krpc/krpc
[krpc-forum]: https://forum.kerbalspaceprogram.com/index.php?/topic/130742-15x-to-122-krpc-control-the-game-using-c-c-java-lua-python-ruby-haskell-c-arduino-v048-28th-october-2018/
[ksp-home]: https://kerbalspaceprogram.com/
[rubygems-all-versions]: https://rubygems.org/gems/krpc/versions
