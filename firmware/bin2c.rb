if ARGV.length < 1
  puts "bin2c.rb <basename>"
else
  basename = ARGV[0]

  even = File.read(basename + '_0.BIN').bytes
  odd  = File.read(basename + '_1.BIN').bytes

  if even.length != odd.length
    puts "I can't handle uneven ROM length yet"
  else
    puts "static unsigned int len = #{even.length};"
    puts "static unsigned char even[] = { #{File.read(basename + '_0.BIN').bytes.map { |b| "0x" + b.to_s(16) }.join(",") } };"
    puts "static unsigned char odd[]  = { #{File.read(basename + '_1.BIN').bytes.map { |b| "0x" + b.to_s(16) }.join(",") } };"
  end
end

