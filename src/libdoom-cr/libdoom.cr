module LibDoom
  @@st_notify : CDoom::Event = CDoom::Event.new
  @@lastlevel = -1
  @@lastepisode = -1
  @@cheatstate = 0
  @@bigstate = 0
  @@buffer : UInt8* = Pointer(UInt8).malloc(20)
  @@nexttic = 0
  @@litelevels : StaticArray(Int32, 8) = StaticArray[0, 4, 7, 10, 12, 14, 15, 15]
  @@litelevelscnt = 0

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

  CDoom.player_arrow[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: CDoom::R, y: 0)) # -----
  CDoom.player_arrow[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: CDoom::R // 4)) # ----->
  CDoom.player_arrow[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: -CDoom::R // 4))
  CDoom.player_arrow[3] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: CDoom::R // 4)) # >---->
  CDoom.player_arrow[4] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: -CDoom::R // 4))
  CDoom.player_arrow[5] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: CDoom::R // 4)) # >>--->
  CDoom.player_arrow[6] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: -CDoom::R // 4))

  CDoom.cheat_player_arrow[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: CDoom::R, y: 0)) # -----
  CDoom.cheat_player_arrow[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: CDoom::R // 6)) # ----->
  CDoom.cheat_player_arrow[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R, y: 0), b: CDoom::Mpoint.new(x: CDoom::R - CDoom::R // 2, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[3] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: CDoom::R // 6)) # >----->
  CDoom.cheat_player_arrow[4] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R - CDoom::R // 8, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[5] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: CDoom::R // 6)) # >>----->
  CDoom.cheat_player_arrow[6] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R + 3 * CDoom::R // 8, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R + CDoom::R // 8, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[7] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 2, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R // 2, y: -CDoom::R // 6)) # >>-d--->
  CDoom.cheat_player_arrow[8] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 2, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: -CDoom::R // 2 + CDoom::R // 6, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[9] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 2 + CDoom::R // 6, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: -CDoom::R // 2 + CDoom::R // 6, y: CDoom::R // 4))
  CDoom.cheat_player_arrow[10] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 6, y: 0), b: CDoom::Mpoint.new(x: -CDoom::R // 6, y: -CDoom::R // 6)) # >>-dd-->
  CDoom.cheat_player_arrow[11] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: -CDoom::R // 6, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: 0, y: -CDoom::R // 6))
  CDoom.cheat_player_arrow[12] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: 0, y: -CDoom::R // 6), b: CDoom::Mpoint.new(x: 0, y: CDoom::R // 4))
  CDoom.cheat_player_arrow[13] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R // 6, y: CDoom::R // 4), b: CDoom::Mpoint.new(x: CDoom::R // 6, y: -CDoom::R // 7)) # >>-ddt->
  CDoom.cheat_player_arrow[14] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R // 6, y: -CDoom::R // 7), b: CDoom::Mpoint.new(x: CDoom::R // 6 + CDoom::R // 32, y: -CDoom::R // 7 - CDoom::R // 32))
  CDoom.cheat_player_arrow[15] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::R // 6 + CDoom::R // 32, y: -CDoom::R // 7 - CDoom::R // 32), b: CDoom::Mpoint.new(x: CDoom::R // 6 + CDoom::R // 10, y: -CDoom::R // 7))

  CDoom.triangle_guy[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (-0.867 * CDoom::FRACUNIT).to_i32!, y: (-0.5 * CDoom::FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: (0.867 * CDoom::FRACUNIT).to_i32!, y: (-0.5 * CDoom::FRACUNIT).to_i32!))
  CDoom.triangle_guy[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (0.867 * CDoom::FRACUNIT).to_i32!, y: (-0.5 * CDoom::FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: 0, y: CDoom::FRACUNIT))
  CDoom.triangle_guy[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: 0, y: CDoom::FRACUNIT), b: CDoom::Mpoint.new(x: (-0.867 * CDoom::FRACUNIT).to_i32!, y: (-0.5 * CDoom::FRACUNIT).to_i32!))

  CDoom.thintriangle_guy[0] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (-0.5 * CDoom::FRACUNIT).to_i32!, y: (-0.7 * CDoom::FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: CDoom::FRACUNIT, y: 0))
  CDoom.thintriangle_guy[1] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: CDoom::FRACUNIT, y: 0), b: CDoom::Mpoint.new(x: (-0.5 * CDoom::FRACUNIT).to_i32!, y: (0.7 * CDoom::FRACUNIT).to_i32!))
  CDoom.thintriangle_guy[2] = CDoom::Mline.new(
    a: CDoom::Mpoint.new(x: (-0.5 * CDoom::FRACUNIT).to_i32!, y: (0.7 * CDoom::FRACUNIT).to_i32!), b: CDoom::Mpoint.new(x: (-0.5 * CDoom::FRACUNIT).to_i32, y: (-0.7 * CDoom::FRACUNIT).to_i32!))

  CDoom.cheating = 0
  CDoom.grid = 0

  CDoom.leveljuststarted = 0

  CDoom.finit_width = CDoom::SCREENWIDTH
  CDoom.finit_height = CDoom::SCREENHEIGHT - 32

  CDoom.scale_mtof = CDoom::INITSCALEMTOF

  CDoom.markpointnum = 0

  CDoom.followplayer = 1

  CDoom.cheat_amap_seq[0] = 0xb2
  CDoom.cheat_amap_seq[1] = 0x26
  CDoom.cheat_amap_seq[2] = 0x26
  CDoom.cheat_amap_seq[3] = 0x2e
  CDoom.cheat_amap_seq[4] = 0xff
  CDoom.cheat_amap.sequence = CDoom.cheat_amap_seq.to_unsafe.as(UInt8*)
  CDoom.cheat_amap.p = Pointer(UInt8).null

  CDoom.stopped = 1

  CDoom.automapactive = 0

  def self.doom_print_impl(str : UInt8*)
    print String.new(str)
  end

  def self.doom_malloc_impl(size : Int32) : Void*
    return GC.malloc(size)
  end

  def self.doom_free_impl(ptr : Void*)
    GC.free(ptr)
  end

  def self.doom_open_impl(filename : UInt8*, mode : UInt8*) : Void*
    begin
      file = File.new(String.new(filename), String.new(mode))
      return Box.box(file)
    rescue
    end
    return Pointer(Void).null
  end

  def self.doom_close_impl(handle : Void*)
    Box(File).unbox(handle).close
  end

  def self.doom_read_impl(handle : Void*, buf : Void*, count : Int32) : Int32
    slice = Slice.new(buf.as(UInt8*), count)
    return Box(File).unbox(handle).read(slice)
  end

  def self.doom_write_impl(handle : Void*, buf : Void*, count : Int32) : Int32
    slice = Slice.new(buf.as(UInt8*), count)
    Box(File).unbox(handle).write(slice)
    return count
  end

  def self.doom_seek_impl(handle : Void*, offset : Int32, origin : CDoom::DoomSeek) : Int32
    begin
      Box(File).unbox(handle).seek(offset, IO::Seek.from_value(origin.value))
    rescue
      return 1
    end
    return 0
  end

  def self.doom_tell_impl(handle : Void*) : Int32
    return Box(File).unbox(handle).pos.to_i32
  end

  def self.doom_eof_impl(handle : Void*) : Int32
    file = Box(File).unbox(handle)
    return file.pos >= file.size ? 1 : 0
  end

  def self.doom_gettime_impl(sec : Int32*, usec : Int32*)
    sec.value = Time.local.to_unix.to_i32
    usec.value = (Time.local.nanosecond // 1_000).to_i32
  end

  def self.doom_exit_impl(code : Int32)
    exit code
  end

  def self.doom_getenv_impl(var : UInt8*) : UInt8*
    ENV[String.new(var)]?.try { |env| return env.to_unsafe }
    return Pointer(UInt8).null
  end

  def self.doom_memset(ptr : Void*, value : Int32, num : Int32)
    ptr.as(UInt8*).fill(num, value.to_u8!)
  end

  def self.doom_memcpy(destination : Void*, source : Void*, num : Int32) : Void*
    destination.as(UInt8*).copy_from(source.as(UInt8*), num)
    return destination
  end

  def self.doom_strlen(str : UInt8*) : Int32
    return String.new(str).size
  end

  def self.doom_concat(dst : UInt8*, src : UInt8*) : UInt8*
    concat = String.new(dst) + String.new(src)
    concat.to_slice.copy_to(dst, concat.bytesize)
    dst[concat.bytesize] = 0
    return dst
  end

  def self.doom_strcpy(dst : UInt8*, src : UInt8*) : UInt8*
    cpy = String.new(src)
    cpy.to_slice.copy_to(dst, cpy.bytesize)
    dst[cpy.bytesize] = 0
    return dst
  end

  def self.doom_strncpy(dst : UInt8*, src : UInt8*, num : Int32) : UInt8*
    len = doom_strlen(src) < num ? doom_strlen(src) : num
    diff = num - len
    dst.copy_from(src, len)
    (dst + len).fill(diff, 0_u8)
    return dst
  end

  def self.doom_strcmp(str1 : UInt8*, str2 : UInt8*) : Int32
    return str1.memcmp(str2, doom_strlen(str1) + 1).clamp(-1, 1)
  end

  def self.doom_strncmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
    len = doom_strlen(str1) + 1 < n ? doom_strlen(str1) + 1 : n
    return str1.memcmp(str2, len).clamp(-1, 1)
  end

  def self.doom_toupper(c : Int32) : Int32
    return c.chr.upcase.ord
  end

  def self.doom_strcasecmp(str1 : UInt8*, str2 : UInt8*) : Int32
    return String.new(str1).compare(String.new(str2), case_insensitive: true)
  end

  def self.doom_strncasecmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
    len = doom_strlen(str1) < n ? doom_strlen(str1) : n
    return String.new(str1)[...len].compare(String.new(str2)[...len], case_insensitive: true)
  end

  def self.doom_atoi(str : UInt8*) : Int32
    String.new(str).to_i?(strict: false).try { |i| return i }
    return 0
  end

  def self.doom_atox(str : UInt8*) : Int32
    String.new(str).to_i?(base: 16, strict: false).try { |i| return i }
    return 0
  end

  def self.doom_itoa(k : Int32, radix : Int32) : UInt8*
    a = k.to_s(radix)
    a.to_slice.copy_to(CDoom.itoa_buf.to_unsafe, a.bytesize)
    CDoom.itoa_buf[a.bytesize] = 0
    return CDoom.itoa_buf.to_unsafe
  end

  def self.doom_ctoa(c : UInt8) : UInt8*
    CDoom.itoa_buf[0] = c
    CDoom.itoa_buf[1] = 0
    return CDoom.itoa_buf.to_unsafe
  end

  def self.doom_ptoa(p : Void*) : UInt8*
    a = "0x" + p.address.to_s(16).upcase
    a.to_slice.copy_to(CDoom.itoa_buf.to_unsafe, a.bytesize)
    CDoom.itoa_buf[a.bytesize] = 0
    return CDoom.itoa_buf.to_unsafe
  end

  def self.doom_fprint(handle : Void*, str : UInt8*) : Int32
    return CDoom.doom_write.call(handle, str.as(Void*), doom_strlen(str))
  end

  def self.get_default(name : UInt8*) : CDoom::Default*
    base = CDoom.defaults.to_unsafe
    CDoom.numdefaults.times do |i|
      default = base + i
      return default if doom_strcmp(default.value.name, name) == 0
    end
    return Pointer(CDoom::Default).null
  end

  def self.doom_set_resolution(width : Int32, height : Int32)
    return if width <= 0 || height <= 0
  end

  def self.doom_set_default_int(name : UInt8*, value : Int32)
    default = get_default(name)
    return if default.null?
    default.value.defaultvalue = value
  end

  def self.doom_set_default_string(name : UInt8*, value : UInt8*)
    default = get_default(name)
    return if default.null?
    default.value.default_text_value = value
  end

  def self.doom_set_print(print_fn : CDoom::DoomPrintFn)
    CDoom.doom_print = print_fn
  end

  def self.doom_set_malloc(malloc_fn : CDoom::DoomMallocFn, free_fn : CDoom::DoomFreeFn)
    CDoom.doom_malloc = malloc_fn
    CDoom.doom_free = free_fn
  end

  def self.doom_set_file_io(open_fn : CDoom::DoomOpenFn,
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

  def self.doom_set_gettime(gettime_fn : CDoom::DoomGettimeFn)
    CDoom.doom_gettime = gettime_fn
  end

  def self.doom_set_exit(exit_fn : CDoom::DoomExitFn)
    CDoom.doom_exit = exit_fn
  end

  def self.doom_set_getenv(getenv_fn : CDoom::DoomGetenvFn)
    CDoom.doom_getenv = getenv_fn
  end

  def self.doom_init(argc : Int32, argv : UInt8**, flags : Int32)
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
    CDoom.last_update_time = CDoom.i_get_time

    CDoom.myargc = argc
    CDoom.myargv = argv
    CDoom.doom_flags = flags

    CDoom.d_doom_main
  end

  def self.doom_update
    now = CDoom.i_get_time
    delta_time = now - CDoom.last_update_time

    delta_time.times do |i|
      if CDoom.is_wiping_screen != 0
        CDoom.d_update_wipe
      else
        CDoom.d_doom_loop
      end
    end

    CDoom.last_update_time = now
  end

  def self.doom_force_update
    if CDoom.is_wiping_screen != 0
      CDoom.d_update_wipe
    else
      CDoom.d_doom_loop
    end
  end

  def self.doom_get_framebuffer(channels : Int32) : UInt8*
    doom_memcpy(CDoom.screen_buffer.as(Void*), CDoom.screens[0].as(Void*), CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT)

    # Draw crosshair
    if (CDoom.crosshair != 0 &&
       CDoom.menuactive == 0 &&
       CDoom.gamestate == CDoom::Gamestate::Level &&
       CDoom.automapactive == 0)
      y = CDoom::SCREENHEIGHT // 2
      y += CDoom.setblocks == 11 ? 8 : -8
      2.times do |i|
        CDoom.screen_buffer[CDoom::SCREENWIDTH // 2 - 2 - i + y * CDoom::SCREENWIDTH] = 4
        CDoom.screen_buffer[CDoom::SCREENWIDTH // 2 + 2 + i + y * CDoom::SCREENWIDTH] = 4
      end
      2.times do |i|
        CDoom.screen_buffer[CDoom::SCREENWIDTH // 2 + (y - 2 - i) * CDoom::SCREENWIDTH] = 4
        CDoom.screen_buffer[CDoom::SCREENWIDTH // 2 + (y + 2 + i) * CDoom::SCREENWIDTH] = 4
      end
    end

    if channels == 1
      return CDoom.screen_buffer
    elsif channels == 3
      (CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).times do |i|
        k = i * 3
        kpal = CDoom.screen_buffer[i] * 3
        CDoom.final_screen_buffer[k + 0] = CDoom.screen_palette[kpal + 0]
        CDoom.final_screen_buffer[k + 1] = CDoom.screen_palette[kpal + 1]
        CDoom.final_screen_buffer[k + 2] = CDoom.screen_palette[kpal + 2]
      end
      return CDoom.final_screen_buffer
    elsif channels == 4
      (CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).times do |i|
        k = i * 4
        kpal = CDoom.screen_buffer[i].to_i32 * 3
        CDoom.final_screen_buffer[k + 0] = CDoom.screen_palette[kpal + 0]
        CDoom.final_screen_buffer[k + 1] = CDoom.screen_palette[kpal + 1]
        CDoom.final_screen_buffer[k + 2] = CDoom.screen_palette[kpal + 2]
        CDoom.final_screen_buffer[k + 3] = 255
      end
      return CDoom.final_screen_buffer
    end
    return Pointer(UInt8).null
  end

  def self.doom_tick_midi : LibC::ULong
    return CDoom.i_tick_song
  end

  def self.doom_get_sound_buffer : Int16*
    CDoom.i_update_sound
    return CDoom.mixbuffer.to_unsafe
  end

  def self.doom_key_down(key : CDoom::DoomKey)
    event = CDoom::Event.new
    event.type = CDoom::Evtype::Keydown
    event.data1 = key.value
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_key_up(key : CDoom::DoomKey)
    event = CDoom::Event.new
    event.type = CDoom::Evtype::Keyup
    event.data1 = key.value
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_button_down(button : CDoom::DoomButton)
    CDoom.button_states[button.value] = 1

    event = CDoom::Event.new
    event.type = CDoom::Evtype::Mouse
    event.data1 =
      (CDoom.button_states[0]) |
        (CDoom.button_states[1] != 0 ? 2 : 0) |
        (CDoom.button_states[2] != 0 ? 4 : 0)
    event.data2 = 0
    event.data3 = 0
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_button_up(button : CDoom::DoomButton)
    CDoom.button_states[button.value] = 0

    event = CDoom::Event.new
    event.type = CDoom::Evtype::Mouse
    event.data1 =
      (CDoom.button_states[0]) |
        (CDoom.button_states[1] != 0 ? 2 : 0) |
        (CDoom.button_states[2] != 0 ? 4 : 0)

    event.data1 =
      event.data1 ^
        (CDoom.button_states[0]) ^
        (CDoom.button_states[1] != 0 ? 2 : 0) ^
        (CDoom.button_states[2] != 0 ? 4 : 0)

    event.data2 = 0
    event.data3 = 0
    CDoom.d_post_event(pointerof(event))
  end

  def self.doom_mouse_move(delta_x : Int32, delta_y : Int32)
    event = CDoom::Event.new
    event.type = CDoom::Evtype::Mouse
    event.data1 =
      (CDoom.button_states[0]) |
        (CDoom.button_states[1] != 0 ? 2 : 0) |
        (CDoom.button_states[2] != 0 ? 4 : 0)
    event.data2 = delta_x
    event.data3 = -delta_y

    CDoom.d_post_event(pointerof(event)) if event.data2 != 0 || event.data3 != 0
  end

  def self.am_activate_new_scale
    CDoom.m_x += CDoom.m_w // 2
    CDoom.m_y += CDoom.m_h // 2
    CDoom.m_w = ftom(CDoom.f_w)
    CDoom.m_h = ftom(CDoom.f_h)
    CDoom.m_x -= CDoom.m_w // 2
    CDoom.m_y -= CDoom.m_h // 2
    CDoom.m_x2 = CDoom.m_x + CDoom.m_w
    CDoom.m_y2 = CDoom.m_y + CDoom.m_h
  end

  def self.am_save_scale_and_loc
    CDoom.old_m_x = CDoom.m_x
    CDoom.old_m_y = CDoom.m_y
    CDoom.old_m_w = CDoom.m_w
    CDoom.old_m_h = CDoom.m_h
  end

  def self.am_restore_scale_and_loc
    CDoom.m_w = CDoom.old_m_w
    CDoom.m_h = CDoom.old_m_h
    if CDoom.followplayer == 0
      CDoom.m_x = CDoom.old_m_x
      CDoom.m_y = CDoom.old_m_y
    else
      CDoom.m_x = CDoom.plr.value.mo.value.x - CDoom.m_w // 2
      CDoom.m_y = CDoom.plr.value.mo.value.y - CDoom.m_h // 2
    end
    CDoom.m_x2 = CDoom.m_x + CDoom.m_w
    CDoom.m_y2 = CDoom.m_y + CDoom.m_h

    # Change the scaling multipliers
    CDoom.scale_mtof = CDoom.fixed_div(CDoom.f_w << CDoom::FRACBITS, CDoom.m_w)
    CDoom.scale_ftom = CDoom.fixed_div(CDoom::FRACUNIT, CDoom.scale_mtof)
  end

  #
  # adds a marker at the current location
  #
  def self.am_add_mark
    (CDoom.markpoints.to_unsafe.as(CDoom::Mpoint*) + CDoom.markpointnum).value.x = CDoom.m_x + CDoom.m_w // 2
    (CDoom.markpoints.to_unsafe.as(CDoom::Mpoint*) + CDoom.markpointnum).value.y = CDoom.m_y + CDoom.m_h // 2
    CDoom.markpointnum = (CDoom.markpointnum + 1) % CDoom::AM_NUMMARKPOINTS
  end

  #
  # Determines bounding box of all vertices,
  # sets global variables controlling zoom range.
  #
  def self.am_find_min_max_boundaries
    CDoom.min_x = Int32::MAX
    CDoom.min_y = Int32::MAX
    CDoom.max_x = -Int32::MAX
    CDoom.max_y = -Int32::MAX

    CDoom.numvertexes.times do |i|
      if CDoom.vertexes[i].x < CDoom.min_x
        CDoom.min_x = CDoom.vertexes[i].x
      elsif CDoom.vertexes[i].x > CDoom.max_x
        CDoom.max_x = CDoom.vertexes[i].x
      end

      if CDoom.vertexes[i].y < CDoom.min_y
        CDoom.min_y = CDoom.vertexes[i].y
      elsif CDoom.vertexes[i].y > CDoom.max_y
        CDoom.max_y = CDoom.vertexes[i].y
      end
    end

    CDoom.max_w = CDoom.max_x - CDoom.min_x
    CDoom.max_h = CDoom.max_y - CDoom.min_y

    CDoom.min_w = 2 * CDoom::PLAYERRADIUS # const? never changed?
    CDoom.min_h = 2 * CDoom::PLAYERRADIUS

    a = CDoom.fixed_div(CDoom.f_w << CDoom::FRACBITS, CDoom.max_w)
    b = CDoom.fixed_div(CDoom.f_h << CDoom::FRACBITS, CDoom.max_h)

    CDoom.min_scale_mtof = a < b ? a : b
    CDoom.max_scale_mtof = CDoom.fixed_div(CDoom.f_h << CDoom::FRACBITS, 2 * CDoom::PLAYERRADIUS)
  end

  def self.am_change_window_loc
    if CDoom.m_paninc.x != 0 || CDoom.m_paninc.y != 0
      CDoom.followplayer = 0
      CDoom.f_oldloc.x = Int32::MAX
    end

    CDoom.m_x += CDoom.m_paninc.x
    CDoom.m_y += CDoom.m_paninc.y

    if CDoom.m_x + CDoom.m_w // 2 > CDoom.max_x
      CDoom.m_x = CDoom.max_x - CDoom.m_w // 2
    elsif CDoom.m_x + CDoom.m_w // 2 < CDoom.min_x
      CDoom.m_x = CDoom.min_x - CDoom.m_w // 2
    end

    if CDoom.m_y + CDoom.m_h // 2 > CDoom.max_y
      CDoom.m_y = CDoom.max_y - CDoom.m_h // 2
    elsif CDoom.m_y + CDoom.m_h // 2 < CDoom.min_y
      CDoom.m_y = CDoom.min_y - CDoom.m_h // 2
    end

    CDoom.m_x2 = CDoom.m_x + CDoom.m_w
    CDoom.m_y2 = CDoom.m_y + CDoom.m_h
  end

  def self.am_init_variables
    @@st_notify.type = CDoom::Evtype::Keyup
    @@st_notify.data1 = CDoom::AM_MSGENTERED

    CDoom.automapactive = 1
    CDoom.fb = CDoom.screens[0]
    CDoom.f_oldloc.x = Int32::MAX
    CDoom.amclock = 0
    CDoom.lightlev = 0

    CDoom.m_paninc.x = 0
    CDoom.m_paninc.y = 0
    CDoom.ftom_zoommul = CDoom::FRACUNIT
    CDoom.mtof_zoommul = CDoom::FRACUNIT

    CDoom.m_w = ftom(CDoom.f_w)
    CDoom.m_h = ftom(CDoom.f_h)

    pnum = CDoom.consoleplayer
    # find player to center on initially
    if CDoom.playeringame[pnum] == 0
      CDoom::MAXPLAYERS.times do |i|
        pnum = i
        break if CDoom.playeringame[pnum] != 0
      end
    end

    CDoom.plr = CDoom.players.to_unsafe.as(CDoom::Player*) + pnum
    CDoom.m_x = CDoom.plr.value.mo.value.x - CDoom.m_w // 2
    CDoom.m_y = CDoom.plr.value.mo.value.y - CDoom.m_h // 2
    CDoom.am_change_window_loc

    # for saving & restoring
    CDoom.old_m_x = CDoom.m_x
    CDoom.old_m_y = CDoom.m_y
    CDoom.old_m_w = CDoom.m_w
    CDoom.old_m_h = CDoom.m_h

    # inform the status bar of the change
    CDoom.st_responder(pointerof(@@st_notify))
  end

  def self.am_load_pics
    namebuf = Pointer(UInt8).malloc(9)

    10.times do |i|
      CDoom.doom_concat(CDoom.doom_strcpy(namebuf, "AMMNUM"), CDoom.doom_itoa(i, 10))
      CDoom.marknums[i] = CDoom.w_cache_lump_name(namebuf, CDoom::PU_STATIC).as(CDoom::Patch*)
    end
  end

  def self.am_unload_pics
    10.times { |i| z_change_tag(CDoom.marknums[i], CDoom::PU_CACHE) }
  end

  def self.am_clear_marks
    CDoom::AM_NUMMARKPOINTS.times do |i|
      (CDoom.markpoints.to_unsafe.as(CDoom::Mpoint*) + i).value.x = -1
    end
    CDoom.markpointnum = 0
  end

  #
  # should be called at the start of every level
  # right now, i figure it out myself
  #
  def self.am_level_init
    CDoom.leveljuststarted = 0

    CDoom.f_x = 0
    CDoom.f_y = 0
    CDoom.f_w = CDoom.finit_width
    CDoom.f_h = CDoom.finit_height

    CDoom.am_clear_marks

    CDoom.am_find_min_max_boundaries
    CDoom.scale_mtof = CDoom.fixed_div(CDoom.min_scale_mtof, (0.7 * CDoom::FRACUNIT).to_i32!)
    CDoom.scale_mtof = CDoom.min_scale_mtof if CDoom.scale_mtof > CDoom.max_scale_mtof
    CDoom.scale_ftom = CDoom.fixed_div(CDoom::FRACUNIT, CDoom.scale_mtof)
  end

  def self.am_stop
    @@st_notify.type = CDoom::Evtype.new(0)
    @@st_notify.data1 = CDoom::Evtype::Keyup.value
    @@st_notify.data2 = CDoom::AM_MSGENTERED

    CDoom.am_unload_pics
    CDoom.automapactive = 0
    CDoom.st_responder(pointerof(@@st_notify))
    CDoom.stopped = 1
  end

  def self.am_start
    CDoom.am_stop if CDoom.stopped == 0
    CDoom.stopped = 0
    if @@lastlevel != CDoom.gamemap || @@lastepisode != CDoom.gameepisode
      CDoom.am_level_init
      @@lastlevel = CDoom.gamemap
      @@lastepisode = CDoom.gameepisode
    end
    CDoom.am_init_variables
    CDoom.am_load_pics
  end

  #
  # set the window scale to the maximum size
  #
  def self.am_min_out_window_scale
    CDoom.scale_mtof = CDoom.min_scale_mtof
    CDoom.scale_ftom = CDoom.fixed_div(CDoom::FRACUNIT, CDoom.scale_mtof)
    CDoom.am_activate_new_scale
  end

  #
  # set the window scale to the minimum size
  #
  def self.am_max_out_window_scale
    CDoom.scale_mtof = CDoom.max_scale_mtof
    CDoom.scale_ftom = CDoom.fixed_div(CDoom::FRACUNIT, CDoom.scale_mtof)
    CDoom.am_activate_new_scale
  end

  #
  # Handle events (user inputs) in automap mode
  #
  def self.am_responder(ev : CDoom::Event*) : CDoom::DoomBool
    rc = 0

    if CDoom.automapactive == 0
      if ev.value.type == CDoom::Evtype::Keydown && ev.value.data1 == CDoom::AM_STARTKEY
        CDoom.am_start
        CDoom.viewactive = 0
        rc = 1
      end
    elsif ev.value.type == CDoom::Evtype::Keydown
      rc = 1
      case ev.value.data1
      when CDoom::AM_PANRIGHTKEY # pan right
        if CDoom.followplayer == 0
          CDoom.m_paninc.x = ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANLEFTKEY # pan left
        if CDoom.followplayer == 0
          CDoom.m_paninc.x = -ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANUPKEY # pan up
        if CDoom.followplayer == 0
          CDoom.m_paninc.y = ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_PANDOWNKEY # pan down
        if CDoom.followplayer == 0
          CDoom.m_paninc.y = -ftom(CDoom::F_PANINC)
        else
          rc = 0
        end
      when CDoom::AM_ZOOMOUTKEY # zoom out
        CDoom.mtof_zoommul = CDoom::M_ZOOMOUT
        CDoom.ftom_zoommul = CDoom::M_ZOOMIN
      when CDoom::AM_ZOOMINKEY # zoom in
        CDoom.mtof_zoommul = CDoom::M_ZOOMIN
        CDoom.ftom_zoommul = CDoom::M_ZOOMOUT
      when CDoom::AM_ENDKEY
        @@bigstate = 0
        CDoom.viewactive = 1
        CDoom.am_stop
      when CDoom::AM_GOBIGKEY
        @@bigstate = @@bigstate != 0 ? 0 : 1
        if @@bigstate != 0
          CDoom.am_save_scale_and_loc
          CDoom.am_min_out_window_scale
        else
          CDoom.am_restore_scale_and_loc
        end
      when CDoom::AM_FOLLOWKEY
        CDoom.followplayer = CDoom.followplayer != 0 ? 0 : 1
        CDoom.f_oldloc.x = Int32::MAX
        CDoom.plr.value.message = CDoom.followplayer != 0 ? CDoom::AMSTR_FOLLOWON : CDoom::AMSTR_FOLLOWOFF
      when CDoom::AM_GRIDKEY
        CDoom.grid = CDoom.grid != 0 ? 0 : 1
        CDoom.plr.value.message = CDoom.grid != 0 ? CDoom::AMSTR_GRIDON : CDoom::AMSTR_GRIDOFF
      when CDoom::AM_MARKKEY
        CDoom.doom_strcpy(@@buffer, CDoom::AMSTR_MARKEDSPOT)
        CDoom.doom_concat(@@buffer, " ")
        CDoom.doom_concat(@@buffer, CDoom.doom_itoa(CDoom.markpointnum, 10))
        CDoom.plr.value.message = @@buffer
        CDoom.am_add_mark
      when CDoom::AM_CLEARMARKKEY
        CDoom.am_clear_marks
        CDoom.plr.value.message = CDoom::AMSTR_MARKSCLEARED
      else
        @@cheatstate = 0
        rc = 0
      end
      if CDoom.deathmatch == 0 && CDoom.cht_check_cheat(pointerof(CDoom.cheat_amap), ev.value.data1) != 0
        rc = 0
        CDoom.cheating = (CDoom.cheating + 1) % 3
      end
    elsif ev.value.type == CDoom::Evtype::Keyup
      rc = 0
      case ev.value.data1
      when CDoom::AM_PANRIGHTKEY
        CDoom.m_paninc.x = 0 if CDoom.followplayer == 0
      when CDoom::AM_PANLEFTKEY
        CDoom.m_paninc.x = 0 if CDoom.followplayer == 0
      when CDoom::AM_PANUPKEY
        CDoom.m_paninc.y = 0 if CDoom.followplayer == 0
      when CDoom::AM_PANDOWNKEY
        CDoom.m_paninc.y = 0 if CDoom.followplayer == 0
      when CDoom::AM_ZOOMOUTKEY, CDoom::AM_ZOOMINKEY
        CDoom.mtof_zoommul = CDoom::FRACUNIT
        CDoom.ftom_zoommul = CDoom::FRACUNIT
      end
    end

    return rc
  end

  #
  # Zooming
  #
  def self.am_change_window_scale
    # Change the scaling multipliers
    CDoom.scale_mtof = CDoom.fixed_mul(CDoom.scale_mtof, CDoom.mtof_zoommul)
    CDoom.scale_ftom = CDoom.fixed_div(CDoom::FRACUNIT, CDoom.scale_mtof)

    if CDoom.scale_mtof < CDoom.min_scale_mtof
      CDoom.am_min_out_window_scale
    elsif CDoom.scale_mtof > CDoom.max_scale_mtof
      CDoom.am_max_out_window_scale
    else
      CDoom.am_activate_new_scale
    end
  end

  def self.am_do_follow_player
    if CDoom.f_oldloc.x != CDoom.plr.value.mo.value.x || CDoom.f_oldloc.y != CDoom.plr.value.mo.value.y
      CDoom.m_x = ftom(mtof(CDoom.plr.value.mo.value.x)) - CDoom.m_w // 2
      CDoom.m_y = ftom(mtof(CDoom.plr.value.mo.value.y)) - CDoom.m_h // 2
      CDoom.m_x2 = CDoom.m_x + CDoom.m_w
      CDoom.m_y2 = CDoom.m_y + CDoom.m_h
      CDoom.f_oldloc.x = CDoom.plr.value.mo.value.x
      CDoom.f_oldloc.y = CDoom.plr.value.mo.value.y
    end
  end

  def self.am_update_light_lev
    # Change light level
    if CDoom.amclock > @@nexttic
      CDoom.lightlev = @@litelevels[@@litelevelscnt]
      @@litelevelscnt += 1
      @@litelevelscnt = 0 if @@litelevelscnt == @@litelevels.size
      @@nexttic = CDoom.amclock + 6 - (CDoom.amclock % 6)
    end
  end

  #
  # Updates on Game Tick
  #
  def self.am_ticker
    return if CDoom.automapactive == 0

    CDoom.amclock += 1

    CDoom.am_do_follow_player if CDoom.followplayer != 0

    # Change the zoom if necessary
    CDoom.am_change_window_scale if CDoom.ftom_zoommul != CDoom::FRACUNIT

    # Change x,y location
    CDoom.am_change_window_loc if CDoom.m_paninc.x != 0 || CDoom.m_paninc.y != 0

    # Update light level
    # CDoom.am_update_light_lev
  end

  #
  # Clear automap frame buffer.
  #
  def self.am_clear_fb(color : Int32)
    CDoom.doom_memset(CDoom.fb, color, CDoom.f_w * CDoom.f_h)
  end

  LEFT   = 1
  RIGHT  = 2
  BOTTOM = 4
  TOP    = 8

  macro dooutcode(oc, mx, my)
    {{oc}} = 0
    if ({{my}} < 0)
      {{oc}} |= TOP
    elsif ({{my}} >= CDoom.f_h)
      {{oc}} |= BOTTOM
    end
    if ({{mx}} < 0)
      {{oc}} |= LEFT
    elsif ({{mx}} >= CDoom.f_w)
      {{oc}} |= RIGHT
    end
  end

  #
  # Automap clipping of lines.
  #
  # Based on Cohen-Sutherland clipping algorithm but with a slightly
  # faster reject and precalculated slopes.  If the speed is needed,
  # use a hash algorithm to handle  the common cases.
  #
  def self.am_clip_mline(ml : CDoom::Mline*, fl : CDoom::Fline*) : CDoom::DoomBool
    outcode1 = 0
    outcode2 = 0
    outside = 0

    tmp = CDoom::Fpoint.new
    dx = 0
    dy = 0

    # do trivial rejects and outcodes
    if ml.value.a.y > CDoom.m_y2
      outcode1 = TOP
    elsif ml.value.a.y < CDoom.m_y
      outcode1 = BOTTOM
    end

    if ml.value.b.y > CDoom.m_y2
      outcode2 = TOP
    elsif ml.value.b.y < CDoom.m_y
      outcode2 = BOTTOM
    end

    return 0 if (outcode1 & outcode2) != 0 # trivially outside

    if ml.value.a.x < CDoom.m_x
      outcode1 |= LEFT
    elsif ml.value.a.x > CDoom.m_x2
      outcode1 |= RIGHT
    end

    if ml.value.b.x < CDoom.m_x
      outcode2 |= LEFT
    elsif ml.value.b.x > CDoom.m_x2
      outcode2 |= RIGHT
    end

    return 0 if (outcode1 & outcode2) != 0 # trivially outside

    # transform to frame-buffer coodinates.
    fl.value.a.x = cxmtof(ml.value.a.x)
    fl.value.a.y = cymtof(ml.value.a.y)
    fl.value.b.x = cxmtof(ml.value.b.x)
    fl.value.b.y = cymtof(ml.value.b.y)

    dooutcode(outcode1, fl.value.a.x, fl.value.a.y)
    dooutcode(outcode2, fl.value.b.x, fl.value.b.y)

    return 0 if (outcode1 & outcode2) != 0

    while (outcode1 | outcode2) != 0
      # may be partially inside box
      # find an outside point
      if outcode1 != 0
        outside = outcode1
      else
        outside = outcode2
      end

      # clip to each side
      if outside & TOP != 0
        dy = fl.value.a.y - fl.value.b.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.x = fl.value.a.x + (dx * fl.value.a.y) // dy
        tmp.y = 0
      elsif outside & BOTTOM != 0
        dy = fl.value.a.y - fl.value.b.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.x = fl.value.a.x + (dx * (fl.value.a.y - CDoom.f_h)) // dy
        tmp.y = CDoom.f_h - 1
      elsif outside & RIGHT != 0
        dy = fl.value.b.y - fl.value.a.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.y = fl.value.a.y + (dy * (CDoom.f_w - 1 - fl.value.a.x)) // dx
        tmp.x = CDoom.f_w - 1
      elsif outside & LEFT != 0
        dy = fl.value.b.y - fl.value.a.y
        dx = fl.value.b.x - fl.value.a.x
        tmp.y = fl.value.a.y + (dy * (-fl.value.a.x)) // dx
        tmp.x = 0
      end

      if outside == outcode1
        fl.value.a = tmp
        dooutcode(outcode1, fl.value.a.x, fl.value.a.y)
      else
        fl.value.b = tmp
        dooutcode(outcode2, fl.value.b.x, fl.value.b.y)
      end

      return 0 if (outcode1 & outcode2) != 0 # trivially outside
    end

    return 1
  end

  macro putdot(xx, yy, cc)
    CDoom.fb[{{yy}}*CDoom.f_w+{{xx}}]={{cc}}
  end

  @@fuck = 0

  #
  # Classic Bresenham w/ whatever optimizations needed for speed
  #
  def self.am_draw_fline(fl : CDoom::Fline*, color : Int32)
    x = 0
    y = 0
    dx = 0
    dy = 0
    sx = 0
    sy = 0
    ax = 0
    ay = 0
    d = 0

    # For debugging only
    {% if false %}
      # [pd] Don't waste CPU cycles testing this then
      if (fl.value.a.x < 0 || fl.value.a.x >= CDoom.f_w ||
         fl.value.a.y < 0 || fl.value.a.y >= CDoom.f_h ||
         fl.value.b.x < 0 || fl.value.b.x >= CDoom.f_w ||
         fl.value.b.y < 0 || fl.value.b.y >= CDoom.f_h)
        CDoom.doom_print("fuck ")
        CDoom.doom_print(CDoom.doom_itoa(@@fuck, 10))
        @@fuck += 1
        CDoom.doom_print("\r")
        return
      end
    {% end %}

    dx = fl.value.b.x - fl.value.a.x
    ax = 2 * (dx < 0 ? -dx : dx)
    sx = dx < 0 ? -1 : 1

    dy = fl.value.b.y - fl.value.a.y
    ay = 2 * (dy < 0 ? -dy : dy)
    sy = dy < 0 ? -1 : 1

    x = fl.value.a.x
    y = fl.value.a.y

    if ax > ay
      d = ay - ax // 2
      while true
        putdot(x, y, color.to_u8!)
        return if x == fl.value.b.x
        if d >= 0
          y += sy
          d -= ax
        end
        x += sx
        d += ay
      end
    else
      d = ax - ay // 2
      while true
        putdot(x, y, color.to_u8!)
        return if y == fl.value.b.y
        if d >= 0
          x += sx
          d -= ay
        end
        y += sy
        d += ax
      end
    end
  end

  @@fl : CDoom::Fline* = Pointer(CDoom::Fline).malloc(1)

  #
  # Clip lines, draw visible part sof lines.
  #
  def self.am_draw_mline(ml : CDoom::Mline*, color : Int32)
    if CDoom.am_clip_mline(ml, @@fl) != 0
      CDoom.am_draw_fline(@@fl, color)
    end
  end


  #
  # Draws flat (floor/ceiling tile) aligned grid lines.
  #
  def self.am_draw_grid(color : Int32)
    # Figure out start of vertical gridlines
    start = CDoom.m_x
    ml = CDoom::Mline.new

    if (start - CDoom.bmaporgx) % (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS)
      start += (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS) -
      ((start - CDoom.bmaporgx) % (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS))
    end
    en = CDoom.m_x + CDoom.m_w

    # draw vertical gridlines
    ml.a.y = CDoom.m_y
    ml.b.y = CDoom.m_y + CDoom.m_h
    x = start
    while x < en
      ml.a.x = x
      ml.b.x = x
      CDoom.am_draw_mline(pointerof(ml), color)
      x += CDoom::MAPBLOCKUNITS << CDoom::FRACBITS
    end

    # Figure out start of horizontal gridlines
    start = CDoom.m_y
    if (start - CDoom.bmaporgy) % (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS)
      start += (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS) - 
      ((start - CDoom.bmaporgy) % (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS))
    end
    en = CDoom.m_y + CDoom.m_h

    # draw horizontal gridlines
    ml.a.x = CDoom.m_x
    ml.b.x = CDoom.m_x + CDoom.m_w
    y = start
    while y < en
      ml.a.y = y
      ml.b.y = y
      CDoom.am_draw_mline(pointerof(ml), color)
      y += (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS)
    end
  end
  
  @@l : CDoom::Mline = CDoom::Mline.new
  #
# Determines visible lines, draws them.
# This is LineDef based, not LineSeg based.
#
  def self.am_draw_walls
    CDoom.numlines.times do |i|
      @@l.a.x = CDoom.lines[i].v1.value.x
      @@l.a.y = CDoom.lines[i].v1.value.y
      @@l.b.x = CDoom.lines[i].v2.value.x
      @@l.b.y = CDoom.lines[i].v2.value.y
      if CDoom.cheating != 0 || (CDoom.lines[i].flags & CDoom::ML_MAPPED) != 0
        next if (CDoom.lines[i].flags & CDoom::LINE_NEVERSEE) != 0 && CDoom.cheating == 0
        if CDoom.lines[i].backsector.null?
          CDoom.am_draw_mline(pointerof(@@l), CDoom::WALLCOLORS + CDoom.lightlev)
        else
          if CDoom.lines[i].special == 39
            # teleporters
            CDoom.am_draw_mline(pointerof(@@l), CDoom::WALLCOLORS + CDoom::WALLRANGE // 2)
          elsif CDoom.lines[i].flags & CDoom::ML_SECRET != 0 # secret door
            if CDoom.cheating != 0
            CDoom.am_draw_mline(pointerof(@@l), CDoom::SECRETWALLCOLORS + CDoom.lightlev)
            else
              CDoom.am_draw_mline(pointerof(@@l), CDoom::WALLCOLORS + CDoom.lightlev)
            end
          elsif CDoom.lines[i].backsector.value.floorheight != CDoom.lines[i].frontsector.value.floorheight
            CDoom.am_draw_mline(pointerof(@@l), CDoom::FDWALLCOLORS + CDoom.lightlev) # floor level change
          elsif CDoom.lines[i].backsector.value.ceilingheight != CDoom.lines[i].frontsector.value.ceilingheight
            CDoom.am_draw_mline(pointerof(@@l), CDoom::CDWALLCOLORS + CDoom.lightlev) # ceiling level change
          elsif CDoom.cheating != 0
            CDoom.am_draw_mline(pointerof(@@l), CDoom::TSWALLCOLORS + CDoom.lightlev)
          end
        end
      elsif CDoom.plr.value.powers[CDoom::Powertype::Allmap.value] != 0
        CDoom.am_draw_mline(pointerof(@@l), CDoom::GRAYS + 3) if CDoom.lines[i].flags & CDoom::LINE_NEVERSEE == 0
      end
    end
  end

  #
# Rotation in 2D.
# Used to rotate player arrow line character.
#
def self.am_rotate(x : CDoom::Fixed*, y : CDoom::Fixed*, a : CDoom::Angle)
  tmpx = CDoom.fixed_mul(x.value, CDoom.finecosine[a >> CDoom::ANGLETOFINESHIFT]) -
  CDoom.fixed_mul(y.value, CDoom.finesine[a >> CDoom::ANGLETOFINESHIFT])

  y.value = CDoom.fixed_mul(x.value, CDoom.finesine[a >> CDoom::ANGLETOFINESHIFT]) +
  CDoom.fixed_mul(y.value, CDoom.finecosine[a >> CDoom::ANGLETOFINESHIFT])

  x.value = tmpx
end


end

