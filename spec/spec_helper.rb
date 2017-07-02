require_relative 'config'
require 'krpc'

PB = KRPC::PB

RSpec.shared_context "test server support" do
  before :context do
    ensure_test_server_downloaded
    @test_server = { rpc_port: 50011, stream_port: 50012 }
    @test_server[:io] = IO.popen("bin/TestServer/TestServer.exe --rpc-port #{@test_server[:rpc_port]} --stream-port #{@test_server[:stream_port]}")
    until @test_server[:io].readline.include? "Server started successfully" do
    end
    @test_server[:pid] = @test_server[:io].pid
  end

  after :context do
    Process.kill("INT", @test_server[:pid])
  end

  def ensure_test_server_downloaded
    fail "Error downloading test server" unless system "bin/download_test_sever.sh --quiet-if-exists"
  end
end

RSpec.shared_context "test client support" do
  include_context "test server support"

  before :example do
    @test_client = connect
    @test_service = @test_client.test_service
  end

  after :example do
    @test_service = nil
    @test_client.close
  end

  def connect
    KRPC.connect(name: "TestClient", host: "localhost", rpc_port: @test_server[:rpc_port], stream_port: @test_server[:stream_port])
  end
end