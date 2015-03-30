#!/usr/bin/env ruby

require 'csv'
require 'json'

source_basename = 'tls-parameters-4.csv'
source_file = File.join(File.dirname(__FILE__), 'source', source_basename)

data = CSV.read(ARGV.fetch(0, source_file))

unless data.first == ["Value", "Description", "DTLS-OK", "Reference"]
  raise ArgumentError.new("Unexpected header from tls-parameters CSV file")
end

output = {}

BooleanMap = {'Y' => true, 'N' => false}

data[1..-1].each do |row|
  value, description, dtls_ok, reference = row
  byte1, byte2 = value.split(',')

  if description == "Unassigned"
    STDERR.puts "Skipping unassigned: #{row}"
    next
  end
  if description.start_with?("Reserved")
    STDERR.puts "Skipping reserved: #{row}"
    next
  end

  int = (Integer(byte1, 16) << 8) + Integer(byte2, 16)

  output[value] = {
    'int' => int,
    'byte1' => byte1,
    'byte2' => byte2,
    'IANA' => description,
    'dtls?' => BooleanMap.fetch(dtls_ok),
    'reference' => reference,
  }
end

STDOUT.puts(JSON.pretty_generate(output))
