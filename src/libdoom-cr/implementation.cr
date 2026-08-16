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

fun f_start_finale = F_StartFinale
  LibDoom.f_start_finale
end

fun f_responder = F_Responder(event : CDoom::Event*) : CDoom::DoomBool
  LibDoom.f_responder(event)
end

fun f_ticker = F_Ticker
  LibDoom.f_ticker
end

fun f_text_write = F_TextWrite
  LibDoom.f_text_write
end

fun f_start_cast = F_StartCast
  LibDoom.f_start_cast
end

fun f_cast_ticker = F_CastTicker
  LibDoom.f_cast_ticker
end

fun f_cast_responder = F_CastResponder(ev : CDoom::Event*) : CDoom::DoomBool
  LibDoom.f_cast_responder(ev)
end

fun f_cast_print = F_CastPrint(text : LibC::Char*)
  LibDoom.f_cast_print(text)
end

fun f_cast_drawer = F_CastDrawer
  LibDoom.f_cast_drawer
end

fun f_draw_patch_col = F_DrawPatchCol(x : LibC::Int, patch : CDoom::Patch*, col : LibC::Int)
  LibDoom.f_draw_patch_col(x, patch, col)
end

fun f_bunny_scroll = F_BunnyScroll
  LibDoom.f_bunny_scroll
end

fun f_drawer = F_Drawer
  LibDoom.f_drawer
end

fun wipe_shitty_col_major_x_form = wipe_shittyColMajorXform(array : LibC::Short*, width : LibC::Int, height : LibC::Int)
  LibDoom.wipe_shitty_col_major_x_form(array, width, height)
end

fun wipe_init_color_x_form = wipe_initColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  LibDoom.wipe_init_color_x_form(width, height, ticks)
end

fun wipe_do_color_x_form = wipe_doColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  LibDoom.wipe_do_color_x_form(width, height, ticks)
end

fun wipe_exit_color_x_form = wipe_exitColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  LibDoom.wipe_exit_color_x_form(width, height, ticks)
end

fun wipe_init_melt = wipe_initMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  LibDoom.wipe_init_melt(width, height, ticks)
end

fun wipe_do_melt = wipe_doMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  LibDoom.wipe_do_melt(width, height, ticks)
end

fun wipe_exit_melt = wipe_exitMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  LibDoom.wipe_exit_melt(width, height, ticks)
end

fun wipe_start_screen = wipe_StartScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  LibDoom.wipe_start_screen(x, y, width, height)
end

fun wipe_end_screen = wipe_EndScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  LibDoom.wipe_end_screen(x, y, width, height)
end

