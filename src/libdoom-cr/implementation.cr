CDoom.screen_buffer = Pointer(UInt8).null
CDoom.final_screen_buffer = Pointer(UInt8).null
CDoom.last_update_time = 0
CDoom.button_states = StaticArray(Int32, 3).new(0)

CDoom.doom_flags = 0
CDoom.doom_print = CDoom::DoomPrintFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_malloc = CDoom::DoomMallocFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_free = CDoom::DoomFreeFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_open = CDoom::DoomOpenFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_close = CDoom::DoomCloseFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_read = CDoom::DoomReadFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_write = CDoom::DoomWriteFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_seek = CDoom::DoomSeekFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_tell = CDoom::DoomTellFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_eof = CDoom::DoomEofFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_gettime = CDoom::DoomGettimeFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_exit = CDoom::DoomExitFn.new(Pointer(Void).null, Pointer(Void).null)
CDoom.doom_getenv = CDoom::DoomGetenvFn.new(Pointer(Void).null, Pointer(Void).null)

fun doom_print_impl(str : UInt8*)
  print String.new(str)
end

fun doom_malloc_impl(size : Int32) : Void*
  return GC.malloc(size)
end

fun doom_free_impl(ptr : Void*)
  GC.free(ptr)
end

fun doom_open_impl(filename : UInt8*, mode : UInt8*) : Void*
  begin
    file = File.new(String.new(filename), String.new(mode))
    return Box.box(file)
  rescue
  end
  return Pointer(Void).null
end
fun doom_close_impl(handle : Void*)
  Box(File).unbox(handle).close
end
fun doom_read_impl(handle : Void*, buf : Void*, count : Int32) : Int32
  slice = Slice.new(buf.as(UInt8*), count)
  return Box(File).unbox(handle).read(slice)
end
fun doom_write_impl(handle : Void*, buf : Void*, count : Int32) : Int32
  slice = Slice.new(buf.as(UInt8*), count)
  Box(File).unbox(handle).write(slice)
  return count
end
fun doom_seek_impl(handle : Void*, offset : Int32, origin : CDoom::DoomSeek) : Int32
  begin
    Box(File).unbox(handle).seek(offset, IO::Seek.from_value(origin.value))
  rescue
    return 1
  end
  return 0
end
fun doom_tell_impl(handle : Void*) : Int32
  return Box(File).unbox(handle).pos.to_i32
end
fun doom_eof_impl(handle : Void*) : Int32
  file = Box(File).unbox(handle)
  return file.pos >= file.size ? 1 : 0
end

