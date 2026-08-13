fun doom_print_impl(str : UInt8*)
  LibDoom.doom_print_impl(str)
end

fun doom_malloc_impl(size : Int32) : Void*
  LibDoom.doom_malloc_impl(size)
end

fun doom_free_impl(ptr : Void*)
  LibDoom.doom_free_impl(ptr)
end

fun doom_open_impl(filename : UInt8*, mode : UInt8*) : Void*
  LibDoom.doom_open_impl(filename, mode)
end
fun doom_close_impl(handle : Void*)
  LibDoom.doom_close_impl(handle)
end
fun doom_read_impl(handle : Void*, buf : Void*, count : Int32) : Int32
  LibDoom.doom_read_impl(handle, buf, count)
end
fun doom_write_impl(handle : Void*, buf : Void*, count : Int32) : Int32
  LibDoom.doom_write_impl(handle, buf, count)
end
fun doom_seek_impl(handle : Void*, offset : Int32, origin : CDoom::DoomSeek) : Int32
  LibDoom.doom_seek_impl(handle, offset, origin)
end
fun doom_tell_impl(handle : Void*) : Int32
  LibDoom.doom_tell_impl(handle)
end
fun doom_eof_impl(handle : Void*) : Int32
  LibDoom.doom_eof_impl(handle)
end

fun doom_gettime_impl(sec : Int32*, usec : Int32*)
  LibDoom.doom_gettime_impl(sec, usec)
end

fun doom_exit_impl(code : Int32)
  LibDoom.doom_exit_impl(code)
end

fun doom_getenv_impl(var : UInt8*) : UInt8*
  LibDoom.doom_getenv_impl(var)
end

fun doom_memset(ptr : Void*, value : Int32, num : Int32)
  LibDoom.doom_memset(ptr, value, num)
end

fun doom_memcpy(destination : Void*, source : Void*, num : Int32) : Void*
  LibDoom.doom_memcpy(destination, source, num)
end

fun doom_strlen(str : UInt8*) : Int32
  LibDoom.doom_strlen(str)
end

fun doom_concat(dst : UInt8*, src : UInt8*) : UInt8*
  LibDoom.doom_concat(dst, src)
end

fun doom_strcpy(dst : UInt8*, src : UInt8*) : UInt8*
  LibDoom.doom_strcpy(dst, src)
end

fun doom_strncpy(dst : UInt8*, src : UInt8*, num : Int32) : UInt8*
  LibDoom.doom_strncpy(dst, src, num)
end

fun doom_strcmp(str1 : UInt8*, str2 : UInt8*) : Int32
  LibDoom.doom_strcmp(str1, str2)
end

fun doom_strncmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
  LibDoom.doom_strncmp(str1, str2, n)
end

fun doom_toupper(c : Int32) : Int32
  LibDoom.doom_toupper(c)
end

fun doom_strcasecmp(str1 : UInt8*, str2 : UInt8*) : Int32
  LibDoom.doom_strcasecmp(str1, str2)
end

fun doom_strncasecmp(str1 : UInt8*, str2 : UInt8*, n : Int32) : Int32
  LibDoom.doom_strncasecmp(str1, str2, n)
end

fun doom_atoi(str : UInt8*) : Int32
  LibDoom.doom_atoi(str)
end

fun doom_atox(str : UInt8*) : Int32
  LibDoom.doom_atox(str)
end

fun doom_itoa(k : Int32, radix : Int32) : UInt8*
  LibDoom.doom_itoa(k, radix)
end

fun doom_ctoa(c : UInt8) : UInt8*
  LibDoom.doom_ctoa(c)
end

fun doom_ptoa(p : Void*) : UInt8*
  LibDoom.doom_ptoa(p)
end

fun doom_fprint(handle : Void*, str : UInt8*) : Int32
  LibDoom.doom_fprint(handle, str)
end

fun get_default(name : UInt8*) : CDoom::Default*
  LibDoom.get_default(name)
end

fun doom_set_resolution(width : Int32, height : Int32)
  LibDoom.doom_set_resolution(width, height)
end

fun doom_set_default_int(name : UInt8*, value : Int32)
  LibDoom.doom_set_default_int(name, value)
end

fun doom_set_default_string(name : UInt8*, value : UInt8*)
  LibDoom.doom_set_default_string(name, value)
end

fun doom_set_print(print_fn : CDoom::DoomPrintFn)
  LibDoom.doom_set_print(print_fn)
end

