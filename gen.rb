#!/usr/bin/env ruby
require 'csv'
require 'json'
require 'set'

def usage
  STDERR.puts <<-EOM
usage: #{File.basename($0)} FORMAT IANA_JSON OPENSSL_JSON

Generate new OpenSSL ciphers list

FORMAT: one of json or csv

IANA_JSON: a processed IANA TLS ciphers list, in JSON format

OPENSSL_JSON: a processed OpenSSL TLS ciphers list, in JSON format
  EOM
end

if ARGV.length < 3
  usage
  exit 1
end

def load_data(iana_json_file, openssl_json_file)
  iana = JSON.parse(File.read(iana_json_file))
  openssl = JSON.parse(File.read(openssl_json_file))

  # deep merge two levels
  output = iana.dup

  openssl.each_pair do |key, data|
    output[key] = output[key].merge(data)
  end

  output
end

def generate_json(iana_json, openssl_json)
  JSON.pretty_generate(load_data(iana_json, openssl_json))
end

CSVKeys = %w{Value
             Byte1 Byte2 IANA DTLS? Reference
             OpenSSL Version Kx Au Enc Mac Export?}
IanaKeys = %w{byte1 byte2 iana dtls? reference}
OpensslKeys = %w{openssl ssl_version kx au enc mac export}

def csv_process_row(key, hash)
  include_openssl = hash.include?('openssl')
  if include_openssl
    keys = IanaKeys + OpensslKeys
  else
    keys = IanaKeys
  end

  row = []

  keys.each do |k|
    begin
      row << hash.fetch(k)
    rescue KeyError
      STDERR.puts "No #{k.inspect} in #{key.inspect}: #{hash.inspect}"
      raise
    end
  end

  unless include_openssl
    OpensslKeys.each { row << nil }
  end

  row
end

def generate_csv(iana_json, openssl_json)
  data = load_data(iana_json, openssl_json)

  CSV.generate do |csv|
    # add header
    csv << CSVKeys

    data.each_pair do |key, hash|
      row = [key]

      csv_process_row(key, hash).each do |v|
        row << v
      end

      csv << row
    end
  end
end

def main(format, iana_json, openssl_json)
  case format.downcase
  when 'csv'
    puts generate_csv(iana_json, openssl_json)
  when 'json'
    puts generate_json(iana_json, openssl_json)
  else
    usage
    raise ArgumentError.new("Invalid format #{format.inspect}")
  end
end

format, iana_json, openssl_json = ARGV
main(format, iana_json, openssl_json)
