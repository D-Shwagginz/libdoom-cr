require "./libdoom-cr/lib.cr"

def run
  ARGV.insert(0, "LibDoom-CR")
  CDoom.doom_init(ARGV.size, ARGV.map(&.to_unsafe), 0)
end

fun crystal_D_DoomMain()
  puts "D_DoomMain called"
end

run()