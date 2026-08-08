@[Link(ldflags: "#{__DIR__}/../../build/glue.o -L#{__DIR__}/../.. -lpuredoom")]
lib CDoom
  fun doom_init(argc : LibC::Int, argv : LibC::Char**, flags : LibC::Int)
end