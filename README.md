kRPC-rb [![Gem Version](https://badge.fury.io/rb/krpc.svg)](http://badge.fury.io/rb/krpc)
=======

kRPC-rb is a Ruby client library for [kRPC](http://forum.kerbalspaceprogram.com/threads/69313), a Kerbal Space Program mod that allows you to control KSP from external scripts running outside of the game.

Installation
-------

    gem install krpc

Basic usage
-------

```ruby
require 'krpc'
client = KRPC.connect("client name here")
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
So official documentation at http://djungelorm.github.io/krpc/docs/ is definitely a good read.
The rest of this file describes few differences there are between Ruby and Python client libraries.

**NOTE:** Streaming is not supported in the current version of kRPC-rb.

Connecting and disconnecting
-------
When you are in REPL, you can connect to kRPC server in this way:

```ruby
client = KRPC.connect({name for client}, {host}, {rpc_port}, {stream_port})
# use client here...
client.close
```

All of the `KRPC.connect`'s arguments are optional, so `client = KRPC.connect` might be enough for you.
Alternatively you can be more explicit (yet still obtain the same result):

```ruby
client = KRPC::Client.new({name for client}, {host}, {rpc_port}, {stream_port}).connect!
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
[29] pry(main)> cl.space_center.transform_position_doc
SpaceCenter.transform_position(
	position :Array[Float, Float, Float],
	from :ReferenceFrame,
	to :ReferenceFrame
) :Array[Float, Float, Float]
=> nil
```

I recommend ending the line with `;` to suppress printing return value (the `=> nil` line at the end).
If you want doc for method whose name ends with a `=` sign, you can put `_doc` before the `=`. Alternatively use `Object#send`, like in: `client.space_center.send "active_vessel=_doc"`.

Combination of `ls`s and `_doc`s should teach you API in no time (also don't be surprised if you'll have a lot of fun with it too :))

```ruby
[31] pry(main)> sc = client.space_center;
[32] pry(main)> ls sc
KRPC::Doc::SuffixMethods#methods: method_missing
KRPC::Services::ServiceBase#methods: client
KRPC::Services::SpaceCenter::AvailableToClassAndInstance#methods: 
  can_rails_warp_at  clear_target    draw_line               launch_vessel_from_vab  transform_position  transform_velocity
  clear_drawing      draw_direction  launch_vessel_from_sph  transform_direction     transform_rotation  warp_to           
KRPC::Services::SpaceCenter#methods: 
  active_vessel   far_available              physics_warp_factor   rails_warp_factor=     target_body=          target_vessel   vessels      warp_rate
  active_vessel=  g                          physics_warp_factor=  remote_tech_available  target_docking_port   target_vessel=  warp_factor
  bodies          maximum_rails_warp_factor  rails_warp_factor     target_body            target_docking_port=  ut              warp_mode  
instance variables: @client
[33] pry(main)> sc.warp_to_doc;
SpaceCenter.warp_to(
	ut :Float,
	max_rails_rate :Float = 100000.0,
	max_physics_rate :Float = 2.0
) :nil
```

Want to know more?
-------
* Read official **kRPC documentation** at http://djungelorm.github.io/krpc/docs, with many great [tutorials and examples](http://djungelorm.github.io/krpc/docs/tutorials.html).
* Refer to **kRPC-rb documentation** at http://tewu.github.io/krpc-rb/doc
* See official **kRPC forum thread** at http://forum.kerbalspaceprogram.com/threads/69313