fun doom_gettime_impl(sec : Int32*, usec : Int32*)
  sec.value = Time.local.to_unix.to_i32
  usec.value = (Time.local.nanosecond // 1_000).to_i32
end

fun doom_exit_impl(code : Int32)
  exit code
end

fun doom_getenv_impl(var : UInt8*) : UInt8*
  ENV[String.new(var)]?.try { |env| return env.to_unsafe }
  return Pointer(UInt8).null
end

fun doom_memset(ptr : Void*, value : Int32, num : Int32)
  ptr.as(UInt8*).fill(num, value.to_u8!)
end

fun doom_memcpy(destination : Void*, source : Void*, num : Int32) : Void*
  destination.as(UInt8*).copy_from(source.as(UInt8*), num)
  return destination
end

fun doom_strlen(str : UInt8*) : Int32
  return String.new(str).size
end

fun doom_concat(dst : UInt8*, src : UInt8*) : UInt8*
  concat = String.new(dst) + String.new(src)
  concat.to_slice.copy_to(dst, concat.bytesize)
  dst[concat.bytesize] = 0
  return dst
end

fun doom_strcpy(dst : UInt8*, src : UInt8*) : UInt8*
  dst.copy_from(src, doom_strlen(src) + 1)
  return dst
end

fun doom_strncpy(dst : UInt8*, src : UInt8*, num : Int32) : UInt8*
  len = doom_strlen(src) < num ? doom_strlen(src) : num
  diff = num - len
  dst.copy_from(src, len)
  (dst + len).fill(diff, 0_u8)
  return dst
end

fun doom_strcmp(str1 : UInt8*, str2 : UInt8*) : Int32
  return str1.memcmp(str2, doom_strlen(str1)).clamp(-1, 1)
end

fun doom_strncmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
  len = doom_strlen(str1) < n ? doom_strlen(str1) : n
  return str1.memcmp(str2, len).clamp(-1, 1)
end

fun doom_toupper(c : Int32) : Int32
  return c.chr.upcase.ord
end

fun doom_strcasecmp(str1 : UInt8*, str2 : UInt8*) : Int32
  return String.new(str1).compare(String.new(str2), case_insensitive: true)
end

fun doom_strncasecmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
  len = doom_strlen(str1) < n ? doom_strlen(str1) : n
  return String.new(str1)[...len].compare(String.new(str2)[...len], case_insensitive: true)
end

fun doom_atoi(str : UInt8*) : Int32
  String.new(str).to_i?(strict: false).try { |i| return i }
  return 0
end

fun doom_atox(str : UInt8*) : Int32
  String.new(str).to_i?(base: 16, strict: false).try { |i| return i }
  return 0
end

fun doom_itoa(k : Int32, radix : Int32) : UInt8*
  a = k.to_s(radix)
  a.to_slice.copy_to(CDoom.itoa_buf.to_unsafe, a.bytesize)
  CDoom.itoa_buf[a.bytesize] = 0
  return CDoom.itoa_buf.to_unsafe
end

fun doom_ctoa(c : UInt8) : UInt8*
  CDoom.itoa_buf[0] = c
  CDoom.itoa_buf[1] = 0
  return CDoom.itoa_buf.to_unsafe
end

fun doom_ptoa(p : Void*) : UInt8*
  a = "0x" + p.address.to_s(16).upcase
  a.to_slice.copy_to(CDoom.itoa_buf.to_unsafe, a.bytesize)
  CDoom.itoa_buf[a.bytesize] = 0
  return CDoom.itoa_buf.to_unsafe
end

fun doom_fprint(handle : Void*, str : UInt8*) : Int32
  return CDoom.doom_write.call(handle, str.as(Void*), doom_strlen(str))
end

fun get_default(name : UInt8*) : CDoom::Default*
  base = CDoom.defaults.to_unsafe
  CDoom.numdefaults.times do |i|
    default = base + i
    return default if doom_strcmp(default.value.name, name) == 0
  end
  return Pointer(CDoom::Default).null
end

fun doom_set_resolution(width : Int32, height : Int32)
  return if width <= 0 || height <= 0
end

fun doom_set_default_int(name : UInt8*, value : Int32)
  default = get_default(name)
  return if default.null?
  default.value.defaultvalue = value
end

fun doom_set_default_string(name : UInt8*, value : UInt8*)
  default = get_default(name)
  return if default.null?
  default.value.default_text_value = value
end

fun doom_set_print(print_fn : CDoom::DoomPrintFn)
  CDoom.doom_print = print_fn
end

fun doom_set_malloc(malloc_fn : CDoom::DoomMallocFn, free_fn : CDoom::DoomFreeFn)
  CDoom.doom_malloc = malloc_fn
  CDoom.doom_free = free_fn
end

fun doom_set_file_io(open_fn : CDoom::DoomOpenFn,
                     close_fn : CDoom::DoomCloseFn,
                     read_fn : CDoom::DoomReadFn,
                     write_fn : CDoom::DoomWriteFn,
                     seek_fn : CDoom::DoomSeekFn,
                     tell_fn : CDoom::DoomTellFn,
                     eof_fn : CDoom::DoomEofFn)
  CDoom.doom_open = open_fn
  CDoom.doom_close = close_fn
  CDoom.doom_read = read_fn
  CDoom.doom_write = write_fn
  CDoom.doom_seek = seek_fn
  CDoom.doom_tell = tell_fn
  CDoom.doom_eof = eof_fn
end

fun doom_set_gettime(gettime_fn : CDoom::DoomGettimeFn)
  CDoom.doom_gettime = gettime_fn
end

fun doom_set_exit(exit_fn : CDoom::DoomExitFn)
  CDoom.doom_exit = exit_fn
end

fun doom_set_getenv(getenv_fn : CDoom::DoomGetenvFn)
  CDoom.doom_getenv = getenv_fn
end

fun doom_init(argc : Int32, argv : UInt8**, flags : Int32)
  CDoom.doom_print = ->doom_print_impl(UInt8*) if CDoom.doom_print.pointer.null?
  CDoom.doom_malloc = ->doom_malloc_impl(Int32) if CDoom.doom_malloc.pointer.null?
  CDoom.doom_free = ->doom_free_impl(Void*) if CDoom.doom_free.pointer.null?
  CDoom.doom_open = ->doom_open_impl(UInt8*, UInt8*) if CDoom.doom_open.pointer.null?
  CDoom.doom_close = ->doom_close_impl(Void*) if CDoom.doom_close.pointer.null?
  CDoom.doom_read = ->doom_read_impl(Void*, Void*, Int32) if CDoom.doom_read.pointer.null?
  CDoom.doom_write = ->doom_write_impl(Void*, Void*, Int32) if CDoom.doom_write.pointer.null?
  CDoom.doom_seek = ->doom_seek_impl(Void*, Int32, CDoom::DoomSeek) if CDoom.doom_seek.pointer.null?
  CDoom.doom_tell = ->doom_tell_impl(Void*) if CDoom.doom_tell.pointer.null?
  CDoom.doom_eof = ->doom_eof_impl(Void*) if CDoom.doom_eof.pointer.null?
  CDoom.doom_gettime = ->doom_gettime_impl(Int32*, Int32*) if CDoom.doom_gettime.pointer.null?
  CDoom.doom_exit = ->doom_exit_impl(Int32) if CDoom.doom_exit.pointer.null?
  CDoom.doom_getenv = ->doom_getenv_impl(UInt8*) if CDoom.doom_getenv.pointer.null?

  CDoom.screen_buffer = CDoom.doom_malloc.call(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).as(UInt8*)
  CDoom.final_screen_buffer = CDoom.doom_malloc.call(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT * 4).as(UInt8*)
  CDoom.last_update_time = CDoom.i_get_time()

  CDoom.myargc = argc
  CDoom.myargv = argv
  CDoom.doom_flags = flags

  CDoom.d_doom_main()
end