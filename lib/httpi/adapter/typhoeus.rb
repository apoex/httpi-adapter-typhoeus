require "httpi"

module HTTPI
  module Adapter
    class Typhoeus < Base
      class TyphoesConnectionError < StandardError
        extend ConnectionError
      end

      register :typhoeus, deps: %w(typhoeus)

      def initialize(request)
        @request = request
      end

      def request(http_method)
        @client = ::Typhoeus::Request.new(
          @request.url,
          method: http_method,
          body: @request.body,
          headers: @request.headers
        )

        configure_auth
        configure_proxy
        configure_ssl
        configure_timeouts

        response = @client.run

        if response.timed_out?
          raise TimeoutError
        elsif response.response_code == 0
          case response.return_message
          when /ssl/i
            raise SSLError, response.return_message
          else
            raise TyphoesConnectionError, response.return_message
          end
        else
          Response.new(response.code, response.headers, response.body)
        end
      end

      private

      def configure_auth
        return unless @request.auth.http? || @request.auth.ntlm?

        @client.options[:httpauth] = @request.auth.type
        @client.options[:username], @client.options[:password] = *@request.auth.credentials
      end

      def configure_proxy
        @client.options[:proxy] = @request.proxy.to_s if @request.proxy
      end

      def configure_ssl
        ssl = @request.auth.ssl

        @client.options[:sslversion] = case ssl.ssl_version
          when :TLSv1_2 then :tlsv1_2
          when :TLSv1_1 then :tlsv1_1
          when :TLSv1   then :tlsv1
          when :SSLv2   then :sslv2
          when :SSLv23  then :sslv2
          when :SSLv3   then :sslv3
        end

        return unless @request.auth.ssl?

        if ssl.verify_mode == :none
          @client.options[:ssl_verifyhost] = 0
          @client.options[:ssl_verifypeer] = false
        else
          @client.options[:ssl_verifyhost] = 2
          @client.options[:ssl_verifypeer] = ssl.verify_mode == :peer
        end

        @client.options[:sslcerttype]  = ssl.cert_type.to_s.upcase
        @client.options[:sslcert]      = ssl.cert_file if ssl.cert_file
        @client.options[:sslkey]       = ssl.cert_key_file if ssl.cert_key_file
        @client.options[:sslkeypasswd] = ssl.cert_key_password if ssl.cert_key_password
        @client.options[:cainfo]       = ssl.ca_cert_file if ssl.ca_cert_file
      end

      def configure_timeouts
        @client.options[:connecttimeout_ms] = (@request.open_timeout * 1000).to_i if @request.open_timeout
        read_or_write_timeout = @request.read_timeout || @request.write_timeout
        @client.options[:timeout_ms] = (read_or_write_timeout * 1000).to_i if read_or_write_timeout
      end
    end
  end
end
