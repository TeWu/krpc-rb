require 'krpc'


shared_context "test server support" do
  before :all do
    @test_server = {rpc_port: 50011, stream_port: 50012, }
    @test_server[:io] = IO.popen("bin/TestServer/TestServer.exe --rpc-port #{@test_server[:rpc_port]} --stream-port #{@test_server[:stream_port]}")
    until @test_server[:io].readline.include? "[kRPC] [Info] TCPServer(StreamServer): started successfully" do
    end
    @test_server[:pid] = @test_server[:io].pid
  end

  after :all do
    Process.kill("INT", @test_server[:pid])
  end
end

shared_context "test client support" do
  include_context "test server support"

  before :each do
    @test_client = connect
    @test_service = @test_client.test_service
  end

  after :each do
    @test_service = nil
    @test_client.close
  end

  def connect
    KRPC.connect(name: "TestClient", host: "localhost", rpc_port: @test_server[:rpc_port], stream_port: @test_server[:stream_port])
  end
end
