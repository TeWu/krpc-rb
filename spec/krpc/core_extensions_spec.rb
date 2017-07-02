require "krpc"

RSpec.describe "core extensions" do

  describe Module do
    it "returns simple class name" do
      expect(Boolean.class_name).to eq "Boolean"
      expect(KRPC::Services::ServiceBase.class_name).to eq "ServiceBase"
    end
  end

  describe String do
    it "converts to snake_case" do
      # Simple cases
      expect("server".underscore).to eq "server"
      expect("Server".underscore).to eq "server"
      expect("MyServer".underscore).to eq "my_server"
      expect("My Server".underscore).to eq "my server"

      # With numbers
      expect("Int32ToString".underscore).to eq "int32_to_string"
      expect("32ToString".underscore).to eq "32_to_string"
      expect("ToInt32".underscore).to eq "to_int32"

      # With multiple capitals
      expect("HTTPS".underscore).to eq "https"
      expect("HTTPServer".underscore).to eq "http_server"
      expect("MyHTTPServer".underscore).to eq "my_http_server"
      expect("HTTPServerSSL".underscore).to eq "http_server_ssl"

      # With underscores
      expect("_HTTPServer".underscore).to eq "_http_server"
      expect("HTTP_Server".underscore).to eq "http_server"

      # With non camel case examples
      expect("foo_bar".underscore).to eq "foo_bar"
      expect("_foobar".underscore).to eq "_foobar"
      expect("_foo_bar".underscore).to eq "_foo_bar"
    end
  end

  describe Array do
    context "last element is a hash" do
      it "extracts nonempty kwargs" do
        arry = [1, 2.0, "three", {one: 1, nine: "9"}]
        result = arry.extract_kwargs!
        expect(result).to eq ({one: 1, nine: "9"})
        expect(arry).to eq [1, 2.0, "three"]
      end
    end

    context "last element is not a hash" do
      it "extracts empty kwargs" do
        arry = [1, 2.0, "three"]
        result = arry.extract_kwargs!
        expect(result).to eq ({})
        expect(arry).to eq [1, 2.0, "three"]
      end
    end
  end

end

