#!/usr/bin/env ruby

require 'json'

def process_equals_arg(name, data)
  key, value = data.split('=')
  unless key && value
    raise ArgumentError.new("Could not parse #{data.inspect}")
  end

  if key.downcase != name.downcase
    raise "Unexpected key #{key.inspect} for name #{name.inspect}"
  end

  return value
end

def process_enc(enc)
  md = enc.match(/\AEnc=(\w+)\((\d+)\)\z/)
  {
    'enc_algo' => md.captures.fetch(0),
    'enc_bits' => Integer(md.captures.fetch(1)),
  }
end

def main(filename)
  if filename == '-'
    file = STDIN
  else
    file = File.open(filename, 'r')
  end

  output = {}

  file.each_line do |line|
    parts = line.gsub(/\s+/, ' ').split(' ')
    value, _hyphen, description, ssl_ver, kx, au, enc, mac, export = parts

    byte1, byte2 = value.split(',')
    int = (Integer(byte1, 16) << 8) + Integer(byte2, 16)

    extra = {}
    extra['kx'] = process_equals_arg('kx', kx)
    extra['au'] = process_equals_arg('au', au)
    extra['enc'] = process_equals_arg('enc', enc)
    extra = extra.merge(process_enc(enc))
    extra['mac'] = process_equals_arg('mac', mac)

    if export
      extra['export'] = true
    end

    output[value] = {
      'int' => int,
      'byte1' => byte1,
      'byte2' => byte2,
      'openssl' => description,
      'ssl_version' => ssl_ver,
    }.merge(extra)

  end

  return output
end

if ARGV.empty?
  STDERR.puts <<-EOM
usage: #{File.basename($0)} FILE

Process text output of \`openssl ciphers -V\` from FILE (or stdin).
  EOM
  exit 1
end

puts JSON.pretty_generate(main(ARGV.fetch(0)))
