require "./client"
require "./repl_tools"
require "pry"

begin
  client = KRPC::Client.new("my_ruby").connect!

  sc = client.space_center
  v = sc.active_vessel
  vrf = v.reference_frame
  c = v.control
  o = v.orbit
  f = v.flight
  
  binding.pry
  
ensure
  client.close unless client.nil?
end