fun doom_set_malloc(malloc_fn : CDoom::DoomMallocFn, free_fn : CDoom::DoomFreeFn)
  LibDoom.doom_set_malloc(malloc_fn, free_fn)
end

fun doom_set_file_io(open_fn : CDoom::DoomOpenFn,
                     close_fn : CDoom::DoomCloseFn,
                     read_fn : CDoom::DoomReadFn,
                     write_fn : CDoom::DoomWriteFn,
                     seek_fn : CDoom::DoomSeekFn,
                     tell_fn : CDoom::DoomTellFn,
                     eof_fn : CDoom::DoomEofFn)
  LibDoom.doom_set_file_io(open_fn,
    close_fn,
    read_fn,
    write_fn,
    seek_fn,
    tell_fn,
    eof_fn)
end

fun doom_set_gettime(gettime_fn : CDoom::DoomGettimeFn)
  LibDoom.doom_set_gettime(gettime_fn)
end

fun doom_set_exit(exit_fn : CDoom::DoomExitFn)
  LibDoom.doom_set_exit(exit_fn)
end

fun doom_set_getenv(getenv_fn : CDoom::DoomGetenvFn)
  LibDoom.doom_set_getenv(getenv_fn)
end

fun doom_init(argc : Int32, argv : UInt8**, flags : Int32)
  LibDoom.doom_init(argc, argv, flags)
end

fun doom_update
  LibDoom.doom_update
end

fun doom_force_update
  LibDoom.doom_force_update
end

fun doom_get_framebuffer(channels : Int32) : UInt8*
  LibDoom.doom_get_framebuffer(channels)
end

fun doom_tick_midi : LibC::ULong
  LibDoom.doom_tick_midi
end

fun doom_get_sound_buffer : Int16*
  LibDoom.doom_get_sound_buffer
end

fun doom_key_down(key : CDoom::DoomKey)
  LibDoom.doom_key_down(key)
end

fun doom_key_up(key : CDoom::DoomKey)
  LibDoom.doom_key_up(key)
end

fun doom_button_down(button : CDoom::DoomButton)
  LibDoom.doom_button_down(button)
end

fun doom_button_up(button : CDoom::DoomButton)
  LibDoom.doom_button_up(button)
end

fun doom_mouse_move(delta_x : Int32, delta_y : Int32)
  LibDoom.doom_mouse_move(delta_x, delta_y)
end

fun am_activate_new_scale = AM_activateNewScale
  LibDoom.am_activate_new_scale
end

fun am_save_scale_and_loc = AM_saveScaleAndLoc
  LibDoom.am_save_scale_and_loc
end

fun am_restore_scale_and_loc = AM_restoreScaleAndLoc
  LibDoom.am_restore_scale_and_loc
end

#
# adds a marker at the current location
#
fun am_add_mark = AM_addMark
  LibDoom.am_add_mark
end

#
# Determines bounding box of all vertices,
# sets global variables controlling zoom range.
#
fun am_find_min_max_boundaries = AM_findMinMaxBoundaries
  LibDoom.am_find_min_max_boundaries
end

fun am_change_window_loc = AM_changeWindowLoc
  LibDoom.am_change_window_loc
end

fun am_init_variables = AM_initVariables
  LibDoom.am_init_variables
end

fun am_load_pics = AM_loadPics
  LibDoom.am_load_pics
end

fun am_unload_pics = AM_unloadPics
  LibDoom.am_unload_pics
end

fun am_clear_marks = AM_clearMarks
  LibDoom.am_clear_marks
end

#
# should be called at the start of every level
# right now, i figure it out myself
#
fun am_level_init = AM_LevelInit
  LibDoom.am_level_init
end

fun am_stop = AM_Stop
  LibDoom.am_stop
end

fun am_start = AM_Start
  LibDoom.am_start
end

#
# set the window scale to the maximum size
#
fun am_min_out_window_scale = AM_minOutWindowScale
  LibDoom.am_min_out_window_scale
end

fun am_max_out_window_scale = AM_maxOutWindowScale
  LibDoom.am_max_out_window_scale
end

fun am_responder = AM_Responder(ev : CDoom::Event*) : CDoom::DoomBool
  LibDoom.am_responder(ev)
end

fun am_change_window_scale = AM_changeWindowScale
  LibDoom.am_change_window_scale
end

fun am_do_follow_player = AM_doFollowPlayer
  LibDoom.am_do_follow_player
end

fun am_update_light_lev = AM_updateLightLev
  LibDoom.am_update_light_lev
end

fun am_ticker = AM_Ticker
  LibDoom.am_ticker
end

