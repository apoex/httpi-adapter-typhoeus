require "spec_helper"
require "httpi/adapter/typhoeus"
require "httpi/request"

HTTPI::Adapter.load_adapter(:typhoeus)

RSpec.describe HTTPI::Adapter::Typhoeus do
  let(:adapter) { described_class.new(httpi) }
  let(:httpi) { HTTPI::Request.new("http://example.com") }
  let(:body) { "foo bar" }

  before do
    stub_request(:any, "example.com").to_return(
      body: body,
      headers: {
        "Accept-encoding" => "utf-8"
      }
    )
  end

  describe "#request(:get)" do
    it "makes the request" do
      adapter.request(:get)

      expect(WebMock).to have_requested(:get, "example.com")
    end

    it "returns a valid HTTPI::Response" do
      expect(adapter.request(:get)).to match_response(body: body)
    end
  end

  describe "#request(:post)" do
    it "makes the request with the body" do
      httpi.body = "xml=hi&name=123"
      adapter.request(:post)

      expect(WebMock).to have_requested(:post, "example.com")
        .with { |req| req.body == "xml=hi&name=123" }
    end

    it "returns a valid HTTPI::Response" do
      expect(adapter.request(:post)).to match_response(body: body)
    end
  end

  describe "#request(:head)" do
    it "makes the request" do
      adapter.request(:head)

      expect(WebMock).to have_requested(:head, "example.com")
    end

    it "returns a valid HTTPI::Response" do
      expect(adapter.request(:head)).to match_response(body: body)
    end
  end

  describe "#request(:put)" do
    it "makes the request with the body" do
      httpi.body = 'xml=hi&name=123'
      adapter.request(:put)

      expect(WebMock).to have_requested(:put, "example.com")
        .with { |req| req.body == "xml=hi&name=123" }
    end

    it "returns a valid HTTPI::Response" do
      expect(adapter.request(:put)).to match_response(body: body)
    end
  end

  describe "#request(:delete)" do
    it "makes the request" do
      adapter.request(:delete)

      expect(WebMock).to have_requested(:delete, "example.com")
    end

    it "returns a valid HTTPI::Response" do
      expect(adapter.request(:delete)).to match_response(body: body)
    end
  end

  describe "settings:" do
    describe "proxy" do
      it "is not set unless it's specified" do
        generate_request do |request|
          expect(request.options[:proxy]).to be_nil
        end
      end

      it "is set if specified" do
        httpi.proxy = "http://proxy.example.com"

        generate_request do |request|
          expect(request.options[:proxy]).to eq("http://proxy.example.com")
        end
      end
    end

    describe "timeout_ms" do
      it "is not set unless it's specified" do
        generate_request do |request|
          expect(request.options[:timeout_ms]).to be_nil
        end
      end

      it "is set if specified read_timeout" do
        httpi.read_timeout = 30

        generate_request do |request|
          expect(request.options[:timeout_ms]).to eq(30_000)
        end
      end

      it "is set if specified write_timeout" do
        httpi.write_timeout = 30

        generate_request do |request|
          expect(request.options[:timeout_ms]).to eq(30_000)
        end
      end
    end

    describe "connecttimeout_ms" do
      it "is not set unless it's specified" do
        generate_request do |request|
          expect(request.options[:connecttimeout_ms]).to be_nil
        end
      end

      it "is set if specified" do
        httpi.open_timeout = 30

        generate_request do |request|
          expect(request.options[:connecttimeout_ms]).to eq(30_000)
        end
      end
    end

    describe "headers" do
      it "is set if specified" do
        httpi.headers = {
          "Coffee-Pot" => "of course"
        }

        generate_request do |request|
          expect(request.options[:headers]).to eq(
            "Coffee-Pot" => "of course"
          )
        end
      end
    end

    describe "http_auth_types" do
      it "is not set if no authentication is configured" do
        generate_request do |request|
          expect(request.options[:httpauth]).to be_nil
        end
      end

      it "is set to :basic for HTTP basic auth" do
        httpi.auth.basic "username", "password"

        generate_request do |request|
          expect(request.options[:httpauth]).to eq(:basic)
        end
      end

      it "is set to :digest for HTTP digest auth" do
        httpi.auth.digest "username", "password"

        generate_request do |request|
          expect(request.options[:httpauth]).to eq(:digest)
        end
      end

      it "is set to :ntlm for HTTP NTLM auth" do
        httpi.auth.ntlm("tester", "vReqSoafRe5O")

        generate_request do |request|
          expect(request.options[:httpauth]).to eq(:ntlm)
        end
      end
    end

    describe "username and password" do
      it "is set for HTTP basic auth" do
        httpi.auth.basic "foo", "bar"

        generate_request do |request|
          expect(request.options[:username]).to eq("foo")
          expect(request.options[:password]).to eq("bar")
        end
      end

      it "is set for HTTP digest auth" do
        httpi.auth.digest "foo", "bar"

        generate_request do |request|
          expect(request.options[:username]).to eq("foo")
          expect(request.options[:password]).to eq("bar")
        end
      end
    end

    context "(for SSL without auth)" do
      before do
        httpi.ssl = true
      end

      context "sets ssl_version" do
        it "defaults to nil when no ssl_version is specified" do
          generate_request do |request|
            expect(request.options[:sslversion]).to be_nil
          end
        end

        {
          TLSv1_2: :tlsv1_2,
          TLSv1_1: :tlsv1_1,
          TLSv1:   :tlsv1,
          SSLv2:   :sslv2,
          SSLv23:  :sslv2,
          SSLv3:   :sslv3,
        }.each do |httpi_value, typhoeus_value|
          it "is set to #{typhoeus_value} when ssl_version is specified as #{httpi_value}" do
            httpi.auth.ssl.ssl_version = httpi_value

            generate_request do |request|
              expect(request.options[:sslversion]).to eq(typhoeus_value)
            end
          end
        end
      end
    end

    context "(for SSL client auth)" do
      before do
        httpi.auth.ssl.cert_key_file = "spec/fixtures/client_key.pem"
        httpi.auth.ssl.cert_file = "spec/fixtures/client_cert.pem"
        httpi.auth.ssl.cert_key_password = "example"
      end

      it "send certificate regardless of state of SSL verify mode" do
        httpi.auth.ssl.verify_mode = :none

        generate_request do |request|
          expect(request.options[:sslcert]).to eq(httpi.auth.ssl.cert_file)
          expect(request.options[:sslkey]).to eq(httpi.auth.ssl.cert_key_file)
          expect(request.options[:sslkeypasswd]).to eq("example")
        end
      end

      it "cert_key, cert and ssl_verify_peer should be set" do
        generate_request do |request|
          expect(request.options[:sslcert]).to eq(httpi.auth.ssl.cert_file)
          expect(request.options[:sslkey]).to eq(httpi.auth.ssl.cert_key_file)
          expect(request.options[:sslkeypasswd]).to eq("example")

          expect(request.options[:ssl_verifyhost]).to eq(2)
          expect(request.options[:ssl_verifypeer]).to eq(true)
        end
      end

      it "sets the cert_type to DER if specified" do
        httpi.auth.ssl.cert_type = :der

        generate_request do |request|
          expect(request.options[:sslcerttype]).to eq("DER")
        end
      end

      it "sets the cacert if specified" do
        httpi.auth.ssl.ca_cert_file = "spec/fixtures/client_cert.pem"

        generate_request do |request|
          expect(request.options[:cainfo]).to eq(httpi.auth.ssl.ca_cert_file)
        end
      end
    end
  end

  def generate_request
    typhoeus_request = Typhoeus::Request.new("example.com")

    allow(Typhoeus::Request).to receive(:new) { |_url, options|
      typhoeus_request.options = options
      typhoeus_request
    }

    adapter.request(:get)

    yield(typhoeus_request)
  end
end
