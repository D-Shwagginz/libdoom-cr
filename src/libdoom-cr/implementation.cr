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

fun doom_print_impl(str : LibC::Char*)
  print String.new(str)
end

fun doom_malloc_impl(size : LibC::Int) : Void*
  return GC.malloc(size)
end

fun doom_free_impl(ptr : Void*)
  GC.free(ptr)
end

fun doom_open_impl(filename : LibC::Char*, mode : LibC::Char*) : Void*
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
fun doom_read_impl(handle : Void*, buf : Void*, count : LibC::Int) : LibC::Int
  slice = Slice.new(buf.as(UInt8*), count)
  return Box(File).unbox(handle).read(slice)
end
fun doom_write_impl(handle : Void*, buf : Void*, count : LibC::Int) : LibC::Int
  slice = Slice.new(buf.as(UInt8*), count)
  Box(File).unbox(handle).write(slice)
  return count
end
fun doom_seek_impl(handle : Void*, offset : LibC::Int, origin : CDoom::DoomSeek) : LibC::Int
  begin
    Box(File).unbox(handle).seek(offset, IO::Seek.from_value(origin.value))
  rescue
    return 1
  end
  return 0
end
fun doom_tell_impl(handle : Void*) : LibC::Int
  return Box(File).unbox(handle).pos.to_i32
end
fun doom_eof_impl(handle : Void*) : LibC::Int
  file = Box(File).unbox(handle)
  return file.pos >= file.size ? 1 : 0
end

fun doom_gettime_impl(sec : LibC::Int*, usec : LibC::Int*)
  sec.value = Time.local.to_unix.to_i32
  usec.value = (Time.local.nanosecond // 1_000).to_i32
end

fun doom_exit_impl(code : LibC::Int)
  exit code
end

fun doom_getenv_impl(var : LibC::Char*) : LibC::Char*
  ENV[String.new(var)]?.try { |env| return env.to_unsafe }
  return Pointer(LibC::Char).null
end


fun doom_memset(ptr : Void*, value : LibC::Int, num : LibC::Int)
  ptr.as(UInt8*).fill(num, value.to_u8!)
end

fun doom_memcpy(destination : Void*, source : Void*, num : LibC::Int) : Void*
  destination.as(UInt8*).copy_from(source.as(UInt8*), num)
  return destination
end

fun doom_strlen(str : LibC::Char*) : LibC::Int
  return String.new(str).size
end

fun doom_concat(dst : LibC::Char*, src : LibC::Char*) : LibC::Char*
  concat = String.new(dst) + String.new(src)
  concat.to_slice.copy_to(dst, concat.bytesize)
  dst[concat.bytesize] = 0
  return dst
end

fun doom_strcpy(dst : LibC::Char*, src : LibC::Char*) : LibC::Char*
  dst.copy_from(src, doom_strlen(src) + 1)
  return dst
end

fun doom_strncpy(dst : LibC::Char*, src : LibC::Char*, num : LibC::Int) : LibC::Char*
  len = doom_strlen(src) < num ? doom_strlen(src) : num
  diff = num - len
  dst.copy_from(src, len)
  (dst + len).fill(diff, 0_u8)
  return dst
end

fun doom_strcmp(str1 : LibC::Char*, str2 : LibC::Char*) : LibC::Int
  return str1.memcmp(str2, doom_strlen(str1)).clamp(-1, 1)
end

fun doom_strncmp(str1 : LibC::Char*, str2 : LibC::Char*, n : LibC::Int) : LibC::Int
  len = doom_strlen(str1) < n ? doom_strlen(str1) : n
  return str1.memcmp(str2, len).clamp(-1, 1)
end

fun doom_toupper(c : LibC::Int) : LibC::Int
  return c.chr.upcase.ord
end