fun am_clear_fb = AM_clearFB(color : LibC::Int)
  LibDoom.am_clear_fb(color)
end

fun am_clip_mline = AM_clipMline(ml : CDoom::Mline*, fl : CDoom::Fline*) : CDoom::DoomBool
  LibDoom.am_clip_mline(ml, fl)
end

fun am_draw_fline = AM_drawFline(fl : CDoom::Fline*, color : LibC::Int)
  LibDoom.am_draw_fline(fl, color)
end

fun am_draw_mline = AM_drawMline(ml : CDoom::Mline*, color : LibC::Int)
  LibDoom.am_draw_mline(ml, color)
end

fun am_draw_grid = AM_drawGrid(color : Int32)
  LibDoom.am_draw_grid(color)
end

fun am_draw_walls = AM_drawWalls
  LibDoom.am_draw_walls
end

fun am_rotate = AM_rotate(x : CDoom::Fixed*, y : CDoom::Fixed*, a : CDoom::Angle)
  LibDoom.am_rotate(x, y, a)
end

fun am_draw_line_character = AM_drawLineCharacter(lineguy : CDoom::Mline*,
                                                  lineguylines : LibC::Int,
                                                  scale : CDoom::Fixed,
                                                  angle : CDoom::Angle,
                                                  color : LibC::Int,
                                                  x : CDoom::Fixed,
                                                  y : CDoom::Fixed)
  LibDoom.am_draw_line_character(lineguy,
    lineguylines,
    scale,
    angle,
    color,
    x,
    y)
end

fun am_draw_players = AM_drawPlayers
  LibDoom.am_draw_players
end

fun am_draw_things = AM_drawThings(colors : LibC::Int, colorrange : LibC::Int)
  LibDoom.am_draw_things(colors, colorrange)
end

fun am_draw_marks = AM_drawMarks
  LibDoom.am_draw_marks
end

fun am_draw_crosshair = AM_drawCrosshair(color : LibC::Int)
  LibDoom.am_draw_crosshair(color)
end

fun am_drawer = AM_Drawer
  LibDoom.am_drawer
end

fun d_post_event = D_PostEvent(ev : CDoom::Event*)
  LibDoom.d_post_event(ev)
end

fun d_process_events = D_ProcessEvents
  LibDoom.d_process_events
end

fun d_display = D_Display
  LibDoom.d_display
end

fun d_update_wipe = D_UpdateWipe
  LibDoom.d_update_wipe
end

fun d_doom_loop = D_DoomLoop
  LibDoom.d_doom_loop
end

fun d_page_ticker = D_PageTicker
  LibDoom.d_page_ticker
end

fun d_page_drawer = D_PageDrawer
  LibDoom.d_page_drawer
end

fun d_advance_demo = D_AdvanceDemo
  LibDoom.d_advance_demo
end

fun d_do_advance_demo = D_DoAdvanceDemo
  LibDoom.d_do_advance_demo
end

fun d_start_title = D_StartTitle
  LibDoom.d_start_title
end

fun d_add_file = D_AddFile(file : LibC::Char*)
  LibDoom.d_add_file(file)
end

fun identify_version = IdentifyVersion
  LibDoom.identify_version
end

fun find_response_file = FindResponseFile
  LibDoom.find_response_file
end

fun d_doom_main = D_DoomMain
  LibDoom.d_doom_main
end

fun net_buffer_size = NetBufferSize : LibC::Int
  LibDoom.net_buffer_size
end

fun net_buffer_checksum = NetbufferChecksum : LibC::UInt
  LibDoom.net_buffer_checksum
end

fun expand_tics = ExpandTics(low : LibC::Int) : LibC::Int
  LibDoom.expand_tics(low)
end

fun h_send_packet = HSendPacket(node : LibC::Int, flags : LibC::Int)
  LibDoom.h_send_packet(node, flags)
end

fun h_get_packet = HGetPacket : CDoom::DoomBool
  LibDoom.h_get_packet
end

fun get_packets = GetPackets
  LibDoom.get_packets
end

fun net_update = NetUpdate
  LibDoom.net_update
end

fun check_abort = CheckAbort
  LibDoom.check_abort
end

fun d_arbitrate_net_start = D_ArbitrateNetStart
  LibDoom.d_arbitrate_net_start
end

fun d_check_net_game = D_CheckNetGame
  LibDoom.d_check_net_game
end

fun d_quit_net_game = D_QuitNetGame
  LibDoom.d_quit_net_game
end

fun try_run_tics = TryRunTics
  LibDoom.try_run_tics
end