fun wipe_screen_wipe = wipe_ScreenWipe(wipeno : LibC::Int, x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int
  LibDoom.wipe_screen_wipe(wipeno, x, y, width, height, ticks)
end

fun g_build_ticcmd = G_BuildTiccmd(cmd : CDoom::Ticcmd*)
  LibDoom.g_build_ticcmd(cmd)
end

fun g_do_load_level = G_DoLoadLevel
  LibDoom.g_do_load_level
end

fun g_responder = G_Responder(ev : CDoom::Event*) : CDoom::DoomBool
  LibDoom.g_responder(ev)
end

fun g_ticker = G_Ticker
  LibDoom.g_ticker
end

fun g_init_player = G_InitPlayer(player : LibC::Int)
  LibDoom.g_init_player(player)
end

fun g_player_finish_level = G_PlayerFinishLevel(player : LibC::Int)
  LibDoom.g_player_finish_level(player)
end

fun g_player_reborn = G_PlayerReborn(player : LibC::Int)
  LibDoom.g_player_reborn(player)
end

fun g_check_spot = G_CheckSpot(playernum : LibC::Int, mthing : CDoom::Mapthing*) : CDoom::DoomBool
  LibDoom.g_check_spot(playernum, mthing)
end

fun g_deathmatch_spawn_player = G_DeathMatchSpawnPlayer(playernum : LibC::Int)
  LibDoom.g_deathmatch_spawn_player(playernum)
end

fun g_do_reborn = G_DoReborn(playernum : LibC::Int)
  LibDoom.g_do_reborn(playernum)
end

fun g_screenshot = G_ScreenShot
  LibDoom.g_screenshot
end

fun g_exit_level = G_ExitLevel
  LibDoom.g_exit_level
end

fun g_secret_exit_level = G_SecretExitLevel
  LibDoom.g_secret_exit_level
end

fun g_do_completed = G_DoCompleted
  LibDoom.g_do_completed
end

fun g_world_done = G_WorldDone
  LibDoom.g_world_done
end

fun g_do_world_done = G_DoWorldDone
  LibDoom.g_do_world_done
end

fun g_load_game = G_LoadGame(name : LibC::Char*)
  LibDoom.g_load_game(name)
end

fun g_do_load_game = G_DoLoadGame
  LibDoom.g_do_load_game
end

fun g_save_game = G_SaveGame(slot : LibC::Int, description : LibC::Char*)
  LibDoom.g_save_game(slot, description)
end

fun g_do_save_game = G_DoSaveGame
  LibDoom.g_do_save_game
end

fun g_defered_init_new = G_DeferedInitNew(skill : CDoom::Skill, episode : LibC::Int, map : LibC::Int)
  LibDoom.g_defered_init_new(skill, episode, map)
end

fun g_do_new_game = G_DoNewGame
  LibDoom.g_do_new_game
end

fun g_init_new = G_InitNew(skill : CDoom::Skill, episode : LibC::Int, map : LibC::Int)
  LibDoom.g_init_new(skill, episode, map)
end

fun g_read_demo_ticcmd = G_ReadDemoTiccmd(cmd : CDoom::Ticcmd*)
  LibDoom.g_read_demo_ticcmd(cmd)
end

fun g_write_demo_ticcmd = G_WriteDemoTiccmd(cmd : CDoom::Ticcmd*)
  LibDoom.g_write_demo_ticcmd(cmd)
end

fun g_record_demo = G_RecordDemo(name : LibC::Char*)
  LibDoom.g_record_demo(name)
end

fun g_begin_recording = G_BeginRecording
  LibDoom.g_begin_recording
end

fun g_defered_play_demo = G_DeferedPlayDemo(demo : LibC::Char*)
  LibDoom.g_defered_play_demo(demo)
end

fun g_do_play_demo = G_DoPlayDemo
  LibDoom.g_do_play_demo
end

fun g_time_demo = G_TimeDemo(name : LibC::Char*)
  LibDoom.g_time_demo(name)
end

fun g_check_demo_status = G_CheckDemoStatus : CDoom::DoomBool
  LibDoom.g_check_demo_status
end

fun hulib_clear_text_line = HUlib_clearTextLine(t : CDoom::HU_Textline*)
  LibDoom.hulib_clear_text_line(t)
end

fun hulib_init_text_line = HUlib_initTextLine(t : CDoom::HU_Textline*, x : LibC::Int, y : LibC::Int, f : CDoom::Patch**, sc : LibC::Int)
  LibDoom.hulib_init_text_line(t, x, y, f, sc)
end

fun hulib_add_char_to_text_line = HUlib_addCharToTextLine(t : CDoom::HU_Textline*, ch : LibC::Char) : CDoom::DoomBool
  LibDoom.hulib_add_char_to_text_line(t, ch)
end

fun hulib_del_char_from_text_line = HUlib_delCharFromTextLine(t : CDoom::HU_Textline*) : CDoom::DoomBool
  LibDoom.hulib_del_char_from_text_line(t)
end

fun hulib_draw_text_line = HUlib_drawTextLine(l : CDoom::HU_Textline*, drawcursor : CDoom::DoomBool)
  LibDoom.hulib_draw_text_line(l, drawcursor)
end

fun hulib_erase_text_line = HUlib_eraseTextLine(l : CDoom::HU_Textline*)
  LibDoom.hulib_erase_text_line(l)
end

fun hulib_init_s_text = HUlib_initSText(s : CDoom::HU_Stext*,
                                        x : LibC::Int,
                                        y : LibC::Int,
                                        h : LibC::Int,
                                        font : CDoom::Patch**,
                                        startchar : LibC::Int,
                                        on : CDoom::DoomBool*)
  LibDoom.hulib_init_s_text(s, x, y, h, font, startchar, on)
end

fun hulib_add_line_to_s_text = HUlib_addLineToSText(s : CDoom::HU_Stext*)
  LibDoom.hulib_add_line_to_s_text(s)
end

fun hulib_add_message_to_s_text = HUlib_addMessageToSText(s : CDoom::HU_Stext*, prefix : LibC::Char*, msg : LibC::Char*)
  LibDoom.hulib_add_message_to_s_text(s, prefix, msg)
end

fun hulib_draw_s_text = HUlib_drawSText(s : CDoom::HU_Stext*)
  LibDoom.hulib_draw_s_text(s)
end

fun hulib_erase_s_text = HUlib_eraseSText(s : CDoom::HU_Stext*)
  LibDoom.hulib_erase_s_text(s)
end

fun hulib_init_i_text = HUlib_initIText(it : CDoom::HU_Itext*,
                                        x : LibC::Int,
                                        y : LibC::Int,
                                        font : CDoom::Patch**,
                                        startchar : LibC::Int,
                                        on : CDoom::DoomBool*)
  LibDoom.hulib_init_i_text(it, x, y, font, startchar, on)
end

fun hulib_del_char_from_i_text = HUlib_delCharFromIText(it : CDoom::HU_Itext*)
  LibDoom.hulib_del_char_from_i_text(it)
end

fun hulib_erase_line_from_i_text = HUlib_eraseLineFromIText(it : CDoom::HU_Itext*)
  LibDoom.hulib_erase_line_from_i_text(it)
end

fun hulib_reset_i_text = HUlib_resetIText(it : CDoom::HU_Itext*)
  LibDoom.hulib_reset_i_text(it)
end

fun hulib_add_prefix_to_i_text = HUlib_addPrefixToIText(it : CDoom::HU_Itext*, str : LibC::Char*)
  LibDoom.hulib_add_prefix_to_i_text(it, str)
end

fun hulib_key_in_i_text = HUlib_keyInIText(it : CDoom::HU_Itext*, ch : LibC::UChar) : CDoom::DoomBool
  LibDoom.hulib_key_in_i_text(it, ch)
end

fun hulib_draw_i_text = HUlib_drawIText(it : CDoom::HU_Itext*)
  LibDoom.hulib_draw_i_text(it)
end

fun hulib_erase_i_text = HUlib_eraseIText(it : CDoom::HU_Itext*)
  LibDoom.hulib_erase_i_text(it)
end

fun foreign_translation = ForeignTranslation(ch : LibC::Char) : LibC::Char
  LibDoom.foreign_translation(ch)
end

fun hu_init = HU_Init
  LibDoom.hu_init
end

fun hu_stop = HU_Stop
  LibDoom.hu_stop
end

fun hu_start = HU_Start
  LibDoom.hu_start
end

fun hu_drawer = HU_Drawer
  LibDoom.hu_drawer
end

fun hu_erase = HU_Erase
  LibDoom.hu_erase
end

fun hu_ticker = HU_Ticker
  LibDoom.hu_ticker
end

fun hu_queue_chat_char = HU_queueChatChar(c : LibC::Char)
  LibDoom.hu_queue_chat_char(c)
end

fun hu_dequeue_chat_char = HU_dequeueChatChar : LibC::Char
  LibDoom.hu_dequeue_chat_char
end

fun hu_responder = HU_Responder(ev : CDoom::Event*) : CDoom::DoomBool
  LibDoom.hu_responder(ev)
end

fun i_init_network = I_InitNetwork
  LibDoom.i_init_network
end

fun i_net_cmd = I_NetCmd
  LibDoom.i_net_cmd
end

fun getsfx(sfxname : LibC::Char*, len : LibC::Int*) : Void*
  LibDoom.getsfx(sfxname, len)
end

fun addsfx(sfxid : LibC::Int, volume : LibC::Int, step : LibC::Int, seperation : LibC::Int) : LibC::Int
  LibDoom.addsfx(sfxid, volume, step, seperation)
end

fun i_set_channels = I_SetChannels
  LibDoom.i_set_channels
end

fun i_set_sfx_volume = I_SetSfxVolume(volume : LibC::Int)
  LibDoom.i_set_sfx_volume(volume)
end

fun i_set_music_volume = I_SetMusicVolume(volume : LibC::Int)
  LibDoom.i_set_music_volume(volume)
end

fun i_get_sfx_lump_num = I_GetSfxLumpNum(sfx : CDoom::Sfxinfo*) : LibC::Int
  LibDoom.i_get_sfx_lump_num(sfx)
end

fun i_start_sound = I_StartSound(id : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int, priority : LibC::Int) : LibC::Int
  LibDoom.i_start_sound(id, vol, sep, pitch, priority)
end

fun i_stop_sound = I_StopSound(handle : LibC::Int)
  LibDoom.i_stop_sound(handle)
end

fun i_sound_is_playing = I_SoundIsPlaying(handle : LibC::Int) : LibC::Int
  LibDoom.i_sound_is_playing(handle)
end

fun i_update_sound = I_UpdateSound
  LibDoom.i_update_sound
end

fun i_submit_sound = I_SubmitSound
  LibDoom.i_submit_sound
end

fun i_update_sound_params = I_UpdateSoundParams(handle : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int)
  LibDoom.i_update_sound_params(handle, vol, sep, pitch)
end

fun i_shutdown_sound = I_ShutdownSound
  LibDoom.i_shutdown_sound
end

fun i_init_sound = I_InitSound
  LibDoom.i_init_sound
end

fun i_init_music = I_InitMusic
  LibDoom.i_init_music
end

fun i_shutdown_music = I_ShutdownMusic
  LibDoom.i_shutdown_music
end

fun i_play_song = I_PlaySong(handle : LibC::Int, looping : LibC::Int)
  LibDoom.i_play_song(handle, looping)
end

fun i_pause_song = I_PauseSong(handle : LibC::Int)
  LibDoom.i_pause_song(handle)
end

fun i_resume_song = I_ResumeSong(handle : LibC::Int)
  LibDoom.i_resume_song(handle)
end

fun reset_all_channels
  LibDoom.reset_all_channels
end

fun i_stop_song = I_StopSong(handle : LibC::Int)
  LibDoom.i_stop_song(handle)
end

fun i_unregister_song = I_UnRegisterSong(handle : LibC::Int)
  LibDoom.i_unregister_song(handle)
end

fun i_register_song = I_RegisterSong(data : Void*) : LibC::Int
  LibDoom.i_register_song(data)
end

fun i_qry_song_playing = I_QrySongPlaying(handle : LibC::Int) : LibC::Int
  LibDoom.i_qry_song_playing(handle)
end

fun i_tick_song = I_TickSong : LibC::ULong
  LibDoom.i_tick_song
end

fun i_tactile = I_Tactile(on : LibC::Int, off : LibC::Int, total : LibC::Int)
  LibDoom.i_tactile(on, off, total)
end

fun i_base_ticcmd = I_BaseTiccmd : CDoom::Ticcmd*
  LibDoom.i_base_ticcmd
end

fun i_get_heap_size = I_GetHeapSize : LibC::Int
  LibDoom.i_get_heap_size
end

fun i_zone_base = I_ZoneBase(size : LibC::Int*) : CDoom::Byte*
  LibDoom.i_zone_base(size)
end

fun i_get_time = I_GetTime : LibC::Int
  LibDoom.i_get_time
end

fun i_init = I_Init
  LibDoom.i_init
end

fun i_quit = I_Quit
  LibDoom.i_quit
end

fun i_wait_vbl = I_WaitVBL(count : LibC::Int)
  LibDoom.i_wait_vbl(count)
end

fun i_shutdown_graphics = I_ShutdownGraphics
  LibDoom.i_shutdown_graphics
end

fun i_init_graphics = I_InitGraphics
  LibDoom.i_init_graphics
end

fun i_alloc_low = I_AllocLow(length : LibC::Int) : CDoom::Byte*
  LibDoom.i_alloc_low(length)
end

fun i_error = I_Error(error : LibC::Char*)
  LibDoom.i_error(error)
end

fun i_shutdown_graphics = I_ShutdownGraphics
  LibDoom.i_shutdown_graphics
end

fun i_start_frame = I_StartFrame
  LibDoom.i_start_frame
end

fun i_start_tic = I_StartTic
  LibDoom.i_start_tic
end

fun i_update_no_blit = I_UpdateNoBlit
  LibDoom.i_update_no_blit
end

fun i_finish_update = I_FinishUpdate
  LibDoom.i_finish_update
end

fun i_read_screen = I_ReadScreen(scr : CDoom::Byte*)
  LibDoom.i_read_screen(scr)
end

fun i_set_palette = I_SetPalette(palette : CDoom::Byte*)
  LibDoom.i_set_palette(palette)
end

fun i_init_graphics = I_InitGraphics
  LibDoom.i_init_graphics
end

fun m_check_parm = M_CheckParm(check : LibC::Char*) : LibC::Int
  LibDoom.m_check_parm(check)
end

fun m_clear_box = M_ClearBox(box : CDoom::Fixed*)
  LibDoom.m_clear_box(box)
end

fun m_add_to_box = M_AddToBox(box : CDoom::Fixed*, x : CDoom::Fixed, y : CDoom::Fixed)
  LibDoom.m_add_to_box(box, x, y)
end

fun cht_check_cheat = cht_CheckCheat(cht : CDoom::Cheatseq*, key : LibC::Char) : LibC::Int
  LibDoom.cht_check_cheat(cht, key)
end

fun cht_get_param = cht_GetParam(cht : CDoom::Cheatseq*, buffer : LibC::Char*)
  LibDoom.cht_get_param(cht, buffer)
end

fun fixed_mul = FixedMul(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
  LibDoom.fixed_mul(a, b)
end

fun fixed_div = FixedDiv(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
  LibDoom.fixed_div(a, b)
end

fun fixed_div2 = FixedDiv2(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
  LibDoom.fixed_div2(a, b)
end

fun m_draw_custom_menu_text = M_DrawCustomMenuText(name : LibC::Char*, x : LibC::Int, y : LibC::Int)
  LibDoom.m_draw_custom_menu_text(name, x, y)
end

fun m_read_save_strings = M_ReadSaveStrings
  LibDoom.m_read_save_strings
end

fun m_draw_load = M_DrawLoad
  LibDoom.m_draw_load
end

fun m_draw_save_load_border = M_DrawSaveLoadBorder(x : LibC::Int, y : LibC::Int)
  LibDoom.m_draw_save_load_border(x, y)
end

fun m_load_select = M_LoadSelect(choice : LibC::Int)
  LibDoom.m_load_select(choice)
end

fun m_load_game = M_LoadGame(choice : LibC::Int)
  LibDoom.m_load_game(choice)
end

fun m_draw_save = M_DrawSave
  LibDoom.m_draw_save
end

fun m_do_save = M_DoSave(slot : LibC::Int)
  LibDoom.m_do_save(slot)
end

fun m_save_select = M_SaveSelect(choice : LibC::Int)
  LibDoom.m_save_select(choice)
end

fun m_save_game = M_SaveGame(choice : LibC::Int)
  LibDoom.m_save_game(choice)
end

fun m_quicksave_response = M_QuickSaveResponse(ch : LibC::Int)
  LibDoom.m_quicksave_response(ch)
end

fun m_quicksave = M_QuickSave
  LibDoom.m_quicksave
end

fun m_quickload_response = M_QuickLoadResponse(ch : LibC::Int)
  LibDoom.m_quickload_response(ch)
end

fun m_quickload = M_QuickLoad
  LibDoom.m_quickload
end

fun m_draw_readthis1 = M_DrawReadThis1
  LibDoom.m_draw_readthis1
end

fun m_draw_readthis2 = M_DrawReadThis2
  LibDoom.m_draw_readthis2
end

fun m_draw_sound = M_DrawSound
  LibDoom.m_draw_sound
end

fun m_sound = M_Sound(choice : LibC::Int)
  LibDoom.m_sound(choice)
end

fun m_mouse_options = M_MouseOptions(choice : LibC::Int)
  LibDoom.m_mouse_options(choice)
end

fun m_sfxvol = M_SfxVol(choice : LibC::Int)
  LibDoom.m_sfxvol(choice)
end

fun m_musicvol = M_MusicVol(choice : LibC::Int)
  LibDoom.m_musicvol(choice)
end

fun m_draw_mainmenu = M_DrawMainMenu
  LibDoom.m_draw_mainmenu
end

fun m_draw_newgame = M_DrawNewGame
  LibDoom.m_draw_newgame
end

fun m_new_game = M_NewGame(choice : LibC::Int)
  LibDoom.m_new_game(choice)
end

fun m_draw_episode = M_DrawEpisode
  LibDoom.m_draw_episode
end

fun m_verify_nightmare = M_VerifyNightmare(ch : LibC::Int)
  LibDoom.m_verify_nightmare(ch)
end

fun m_choose_skill = M_ChooseSkill(choice : LibC::Int)
  LibDoom.m_choose_skill(choice)
end

fun m_episode = M_Episode(choice : LibC::Int)
  LibDoom.m_episode(choice)
end

fun m_draw_options = M_DrawOptions
  LibDoom.m_draw_options
end

fun m_draw_mouse_options = M_DrawMouseOptions
  LibDoom.m_draw_mouse_options
end

fun m_options = M_Options(choice : LibC::Int)
  LibDoom.m_options(choice)
end

fun m_change_messages = M_ChangeMessages(choice : LibC::Int)
  LibDoom.m_change_messages(choice)
end

fun m_change_crosshair = M_ChangeCrosshair(choice : LibC::Int)
  LibDoom.m_change_crosshair(choice)
end

fun m_change_alwaysrun = M_ChangeAlwaysRun(choice : LibC::Int)
  LibDoom.m_change_alwaysrun(choice)
end

fun m_endgame_response = M_EndGameResponse(ch : Int32)
  LibDoom.m_endgame_response(ch)
end

fun m_endgame = M_EndGame(choice : LibC::Int)
  LibDoom.m_endgame(choice)
end

fun m_readthis = M_ReadThis(choice : LibC::Int)
  LibDoom.m_readthis(choice)
end

fun m_readthis2 = M_ReadThis2(choice : LibC::Int)
  LibDoom.m_readthis2(choice)
end

fun m_finish_readthis = M_FinishReadThis(choice : LibC::Int)
  LibDoom.m_finish_readthis(choice)
end

fun m_quit_response = M_QuitResponse(ch : LibC::Int)
  LibDoom.m_quit_response(ch)
end

fun m_quitdoom = M_QuitDOOM(choice : LibC::Int)
  LibDoom.m_quitdoom(choice)
end

fun m_change_sensitivity = M_ChangeSensitivity(choice : LibC::Int)
  LibDoom.m_change_sensitivity(choice)
end

fun m_mouse_move = M_MouseMove(choice : LibC::Int)
  LibDoom.m_mouse_move(choice)
end

fun m_size_display = M_SizeDisplay(choice : LibC::Int)
  LibDoom.m_size_display(choice)
end

fun m_draw_thermo = M_DrawThermo(x : LibC::Int, y : LibC::Int, therm_width : LibC::Int, therm_dot : LibC::Int)
  LibDoom.m_draw_thermo(x, y, therm_width, therm_dot)
end

fun m_draw_empty_cell = M_DrawEmptyCell(menu : CDoom::Menu*, item : LibC::Int)
  LibDoom.m_draw_empty_cell(menu, item)
end

fun m_draw_selcell = M_DrawSelCell(menu : CDoom::Menu*, item : LibC::Int)
  LibDoom.m_draw_selcell(menu, item)
end

fun m_start_message = M_StartMessage(string : LibC::Char*, routine : Proc(Int32, Nil), input : CDoom::DoomBool)
  LibDoom.m_start_message(string, routine, input)
end

fun m_stop_message = M_StopMessage
  LibDoom.m_stop_message
end

fun m_string_width = M_StringWidth(string : LibC::Char*) : LibC::Int
  LibDoom.m_string_width(string)
end

fun m_string_height = M_StringHeight(string : LibC::Char*) : LibC::Int
  LibDoom.m_string_height(string)
end

fun m_write_text = M_WriteText(x : LibC::Int, y : LibC::Int, string : LibC::Char*)
  LibDoom.m_write_text(x, y, string)
end

fun m_responder = M_Responder(ev : CDoom::Event*) : CDoom::DoomBool
  LibDoom.m_responder(ev)
end

fun m_start_control_panel = M_StartControlPanel
  LibDoom.m_start_control_panel
end

fun m_drawer = M_Drawer
  LibDoom.m_drawer
end

fun m_clear_menus = M_ClearMenus
  LibDoom.m_clear_menus
end

fun m_setup_next_menu = M_SetupNextMenu(menudef : CDoom::Menu*)
  LibDoom.m_setup_next_menu(menudef)
end

fun m_ticker = M_Ticker
  LibDoom.m_ticker
end

fun m_init = M_Init
  LibDoom.m_init
end

fun m_draw_text(x : LibC::Int, y : LibC::Int, direct : CDoom::DoomBool, string : LibC::Char*) : LibC::Int
  LibDoom.m_draw_text(x, y, direct, string)
end

fun m_write_file = M_WriteFile(name : LibC::Char*, source : Void*, length : LibC::Int) : CDoom::DoomBool
  LibDoom.m_write_file(name, source, length)
end

fun m_read_file = M_ReadFile(name : LibC::Char*, buffer : CDoom::Byte**) : LibC::Int
  LibDoom.m_read_file(name, buffer)
end

fun m_save_defaults = M_SaveDefaults
  LibDoom.m_save_defaults
end

fun m_load_defaults = M_LoadDefaults
  LibDoom.m_load_defaults
end

fun write_pcx_file = WritePCXfile(filename : LibC::Char*, data : CDoom::Byte*, width : LibC::Int, height : LibC::Int, palette : CDoom::Byte*)
  LibDoom.write_pcx_file(filename, data, width, height, palette)
end

fun m_screenshot = M_ScreenShot
  LibDoom.m_screenshot
end

fun p_random = P_Random : LibC::Int
  LibDoom.p_random
end

fun m_random = M_Random : LibC::Int
  LibDoom.m_random
end

fun m_clear_random = M_ClearRandom
  LibDoom.m_clear_random
end

fun t_move_ceiling = T_MoveCeiling(ceiling : CDoom::Ceiling*)
  LibDoom.t_move_ceiling(ceiling)
end

fun ev_do_ceiling = EV_DoCeiling(line : CDoom::Line*, type : CDoom::Ceilingenum) : LibC::Int
  LibDoom.ev_do_ceiling(line, type)
end

fun p_add_active_ceiling = P_AddActiveCeiling(c : CDoom::Ceiling*)
  LibDoom.p_add_active_ceiling(c)
end

fun p_remove_active_ceiling = P_RemoveActiveCeiling(c : CDoom::Ceiling*)
  LibDoom.p_remove_active_ceiling(c)
end

fun p_activate_in_stasis_ceiling = P_ActivateInStasisCeiling(line : CDoom::Line*)
  LibDoom.p_activate_in_stasis_ceiling(line)
end

fun ev_ceiling_crush_stop = EV_CeilingCrushStop(line : CDoom::Line*) : LibC::Int
  LibDoom.ev_ceiling_crush_stop(line)
end

fun t_vertical_door = T_VerticalDoor(door : CDoom::Vldoor*)
  LibDoom.t_vertical_door(door)
end

fun ev_do_locked_door = EV_DoLockedDoor(line : CDoom::Line*, type : CDoom::Vldoorenum, thing : CDoom::Mobj*) : LibC::Int
  LibDoom.ev_do_locked_door(line, type, thing)
end

fun ev_do_door = EV_DoDoor(line : CDoom::Line*, type : CDoom::Vldoorenum) : LibC::Int
  LibDoom.ev_do_door(line, type)
end

  fun ev_vertical_door = EV_VerticalDoor(line : CDoom::Line*, thing : CDoom::Mobj*)
LibDoom.ev_vertical_door(line, thing)
  end

  fun p_spawn_door_close_in_30 = P_SpawnDoorCloseIn30(sec : CDoom::Sector*)
LibDoom.p_spawn_door_close_in_30(sec)
  end

  fun p_spawn_door_raise_in_5_mins = P_SpawnDoorRaiseIn5Mins(sec : CDoom::Sector*, secnum : LibC::Int)
LibDoom.p_spawn_door_raise_in_5_mins(sec, secnum)
  end
