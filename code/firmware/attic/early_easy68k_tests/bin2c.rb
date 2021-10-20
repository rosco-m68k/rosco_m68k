if ARGV.length < 1
  puts "bin2c.rb <basename>"
else
  basename = ARGV[0]

  even = File.open(basename + '_0.BIN', 'rb') { |f| f.read }.bytes
  odd  = File.open(basename + '_1.BIN', 'rb') { |f| f.read }.bytes

  if even.length != odd.length
    puts "I can't handle uneven ROM length yet (even is #{even.length}, while odd is #{odd.length})"
  else
    puts "static unsigned int len = #{even.length};"
    puts "static unsigned char even[] = { #{even.map { |b| "0x" + b.to_s(16) }.join(",") } };"
    puts "static unsigned char odd[]  = { #{odd.map { |b| "0x" + b.to_s(16) }.join(",") } };"
  end
end

