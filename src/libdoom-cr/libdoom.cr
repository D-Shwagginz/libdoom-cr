module LibDoom
  NULL_PROC = Proc(Int32, Nil).new(Pointer(Void).null, Pointer(Void).null)

  @@st_notify : CDoom::Event = CDoom::Event.new
  @@lastlevel = -1
  @@lastepisode = -1
  @@cheatstate = 0
  @@bigstate = 0
  @@buffer : UInt8* = Pointer(UInt8).malloc(20)
  @@nexttic = 0
  @@litelevels : StaticArray(Int32, 8) = StaticArray[0, 4, 7, 10, 12, 14, 15, 15]
  @@litelevelscnt = 0

  @@doomport : Int32 = CDoom::IPPORT_USERRESERVED + 0x1d
  @@doomport_send : Int32 = CDoom::IPPORT_USERRESERVED + 0x1e

  closing = false

  @@screen_texture : Raylib::Texture?
  @@audio_stream : RAudio::AudioStream?
  @@adl_player : ADLMIDI::Player*?
  @@music_stream : RAudio::AudioStream?
  @@last_time = 0
  @@music_buffer = Pointer(Int16).null
  @@midi_tick_accumulator = 0.0

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

  CDoom.weaponinfo[0] = CDoom::Weaponinfo.new(
    # fist
    ammo: CDoom::Ammotype::Noammo,
    upstate: CDoom::Statenum::S_PUNCHUP,
    downstate: CDoom::Statenum::S_PUNCHDOWN,
    readystate: CDoom::Statenum::S_PUNCH,
    atkstate: CDoom::Statenum::S_PUNCH1,
    flashstate: CDoom::Statenum::S_NULL
  )
  CDoom.weaponinfo[1] = CDoom::Weaponinfo.new(
    # pistol
    ammo: CDoom::Ammotype::Clip,
    upstate: CDoom::Statenum::S_PISTOLUP,
    downstate: CDoom::Statenum::S_PISTOLDOWN,
    readystate: CDoom::Statenum::S_PISTOL,
    atkstate: CDoom::Statenum::S_PISTOL1,
    flashstate: CDoom::Statenum::S_PISTOLFLASH
  )
  CDoom.weaponinfo[2] = CDoom::Weaponinfo.new(
    # shotgun
    ammo: CDoom::Ammotype::Shell,
    upstate: CDoom::Statenum::S_SGUNUP,
    downstate: CDoom::Statenum::S_SGUNDOWN,
    readystate: CDoom::Statenum::S_SGUN,
    atkstate: CDoom::Statenum::S_SGUN1,
    flashstate: CDoom::Statenum::S_SGUNFLASH1
  )
  CDoom.weaponinfo[3] = CDoom::Weaponinfo.new(
    # chaingun
    ammo: CDoom::Ammotype::Clip,
    upstate: CDoom::Statenum::S_CHAINUP,
    downstate: CDoom::Statenum::S_CHAINDOWN,
    readystate: CDoom::Statenum::S_CHAIN,
    atkstate: CDoom::Statenum::S_CHAIN1,
    flashstate: CDoom::Statenum::S_CHAINFLASH1
  )
  CDoom.weaponinfo[4] = CDoom::Weaponinfo.new(
    # missile launcher
    ammo: CDoom::Ammotype::Misl,
    upstate: CDoom::Statenum::S_MISSILEUP,
    downstate: CDoom::Statenum::S_MISSILEDOWN,
    readystate: CDoom::Statenum::S_MISSILE,
    atkstate: CDoom::Statenum::S_MISSILE1,
    flashstate: CDoom::Statenum::S_MISSILEFLASH1
  )
  CDoom.weaponinfo[5] = CDoom::Weaponinfo.new(
    # plasma rifle
    ammo: CDoom::Ammotype::Cell,
    upstate: CDoom::Statenum::S_PLASMAUP,
    downstate: CDoom::Statenum::S_PLASMADOWN,
    readystate: CDoom::Statenum::S_PLASMA,
    atkstate: CDoom::Statenum::S_PLASMA1,
    flashstate: CDoom::Statenum::S_PLASMAFLASH1
  )
  CDoom.weaponinfo[6] = CDoom::Weaponinfo.new(
    # bfg 9000
    ammo: CDoom::Ammotype::Cell,
    upstate: CDoom::Statenum::S_BFGUP,
    downstate: CDoom::Statenum::S_BFGDOWN,
    readystate: CDoom::Statenum::S_BFG,
    atkstate: CDoom::Statenum::S_BFG1,
    flashstate: CDoom::Statenum::S_BFGFLASH1
  )
  CDoom.weaponinfo[7] = CDoom::Weaponinfo.new(
    # chainsaw
    ammo: CDoom::Ammotype::Noammo,
    upstate: CDoom::Statenum::S_SAWUP,
    downstate: CDoom::Statenum::S_SAWDOWN,
    readystate: CDoom::Statenum::S_SAW,
    atkstate: CDoom::Statenum::S_SAW1,
    flashstate: CDoom::Statenum::S_NULL
  )
  CDoom.weaponinfo[8] = CDoom::Weaponinfo.new(
    # fist
    ammo: CDoom::Ammotype::Shell,
    upstate: CDoom::Statenum::S_DSGUNUP,
    downstate: CDoom::Statenum::S_DSGUNDOWN,
    readystate: CDoom::Statenum::S_DSGUN,
    atkstate: CDoom::Statenum::S_DSGUN1,
    flashstate: CDoom::Statenum::S_DSGUNFLASH1
  )

  CDoom.singletics = 1

  CDoom.is_wiping_screen = 0

  CDoom.debugfile = Pointer(Void).null

  CDoom.wipegamestate = CDoom::Gamestate::Demoscreen

  CDoom.forwardmove[0] = 0x19
  CDoom.forwardmove[1] = 0x32
  CDoom.sidemove[0] = 0x18
  CDoom.sidemove[1] = 0x28
  CDoom.angleturn[0] = 640
  CDoom.angleturn[1] = 1280
  CDoom.angleturn[2] = 320

  CDoom.gamemode = CDoom::GameMode::Indetermined
  CDoom.gamemission = CDoom::GameMission::Doom

  # Language.
  CDoom.language = CDoom::Language::English

  # Set if homebrew PWAD stuff has been added.
  CDoom.modifiedgame
  # DOOM1
  CDoom.doom1_endmsg[0] = CDoom::QUITMSG.to_unsafe
  CDoom.doom1_endmsg[1] = "please don't leave, there's more\ndemons to toast!".to_unsafe
  CDoom.doom1_endmsg[2] = "let's beat it -- this is turning\ninto a bloodbath!".to_unsafe
  CDoom.doom1_endmsg[3] = "i wouldn't leave if i were you.\ndos is much worse.".to_unsafe
  CDoom.doom1_endmsg[4] = "you're trying to say you like dos\nbetter than me, right?".to_unsafe
  CDoom.doom1_endmsg[5] = "don't leave yet -- there's a\ndemon around that corner!".to_unsafe
  CDoom.doom1_endmsg[6] = "ya know, next time you come in here\ni'm gonna toast ya.".to_unsafe
  CDoom.doom1_endmsg[7] = "go ahead and leave. see if i care.".to_unsafe

  # QuitDOOM II messages
  CDoom.doom2_endmsg[0] = CDoom::QUITMSG.to_unsafe
  CDoom.doom2_endmsg[1] = "you want to quit?\nthen, thou hast lost an eighth!".to_unsafe
  CDoom.doom2_endmsg[2] = "don't go now, there's a \ndimensional shambler waiting\nat the dos prompt!".to_unsafe
  CDoom.doom2_endmsg[3] = "get outta here and go back\nto your boring programs.".to_unsafe
  CDoom.doom2_endmsg[4] = "if i were your boss, i'd \n deathmatch ya in a minute!".to_unsafe
  CDoom.doom2_endmsg[5] = "look, bud. you leave now\nand you forfeit your body count!".to_unsafe
  CDoom.doom2_endmsg[6] = "just leave. when you come\nback, i'll be waiting with a bat.".to_unsafe
  CDoom.doom2_endmsg[7] = "you're lucky i don't smack\nyou for thinking about leaving.".to_unsafe

  # Stage of animation:
  #  0 = text, 1 = art screen, 2 = character cast
  # CDoom.finalstage

  CDoom.e1text = CDoom::E1TEXT
  CDoom.e2text = CDoom::E2TEXT
  CDoom.e3text = CDoom::E3TEXT
  CDoom.e4text = CDoom::E4TEXT

  CDoom.c1text = CDoom::C1TEXT
  CDoom.c2text = CDoom::C2TEXT
  CDoom.c3text = CDoom::C3TEXT
  CDoom.c4text = CDoom::C4TEXT
  CDoom.c5text = CDoom::C5TEXT
  CDoom.c6text = CDoom::C6TEXT

  CDoom.p1text = CDoom::P1TEXT
  CDoom.p2text = CDoom::P2TEXT
  CDoom.p3text = CDoom::P3TEXT
  CDoom.p4text = CDoom::P4TEXT
  CDoom.p5text = CDoom::P5TEXT
  CDoom.p6text = CDoom::P6TEXT

  CDoom.t1text = CDoom::T1TEXT
  CDoom.t2text = CDoom::T2TEXT
  CDoom.t3text = CDoom::T3TEXT
  CDoom.t4text = CDoom::T4TEXT
  CDoom.t5text = CDoom::T5TEXT
  CDoom.t6text = CDoom::T6TEXT

  CDoom.castorder[0] = CDoom::Castinfo.new(name: CDoom::CC_ZOMBIE, type: CDoom::Mobjtype::MT_POSSESSED)
  CDoom.castorder[1] = CDoom::Castinfo.new(name: CDoom::CC_SHOTGUN, type: CDoom::Mobjtype::MT_SHOTGUY)
  CDoom.castorder[2] = CDoom::Castinfo.new(name: CDoom::CC_HEAVY, type: CDoom::Mobjtype::MT_CHAINGUY)
  CDoom.castorder[3] = CDoom::Castinfo.new(name: CDoom::CC_IMP, type: CDoom::Mobjtype::MT_TROOP)
  CDoom.castorder[4] = CDoom::Castinfo.new(name: CDoom::CC_DEMON, type: CDoom::Mobjtype::MT_SERGEANT)
  CDoom.castorder[5] = CDoom::Castinfo.new(name: CDoom::CC_LOST, type: CDoom::Mobjtype::MT_SKULL)
  CDoom.castorder[6] = CDoom::Castinfo.new(name: CDoom::CC_CACO, type: CDoom::Mobjtype::MT_HEAD)
  CDoom.castorder[7] = CDoom::Castinfo.new(name: CDoom::CC_HELL, type: CDoom::Mobjtype::MT_KNIGHT)
  CDoom.castorder[8] = CDoom::Castinfo.new(name: CDoom::CC_BARON, type: CDoom::Mobjtype::MT_BRUISER)
  CDoom.castorder[9] = CDoom::Castinfo.new(name: CDoom::CC_ARACH, type: CDoom::Mobjtype::MT_BABY)
  CDoom.castorder[10] = CDoom::Castinfo.new(name: CDoom::CC_PAIN, type: CDoom::Mobjtype::MT_PAIN)
  CDoom.castorder[11] = CDoom::Castinfo.new(name: CDoom::CC_REVEN, type: CDoom::Mobjtype::MT_UNDEAD)
  CDoom.castorder[12] = CDoom::Castinfo.new(name: CDoom::CC_MANCU, type: CDoom::Mobjtype::MT_FATSO)
  CDoom.castorder[13] = CDoom::Castinfo.new(name: CDoom::CC_ARCH, type: CDoom::Mobjtype::MT_VILE)
  CDoom.castorder[14] = CDoom::Castinfo.new(name: CDoom::CC_SPIDER, type: CDoom::Mobjtype::MT_SPIDER)
  CDoom.castorder[15] = CDoom::Castinfo.new(name: CDoom::CC_CYBER, type: CDoom::Mobjtype::MT_CYBORG)
  CDoom.castorder[16] = CDoom::Castinfo.new(name: CDoom::CC_HERO, type: CDoom::Mobjtype::MT_PLAYER)

  CDoom.castorder[17] = CDoom::Castinfo.new

  CDoom.go = 0

  CDoom.mousebuttons = CDoom.mousearray.to_unsafe + 1

  CDoom.joybuttons = CDoom.joyarray.to_unsafe + 1

  # DOOM Par Times
  CDoom.pars[0][0] = 0
  CDoom.pars[0][1] = 0
  CDoom.pars[0][2] = 0
  CDoom.pars[0][3] = 0
  CDoom.pars[0][4] = 0
  CDoom.pars[0][5] = 0
  CDoom.pars[0][6] = 0
  CDoom.pars[0][7] = 0
  CDoom.pars[0][8] = 0
  CDoom.pars[0][9] = 0
  CDoom.pars[1][0] = 0
  CDoom.pars[1][1] = 30
  CDoom.pars[1][2] = 75
  CDoom.pars[1][3] = 120
  CDoom.pars[1][4] = 90
  CDoom.pars[1][5] = 165
  CDoom.pars[1][6] = 180
  CDoom.pars[1][7] = 180
  CDoom.pars[1][8] = 30
  CDoom.pars[1][9] = 165
  CDoom.pars[2][0] = 0
  CDoom.pars[2][1] = 90
  CDoom.pars[2][2] = 90
  CDoom.pars[2][3] = 90
  CDoom.pars[2][4] = 120
  CDoom.pars[2][5] = 90
  CDoom.pars[2][6] = 360
  CDoom.pars[2][7] = 240
  CDoom.pars[2][8] = 30
  CDoom.pars[2][9] = 170
  CDoom.pars[3][0] = 0
  CDoom.pars[3][1] = 90
  CDoom.pars[3][2] = 45
  CDoom.pars[3][3] = 90
  CDoom.pars[3][4] = 150
  CDoom.pars[3][5] = 90
  CDoom.pars[3][6] = 90
  CDoom.pars[3][7] = 165
  CDoom.pars[3][8] = 30
  CDoom.pars[3][9] = 135

  # DOOM II Par Times
  CDoom.cpars[0] = 30
  CDoom.cpars[1] = 90
  CDoom.cpars[2] = 120
  CDoom.cpars[3] = 120
  CDoom.cpars[4] = 90
  CDoom.cpars[5] = 150
  CDoom.cpars[6] = 120
  CDoom.cpars[7] = 120
  CDoom.cpars[8] = 270
  CDoom.cpars[9] = 90
  CDoom.cpars[10] = 210
  CDoom.cpars[11] = 150
  CDoom.cpars[12] = 150
  CDoom.cpars[13] = 150
  CDoom.cpars[14] = 210
  CDoom.cpars[15] = 150
  CDoom.cpars[16] = 420
  CDoom.cpars[17] = 150
  CDoom.cpars[18] = 210
  CDoom.cpars[19] = 150
  CDoom.cpars[20] = 240
  CDoom.cpars[21] = 150
  CDoom.cpars[22] = 180
  CDoom.cpars[23] = 150
  CDoom.cpars[24] = 150
  CDoom.cpars[25] = 300
  CDoom.cpars[26] = 330
  CDoom.cpars[27] = 420
  CDoom.cpars[28] = 300
  CDoom.cpars[29] = 180
  CDoom.cpars[30] = 120
  CDoom.cpars[31] = 30

  CDoom.always_off = 0
  CDoom.headsupactive = 0
  CDoom.head = 0
  CDoom.tail = 0

  CDoom.chat_macros[0] = CDoom::HUSTR_CHATMACRO0.to_unsafe
  CDoom.chat_macros[1] = CDoom::HUSTR_CHATMACRO1.to_unsafe
  CDoom.chat_macros[2] = CDoom::HUSTR_CHATMACRO2.to_unsafe
  CDoom.chat_macros[3] = CDoom::HUSTR_CHATMACRO3.to_unsafe
  CDoom.chat_macros[4] = CDoom::HUSTR_CHATMACRO4.to_unsafe
  CDoom.chat_macros[5] = CDoom::HUSTR_CHATMACRO5.to_unsafe
  CDoom.chat_macros[6] = CDoom::HUSTR_CHATMACRO6.to_unsafe
  CDoom.chat_macros[7] = CDoom::HUSTR_CHATMACRO7.to_unsafe
  CDoom.chat_macros[8] = CDoom::HUSTR_CHATMACRO8.to_unsafe
  CDoom.chat_macros[9] = CDoom::HUSTR_CHATMACRO9.to_unsafe

  CDoom.french_shiftxform[0] = 0_u8
  CDoom.french_shiftxform[1] = 1
  CDoom.french_shiftxform[2] = 2
  CDoom.french_shiftxform[3] = 3
  CDoom.french_shiftxform[4] = 4
  CDoom.french_shiftxform[5] = 5
  CDoom.french_shiftxform[6] = 6
  CDoom.french_shiftxform[7] = 7
  CDoom.french_shiftxform[8] = 8
  CDoom.french_shiftxform[9] = 9
  CDoom.french_shiftxform[10] = 10
  CDoom.french_shiftxform[11] = 11
  CDoom.french_shiftxform[12] = 12
  CDoom.french_shiftxform[13] = 13
  CDoom.french_shiftxform[14] = 14
  CDoom.french_shiftxform[15] = 15
  CDoom.french_shiftxform[16] = 16
  CDoom.french_shiftxform[17] = 17
  CDoom.french_shiftxform[18] = 18
  CDoom.french_shiftxform[19] = 19
  CDoom.french_shiftxform[20] = 20
  CDoom.french_shiftxform[21] = 21
  CDoom.french_shiftxform[22] = 22
  CDoom.french_shiftxform[23] = 23
  CDoom.french_shiftxform[24] = 24
  CDoom.french_shiftxform[25] = 25
  CDoom.french_shiftxform[26] = 26
  CDoom.french_shiftxform[27] = 27
  CDoom.french_shiftxform[28] = 28
  CDoom.french_shiftxform[29] = 29
  CDoom.french_shiftxform[30] = 30
  CDoom.french_shiftxform[31] = 31
  CDoom.french_shiftxform[32] = ' '.ord.to_u8
  CDoom.french_shiftxform[33] = '!'.ord.to_u8
  CDoom.french_shiftxform[34] = '"'.ord.to_u8
  CDoom.french_shiftxform[35] = '#'.ord.to_u8
  CDoom.french_shiftxform[36] = '$'.ord.to_u8
  CDoom.french_shiftxform[37] = '%'.ord.to_u8
  CDoom.french_shiftxform[38] = '&'.ord.to_u8
  CDoom.french_shiftxform[39] = '"'.ord.to_u8
  CDoom.french_shiftxform[40] = '('.ord.to_u8
  CDoom.french_shiftxform[41] = ')'.ord.to_u8
  CDoom.french_shiftxform[42] = '*'.ord.to_u8
  CDoom.french_shiftxform[43] = '+'.ord.to_u8
  CDoom.french_shiftxform[44] = '?'.ord.to_u8
  CDoom.french_shiftxform[45] = '_'.ord.to_u8
  CDoom.french_shiftxform[46] = '>'.ord.to_u8
  CDoom.french_shiftxform[47] = '?'.ord.to_u8
  CDoom.french_shiftxform[48] = '0'.ord.to_u8
  CDoom.french_shiftxform[49] = '1'.ord.to_u8
  CDoom.french_shiftxform[50] = '2'.ord.to_u8
  CDoom.french_shiftxform[51] = '3'.ord.to_u8
  CDoom.french_shiftxform[52] = '4'.ord.to_u8
  CDoom.french_shiftxform[53] = '5'.ord.to_u8
  CDoom.french_shiftxform[54] = '6'.ord.to_u8
  CDoom.french_shiftxform[55] = '7'.ord.to_u8
  CDoom.french_shiftxform[56] = '8'.ord.to_u8
  CDoom.french_shiftxform[57] = '9'.ord.to_u8
  CDoom.french_shiftxform[58] = '/'.ord.to_u8
  CDoom.french_shiftxform[59] = '.'.ord.to_u8
  CDoom.french_shiftxform[60] = '<'.ord.to_u8
  CDoom.french_shiftxform[61] = '+'.ord.to_u8
  CDoom.french_shiftxform[62] = '>'.ord.to_u8
  CDoom.french_shiftxform[63] = '?'.ord.to_u8
  CDoom.french_shiftxform[64] = '@'.ord.to_u8
  CDoom.french_shiftxform[65] = 'A'.ord.to_u8
  CDoom.french_shiftxform[66] = 'B'.ord.to_u8
  CDoom.french_shiftxform[67] = 'C'.ord.to_u8
  CDoom.french_shiftxform[68] = 'D'.ord.to_u8
  CDoom.french_shiftxform[69] = 'E'.ord.to_u8
  CDoom.french_shiftxform[70] = 'F'.ord.to_u8
  CDoom.french_shiftxform[71] = 'G'.ord.to_u8
  CDoom.french_shiftxform[72] = 'H'.ord.to_u8
  CDoom.french_shiftxform[73] = 'I'.ord.to_u8
  CDoom.french_shiftxform[74] = 'J'.ord.to_u8
  CDoom.french_shiftxform[75] = 'K'.ord.to_u8
  CDoom.french_shiftxform[76] = 'L'.ord.to_u8
  CDoom.french_shiftxform[77] = 'M'.ord.to_u8
  CDoom.french_shiftxform[78] = 'N'.ord.to_u8
  CDoom.french_shiftxform[79] = 'O'.ord.to_u8
  CDoom.french_shiftxform[80] = 'P'.ord.to_u8
  CDoom.french_shiftxform[81] = 'Q'.ord.to_u8
  CDoom.french_shiftxform[82] = 'R'.ord.to_u8
  CDoom.french_shiftxform[83] = 'S'.ord.to_u8
  CDoom.french_shiftxform[84] = 'T'.ord.to_u8
  CDoom.french_shiftxform[85] = 'U'.ord.to_u8
  CDoom.french_shiftxform[86] = 'V'.ord.to_u8
  CDoom.french_shiftxform[87] = 'W'.ord.to_u8
  CDoom.french_shiftxform[88] = 'X'.ord.to_u8
  CDoom.french_shiftxform[89] = 'Y'.ord.to_u8
  CDoom.french_shiftxform[90] = 'Z'.ord.to_u8
  CDoom.french_shiftxform[91] = '['.ord.to_u8
  CDoom.french_shiftxform[92] = '!'.ord.to_u8
  CDoom.french_shiftxform[93] = ']'.ord.to_u8
  CDoom.french_shiftxform[94] = '"'.ord.to_u8
  CDoom.french_shiftxform[95] = '_'.ord.to_u8
  CDoom.french_shiftxform[96] = '\''.ord.to_u8
  CDoom.french_shiftxform[97] = 'A'.ord.to_u8
  CDoom.french_shiftxform[98] = 'B'.ord.to_u8
  CDoom.french_shiftxform[99] = 'C'.ord.to_u8
  CDoom.french_shiftxform[100] = 'D'.ord.to_u8
  CDoom.french_shiftxform[101] = 'E'.ord.to_u8
  CDoom.french_shiftxform[102] = 'F'.ord.to_u8
  CDoom.french_shiftxform[103] = 'G'.ord.to_u8
  CDoom.french_shiftxform[104] = 'H'.ord.to_u8
  CDoom.french_shiftxform[105] = 'I'.ord.to_u8
  CDoom.french_shiftxform[106] = 'J'.ord.to_u8
  CDoom.french_shiftxform[107] = 'K'.ord.to_u8
  CDoom.french_shiftxform[108] = 'L'.ord.to_u8
  CDoom.french_shiftxform[109] = 'M'.ord.to_u8
  CDoom.french_shiftxform[110] = 'N'.ord.to_u8
  CDoom.french_shiftxform[111] = 'O'.ord.to_u8
  CDoom.french_shiftxform[112] = 'P'.ord.to_u8
  CDoom.french_shiftxform[113] = 'Q'.ord.to_u8
  CDoom.french_shiftxform[114] = 'R'.ord.to_u8
  CDoom.french_shiftxform[115] = 'S'.ord.to_u8
  CDoom.french_shiftxform[116] = 'T'.ord.to_u8
  CDoom.french_shiftxform[117] = 'U'.ord.to_u8
  CDoom.french_shiftxform[118] = 'V'.ord.to_u8
  CDoom.french_shiftxform[119] = 'W'.ord.to_u8
  CDoom.french_shiftxform[120] = 'X'.ord.to_u8
  CDoom.french_shiftxform[121] = 'Y'.ord.to_u8
  CDoom.french_shiftxform[122] = 'Z'.ord.to_u8
  CDoom.french_shiftxform[123] = '{'.ord.to_u8
  CDoom.french_shiftxform[124] = '|'.ord.to_u8
  CDoom.french_shiftxform[125] = '}'.ord.to_u8
  CDoom.french_shiftxform[126] = '~'.ord.to_u8
  CDoom.french_shiftxform[127] = 127

  CDoom.english_shiftxform[0] = 0
  CDoom.english_shiftxform[1] = 1
  CDoom.english_shiftxform[2] = 2
  CDoom.english_shiftxform[3] = 3
  CDoom.english_shiftxform[4] = 4
  CDoom.english_shiftxform[5] = 5
  CDoom.english_shiftxform[6] = 6
  CDoom.english_shiftxform[7] = 7
  CDoom.english_shiftxform[8] = 8
  CDoom.english_shiftxform[9] = 9
  CDoom.english_shiftxform[10] = 10
  CDoom.english_shiftxform[11] = 11
  CDoom.english_shiftxform[12] = 12
  CDoom.english_shiftxform[13] = 13
  CDoom.english_shiftxform[14] = 14
  CDoom.english_shiftxform[15] = 15
  CDoom.english_shiftxform[16] = 16
  CDoom.english_shiftxform[17] = 17
  CDoom.english_shiftxform[18] = 18
  CDoom.english_shiftxform[19] = 19
  CDoom.english_shiftxform[20] = 20
  CDoom.english_shiftxform[21] = 21
  CDoom.english_shiftxform[22] = 22
  CDoom.english_shiftxform[23] = 23
  CDoom.english_shiftxform[24] = 24
  CDoom.english_shiftxform[25] = 25
  CDoom.english_shiftxform[26] = 26
  CDoom.english_shiftxform[27] = 27
  CDoom.english_shiftxform[28] = 28
  CDoom.english_shiftxform[29] = 29
  CDoom.english_shiftxform[30] = 30
  CDoom.english_shiftxform[31] = 31
  CDoom.english_shiftxform[32] = ' '.ord.to_u8
  CDoom.english_shiftxform[33] = '!'.ord.to_u8
  CDoom.english_shiftxform[34] = '"'.ord.to_u8
  CDoom.english_shiftxform[35] = '#'.ord.to_u8
  CDoom.english_shiftxform[36] = '$'.ord.to_u8
  CDoom.english_shiftxform[37] = '%'.ord.to_u8
  CDoom.english_shiftxform[38] = '&'.ord.to_u8
  CDoom.english_shiftxform[39] = '"'.ord.to_u8
  CDoom.english_shiftxform[40] = '('.ord.to_u8
  CDoom.english_shiftxform[41] = ')'.ord.to_u8
  CDoom.english_shiftxform[42] = '*'.ord.to_u8
  CDoom.english_shiftxform[43] = '+'.ord.to_u8
  CDoom.english_shiftxform[44] = '<'.ord.to_u8
  CDoom.english_shiftxform[45] = '_'.ord.to_u8
  CDoom.english_shiftxform[46] = '>'.ord.to_u8
  CDoom.english_shiftxform[47] = '?'.ord.to_u8
  CDoom.english_shiftxform[48] = ')'.ord.to_u8
  CDoom.english_shiftxform[49] = '!'.ord.to_u8
  CDoom.english_shiftxform[50] = '@'.ord.to_u8
  CDoom.english_shiftxform[51] = '#'.ord.to_u8
  CDoom.english_shiftxform[52] = '$'.ord.to_u8
  CDoom.english_shiftxform[53] = '%'.ord.to_u8
  CDoom.english_shiftxform[54] = '^'.ord.to_u8
  CDoom.english_shiftxform[55] = '&'.ord.to_u8
  CDoom.english_shiftxform[56] = '*'.ord.to_u8
  CDoom.english_shiftxform[57] = '('.ord.to_u8
  CDoom.english_shiftxform[58] = ':'.ord.to_u8
  CDoom.english_shiftxform[59] = ':'.ord.to_u8
  CDoom.english_shiftxform[60] = '<'.ord.to_u8
  CDoom.english_shiftxform[61] = '+'.ord.to_u8
  CDoom.english_shiftxform[62] = '>'.ord.to_u8
  CDoom.english_shiftxform[63] = '?'.ord.to_u8
  CDoom.english_shiftxform[64] = '@'.ord.to_u8
  CDoom.english_shiftxform[65] = 'A'.ord.to_u8
  CDoom.english_shiftxform[66] = 'B'.ord.to_u8
  CDoom.english_shiftxform[67] = 'C'.ord.to_u8
  CDoom.english_shiftxform[68] = 'D'.ord.to_u8
  CDoom.english_shiftxform[69] = 'E'.ord.to_u8
  CDoom.english_shiftxform[70] = 'F'.ord.to_u8
  CDoom.english_shiftxform[71] = 'G'.ord.to_u8
  CDoom.english_shiftxform[72] = 'H'.ord.to_u8
  CDoom.english_shiftxform[73] = 'I'.ord.to_u8
  CDoom.english_shiftxform[74] = 'J'.ord.to_u8
  CDoom.english_shiftxform[75] = 'K'.ord.to_u8
  CDoom.english_shiftxform[76] = 'L'.ord.to_u8
  CDoom.english_shiftxform[77] = 'M'.ord.to_u8
  CDoom.english_shiftxform[78] = 'N'.ord.to_u8
  CDoom.english_shiftxform[79] = 'O'.ord.to_u8
  CDoom.english_shiftxform[80] = 'P'.ord.to_u8
  CDoom.english_shiftxform[81] = 'Q'.ord.to_u8
  CDoom.english_shiftxform[82] = 'R'.ord.to_u8
  CDoom.english_shiftxform[83] = 'S'.ord.to_u8
  CDoom.english_shiftxform[84] = 'T'.ord.to_u8
  CDoom.english_shiftxform[85] = 'U'.ord.to_u8
  CDoom.english_shiftxform[86] = 'V'.ord.to_u8
  CDoom.english_shiftxform[87] = 'W'.ord.to_u8
  CDoom.english_shiftxform[88] = 'X'.ord.to_u8
  CDoom.english_shiftxform[89] = 'Y'.ord.to_u8
  CDoom.english_shiftxform[90] = 'Z'.ord.to_u8
  CDoom.english_shiftxform[91] = '['.ord.to_u8
  CDoom.english_shiftxform[92] = '!'.ord.to_u8
  CDoom.english_shiftxform[93] = ']'.ord.to_u8
  CDoom.english_shiftxform[94] = '"'.ord.to_u8
  CDoom.english_shiftxform[95] = '_'.ord.to_u8
  CDoom.english_shiftxform[96] = '\''.ord.to_u8
  CDoom.english_shiftxform[97] = 'A'.ord.to_u8
  CDoom.english_shiftxform[98] = 'B'.ord.to_u8
  CDoom.english_shiftxform[99] = 'C'.ord.to_u8
  CDoom.english_shiftxform[100] = 'D'.ord.to_u8
  CDoom.english_shiftxform[101] = 'E'.ord.to_u8
  CDoom.english_shiftxform[102] = 'F'.ord.to_u8
  CDoom.english_shiftxform[103] = 'G'.ord.to_u8
  CDoom.english_shiftxform[104] = 'H'.ord.to_u8
  CDoom.english_shiftxform[105] = 'I'.ord.to_u8
  CDoom.english_shiftxform[106] = 'J'.ord.to_u8
  CDoom.english_shiftxform[107] = 'K'.ord.to_u8
  CDoom.english_shiftxform[108] = 'L'.ord.to_u8
  CDoom.english_shiftxform[109] = 'M'.ord.to_u8
  CDoom.english_shiftxform[110] = 'N'.ord.to_u8
  CDoom.english_shiftxform[111] = 'O'.ord.to_u8
  CDoom.english_shiftxform[112] = 'P'.ord.to_u8
  CDoom.english_shiftxform[113] = 'Q'.ord.to_u8
  CDoom.english_shiftxform[114] = 'R'.ord.to_u8
  CDoom.english_shiftxform[115] = 'S'.ord.to_u8
  CDoom.english_shiftxform[116] = 'T'.ord.to_u8
  CDoom.english_shiftxform[117] = 'U'.ord.to_u8
  CDoom.english_shiftxform[118] = 'V'.ord.to_u8
  CDoom.english_shiftxform[119] = 'W'.ord.to_u8
  CDoom.english_shiftxform[120] = 'X'.ord.to_u8
  CDoom.english_shiftxform[121] = 'Y'.ord.to_u8
  CDoom.english_shiftxform[122] = 'Z'.ord.to_u8
  CDoom.english_shiftxform[123] = '{'.ord.to_u8
  CDoom.english_shiftxform[124] = '|'.ord.to_u8
  CDoom.english_shiftxform[125] = '}'.ord.to_u8
  CDoom.english_shiftxform[126] = '~'.ord.to_u8
  CDoom.english_shiftxform[127] = 127

  CDoom.french_key_map[0] = 0
  CDoom.french_key_map[1] = 1
  CDoom.french_key_map[2] = 2
  CDoom.french_key_map[3] = 3
  CDoom.french_key_map[4] = 4
  CDoom.french_key_map[5] = 5
  CDoom.french_key_map[6] = 6
  CDoom.french_key_map[7] = 7
  CDoom.french_key_map[8] = 8
  CDoom.french_key_map[9] = 9
  CDoom.french_key_map[10] = 10
  CDoom.french_key_map[11] = 11
  CDoom.french_key_map[12] = 12
  CDoom.french_key_map[13] = 13
  CDoom.french_key_map[14] = 14
  CDoom.french_key_map[15] = 15
  CDoom.french_key_map[16] = 16
  CDoom.french_key_map[17] = 17
  CDoom.french_key_map[18] = 18
  CDoom.french_key_map[19] = 19
  CDoom.french_key_map[20] = 20
  CDoom.french_key_map[21] = 21
  CDoom.french_key_map[22] = 22
  CDoom.french_key_map[23] = 23
  CDoom.french_key_map[24] = 24
  CDoom.french_key_map[25] = 25
  CDoom.french_key_map[26] = 26
  CDoom.french_key_map[27] = 27
  CDoom.french_key_map[28] = 28
  CDoom.french_key_map[29] = 29
  CDoom.french_key_map[30] = 30
  CDoom.french_key_map[31] = 31
  CDoom.french_key_map[32] = ' '.ord.to_u8
  CDoom.french_key_map[33] = '!'.ord.to_u8
  CDoom.french_key_map[34] = '"'.ord.to_u8
  CDoom.french_key_map[35] = '#'.ord.to_u8
  CDoom.french_key_map[36] = '$'.ord.to_u8
  CDoom.french_key_map[37] = '%'.ord.to_u8
  CDoom.french_key_map[38] = '&'.ord.to_u8
  CDoom.french_key_map[39] = '%'.ord.to_u8
  CDoom.french_key_map[40] = '('.ord.to_u8
  CDoom.french_key_map[41] = ')'.ord.to_u8
  CDoom.french_key_map[42] = '*'.ord.to_u8
  CDoom.french_key_map[43] = '+'.ord.to_u8
  CDoom.french_key_map[44] = ';'.ord.to_u8
  CDoom.french_key_map[45] = '-'.ord.to_u8
  CDoom.french_key_map[46] = ':'.ord.to_u8
  CDoom.french_key_map[47] = '!'.ord.to_u8
  CDoom.french_key_map[48] = '0'.ord.to_u8
  CDoom.french_key_map[49] = '1'.ord.to_u8
  CDoom.french_key_map[50] = '2'.ord.to_u8
  CDoom.french_key_map[51] = '3'.ord.to_u8
  CDoom.french_key_map[52] = '4'.ord.to_u8
  CDoom.french_key_map[53] = '5'.ord.to_u8
  CDoom.french_key_map[54] = '6'.ord.to_u8
  CDoom.french_key_map[55] = '7'.ord.to_u8
  CDoom.french_key_map[56] = '8'.ord.to_u8
  CDoom.french_key_map[57] = '9'.ord.to_u8
  CDoom.french_key_map[58] = ':'.ord.to_u8
  CDoom.french_key_map[59] = 'M'.ord.to_u8
  CDoom.french_key_map[60] = '<'.ord.to_u8
  CDoom.french_key_map[61] = '='.ord.to_u8
  CDoom.french_key_map[62] = '>'.ord.to_u8
  CDoom.french_key_map[63] = '?'.ord.to_u8
  CDoom.french_key_map[64] = '@'.ord.to_u8
  CDoom.french_key_map[65] = 'Q'.ord.to_u8
  CDoom.french_key_map[66] = 'B'.ord.to_u8
  CDoom.french_key_map[67] = 'C'.ord.to_u8
  CDoom.french_key_map[68] = 'D'.ord.to_u8
  CDoom.french_key_map[69] = 'E'.ord.to_u8
  CDoom.french_key_map[70] = 'F'.ord.to_u8
  CDoom.french_key_map[71] = 'G'.ord.to_u8
  CDoom.french_key_map[72] = 'H'.ord.to_u8
  CDoom.french_key_map[73] = 'I'.ord.to_u8
  CDoom.french_key_map[74] = 'J'.ord.to_u8
  CDoom.french_key_map[75] = 'K'.ord.to_u8
  CDoom.french_key_map[76] = 'L'.ord.to_u8
  CDoom.french_key_map[77] = ','.ord.to_u8
  CDoom.french_key_map[78] = 'N'.ord.to_u8
  CDoom.french_key_map[79] = 'O'.ord.to_u8
  CDoom.french_key_map[80] = 'P'.ord.to_u8
  CDoom.french_key_map[81] = 'A'.ord.to_u8
  CDoom.french_key_map[82] = 'R'.ord.to_u8
  CDoom.french_key_map[83] = 'S'.ord.to_u8
  CDoom.french_key_map[84] = 'T'.ord.to_u8
  CDoom.french_key_map[85] = 'U'.ord.to_u8
  CDoom.french_key_map[86] = 'V'.ord.to_u8
  CDoom.french_key_map[87] = 'Z'.ord.to_u8
  CDoom.french_key_map[88] = 'X'.ord.to_u8
  CDoom.french_key_map[89] = 'Y'.ord.to_u8
  CDoom.french_key_map[90] = 'W'.ord.to_u8
  CDoom.french_key_map[91] = '^'.ord.to_u8
  CDoom.french_key_map[92] = '\\'.ord.to_u8
  CDoom.french_key_map[93] = '$'.ord.to_u8
  CDoom.french_key_map[94] = '^'.ord.to_u8
  CDoom.french_key_map[95] = '_'.ord.to_u8
  CDoom.french_key_map[96] = '@'.ord.to_u8
  CDoom.french_key_map[97] = 'Q'.ord.to_u8
  CDoom.french_key_map[98] = 'B'.ord.to_u8
  CDoom.french_key_map[99] = 'C'.ord.to_u8
  CDoom.french_key_map[100] = 'D'.ord.to_u8
  CDoom.french_key_map[101] = 'E'.ord.to_u8
  CDoom.french_key_map[102] = 'F'.ord.to_u8
  CDoom.french_key_map[103] = 'G'.ord.to_u8
  CDoom.french_key_map[104] = 'H'.ord.to_u8
  CDoom.french_key_map[105] = 'I'.ord.to_u8
  CDoom.french_key_map[106] = 'J'.ord.to_u8
  CDoom.french_key_map[107] = 'K'.ord.to_u8
  CDoom.french_key_map[108] = 'L'.ord.to_u8
  CDoom.french_key_map[109] = ','.ord.to_u8
  CDoom.french_key_map[110] = 'N'.ord.to_u8
  CDoom.french_key_map[111] = 'O'.ord.to_u8
  CDoom.french_key_map[112] = 'P'.ord.to_u8
  CDoom.french_key_map[113] = 'A'.ord.to_u8
  CDoom.french_key_map[114] = 'R'.ord.to_u8
  CDoom.french_key_map[115] = 'S'.ord.to_u8
  CDoom.french_key_map[116] = 'T'.ord.to_u8
  CDoom.french_key_map[117] = 'U'.ord.to_u8
  CDoom.french_key_map[118] = 'V'.ord.to_u8
  CDoom.french_key_map[119] = 'Z'.ord.to_u8
  CDoom.french_key_map[120] = 'X'.ord.to_u8
  CDoom.french_key_map[121] = 'Y'.ord.to_u8
  CDoom.french_key_map[122] = 'W'.ord.to_u8
  CDoom.french_key_map[123] = '^'.ord.to_u8
  CDoom.french_key_map[124] = '\\'.ord.to_u8
  CDoom.french_key_map[125] = '$'.ord.to_u8
  CDoom.french_key_map[126] = '^'.ord.to_u8
  CDoom.french_key_map[127] = 127

  #
  # Builtin map names.
  # The actual names can be found in DStrings.h.
  #

  # DOOM shareware/registered/retail (Ultimate) names.
  CDoom.mapnames[0] = CDoom::HUSTR_E1M1.to_unsafe
  CDoom.mapnames[1] = CDoom::HUSTR_E1M2.to_unsafe
  CDoom.mapnames[2] = CDoom::HUSTR_E1M3.to_unsafe
  CDoom.mapnames[3] = CDoom::HUSTR_E1M4.to_unsafe
  CDoom.mapnames[4] = CDoom::HUSTR_E1M5.to_unsafe
  CDoom.mapnames[5] = CDoom::HUSTR_E1M6.to_unsafe
  CDoom.mapnames[6] = CDoom::HUSTR_E1M7.to_unsafe
  CDoom.mapnames[7] = CDoom::HUSTR_E1M8.to_unsafe
  CDoom.mapnames[8] = CDoom::HUSTR_E1M9.to_unsafe

  CDoom.mapnames[9] = CDoom::HUSTR_E2M1.to_unsafe
  CDoom.mapnames[10] = CDoom::HUSTR_E2M2.to_unsafe
  CDoom.mapnames[11] = CDoom::HUSTR_E2M3.to_unsafe
  CDoom.mapnames[12] = CDoom::HUSTR_E2M4.to_unsafe
  CDoom.mapnames[13] = CDoom::HUSTR_E2M5.to_unsafe
  CDoom.mapnames[14] = CDoom::HUSTR_E2M6.to_unsafe
  CDoom.mapnames[15] = CDoom::HUSTR_E2M7.to_unsafe
  CDoom.mapnames[16] = CDoom::HUSTR_E2M8.to_unsafe
  CDoom.mapnames[17] = CDoom::HUSTR_E2M9.to_unsafe

  CDoom.mapnames[18] = CDoom::HUSTR_E3M1.to_unsafe
  CDoom.mapnames[19] = CDoom::HUSTR_E3M2.to_unsafe
  CDoom.mapnames[20] = CDoom::HUSTR_E3M3.to_unsafe
  CDoom.mapnames[21] = CDoom::HUSTR_E3M4.to_unsafe
  CDoom.mapnames[22] = CDoom::HUSTR_E3M5.to_unsafe
  CDoom.mapnames[23] = CDoom::HUSTR_E3M6.to_unsafe
  CDoom.mapnames[24] = CDoom::HUSTR_E3M7.to_unsafe
  CDoom.mapnames[25] = CDoom::HUSTR_E3M8.to_unsafe
  CDoom.mapnames[26] = CDoom::HUSTR_E3M9.to_unsafe

  CDoom.mapnames[27] = CDoom::HUSTR_E4M1.to_unsafe
  CDoom.mapnames[28] = CDoom::HUSTR_E4M2.to_unsafe
  CDoom.mapnames[29] = CDoom::HUSTR_E4M3.to_unsafe
  CDoom.mapnames[30] = CDoom::HUSTR_E4M4.to_unsafe
  CDoom.mapnames[31] = CDoom::HUSTR_E4M5.to_unsafe
  CDoom.mapnames[32] = CDoom::HUSTR_E4M6.to_unsafe
  CDoom.mapnames[33] = CDoom::HUSTR_E4M7.to_unsafe
  CDoom.mapnames[34] = CDoom::HUSTR_E4M8.to_unsafe
  CDoom.mapnames[35] = CDoom::HUSTR_E4M9.to_unsafe

  CDoom.mapnames[36] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[37] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[38] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[39] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[40] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[41] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[42] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[43] = "NEWLEVEL".to_unsafe
  CDoom.mapnames[44] = "NEWLEVEL".to_unsafe

  # DOOM 2 map names.
  CDoom.mapnames2[0] = CDoom::HUSTR_1.to_unsafe
  CDoom.mapnames2[1] = CDoom::HUSTR_2.to_unsafe
  CDoom.mapnames2[2] = CDoom::HUSTR_3.to_unsafe
  CDoom.mapnames2[3] = CDoom::HUSTR_4.to_unsafe
  CDoom.mapnames2[4] = CDoom::HUSTR_5.to_unsafe
  CDoom.mapnames2[5] = CDoom::HUSTR_6.to_unsafe
  CDoom.mapnames2[6] = CDoom::HUSTR_7.to_unsafe
  CDoom.mapnames2[7] = CDoom::HUSTR_8.to_unsafe
  CDoom.mapnames2[8] = CDoom::HUSTR_9.to_unsafe
  CDoom.mapnames2[9] = CDoom::HUSTR_10.to_unsafe
  CDoom.mapnames2[10] = CDoom::HUSTR_11.to_unsafe

  CDoom.mapnames2[11] = CDoom::HUSTR_12.to_unsafe
  CDoom.mapnames2[12] = CDoom::HUSTR_13.to_unsafe
  CDoom.mapnames2[13] = CDoom::HUSTR_14.to_unsafe
  CDoom.mapnames2[14] = CDoom::HUSTR_15.to_unsafe
  CDoom.mapnames2[15] = CDoom::HUSTR_16.to_unsafe
  CDoom.mapnames2[16] = CDoom::HUSTR_17.to_unsafe
  CDoom.mapnames2[17] = CDoom::HUSTR_18.to_unsafe
  CDoom.mapnames2[18] = CDoom::HUSTR_19.to_unsafe
  CDoom.mapnames2[19] = CDoom::HUSTR_20.to_unsafe

  CDoom.mapnames2[20] = CDoom::HUSTR_21.to_unsafe
  CDoom.mapnames2[21] = CDoom::HUSTR_22.to_unsafe
  CDoom.mapnames2[22] = CDoom::HUSTR_23.to_unsafe
  CDoom.mapnames2[23] = CDoom::HUSTR_24.to_unsafe
  CDoom.mapnames2[24] = CDoom::HUSTR_25.to_unsafe
  CDoom.mapnames2[25] = CDoom::HUSTR_26.to_unsafe
  CDoom.mapnames2[26] = CDoom::HUSTR_27.to_unsafe
  CDoom.mapnames2[27] = CDoom::HUSTR_28.to_unsafe
  CDoom.mapnames2[28] = CDoom::HUSTR_29.to_unsafe
  CDoom.mapnames2[29] = CDoom::HUSTR_30.to_unsafe
  CDoom.mapnames2[30] = CDoom::HUSTR_31.to_unsafe
  CDoom.mapnames2[31] = CDoom::HUSTR_32.to_unsafe

  # Plutonia WAD map names.
  CDoom.mapnamesp[0] = CDoom::PHUSTR_1.to_unsafe
  CDoom.mapnamesp[1] = CDoom::PHUSTR_2.to_unsafe
  CDoom.mapnamesp[2] = CDoom::PHUSTR_3.to_unsafe
  CDoom.mapnamesp[3] = CDoom::PHUSTR_4.to_unsafe
  CDoom.mapnamesp[4] = CDoom::PHUSTR_5.to_unsafe
  CDoom.mapnamesp[5] = CDoom::PHUSTR_6.to_unsafe
  CDoom.mapnamesp[6] = CDoom::PHUSTR_7.to_unsafe
  CDoom.mapnamesp[7] = CDoom::PHUSTR_8.to_unsafe
  CDoom.mapnamesp[8] = CDoom::PHUSTR_9.to_unsafe
  CDoom.mapnamesp[9] = CDoom::PHUSTR_10.to_unsafe
  CDoom.mapnamesp[10] = CDoom::PHUSTR_11.to_unsafe

  CDoom.mapnamesp[11] = CDoom::PHUSTR_12.to_unsafe
  CDoom.mapnamesp[12] = CDoom::PHUSTR_13.to_unsafe
  CDoom.mapnamesp[13] = CDoom::PHUSTR_14.to_unsafe
  CDoom.mapnamesp[14] = CDoom::PHUSTR_15.to_unsafe
  CDoom.mapnamesp[15] = CDoom::PHUSTR_16.to_unsafe
  CDoom.mapnamesp[16] = CDoom::PHUSTR_17.to_unsafe
  CDoom.mapnamesp[17] = CDoom::PHUSTR_18.to_unsafe
  CDoom.mapnamesp[18] = CDoom::PHUSTR_19.to_unsafe
  CDoom.mapnamesp[19] = CDoom::PHUSTR_20.to_unsafe

  CDoom.mapnamesp[20] = CDoom::PHUSTR_21.to_unsafe
  CDoom.mapnamesp[21] = CDoom::PHUSTR_22.to_unsafe
  CDoom.mapnamesp[22] = CDoom::PHUSTR_23.to_unsafe
  CDoom.mapnamesp[23] = CDoom::PHUSTR_24.to_unsafe
  CDoom.mapnamesp[24] = CDoom::PHUSTR_25.to_unsafe
  CDoom.mapnamesp[25] = CDoom::PHUSTR_26.to_unsafe
  CDoom.mapnamesp[26] = CDoom::PHUSTR_27.to_unsafe
  CDoom.mapnamesp[27] = CDoom::PHUSTR_28.to_unsafe
  CDoom.mapnamesp[28] = CDoom::PHUSTR_29.to_unsafe
  CDoom.mapnamesp[29] = CDoom::PHUSTR_30.to_unsafe
  CDoom.mapnamesp[30] = CDoom::PHUSTR_31.to_unsafe
  CDoom.mapnamesp[31] = CDoom::PHUSTR_32.to_unsafe

  # TNT WAD map names.
  CDoom.mapnamest[0] = CDoom::THUSTR_1.to_unsafe
  CDoom.mapnamest[1] = CDoom::THUSTR_2.to_unsafe
  CDoom.mapnamest[2] = CDoom::THUSTR_3.to_unsafe
  CDoom.mapnamest[3] = CDoom::THUSTR_4.to_unsafe
  CDoom.mapnamest[4] = CDoom::THUSTR_5.to_unsafe
  CDoom.mapnamest[5] = CDoom::THUSTR_6.to_unsafe
  CDoom.mapnamest[6] = CDoom::THUSTR_7.to_unsafe
  CDoom.mapnamest[7] = CDoom::THUSTR_8.to_unsafe
  CDoom.mapnamest[8] = CDoom::THUSTR_9.to_unsafe
  CDoom.mapnamest[9] = CDoom::THUSTR_10.to_unsafe
  CDoom.mapnamest[10] = CDoom::THUSTR_11.to_unsafe

  CDoom.mapnamest[11] = CDoom::THUSTR_12.to_unsafe
  CDoom.mapnamest[12] = CDoom::THUSTR_13.to_unsafe
  CDoom.mapnamest[13] = CDoom::THUSTR_14.to_unsafe
  CDoom.mapnamest[14] = CDoom::THUSTR_15.to_unsafe
  CDoom.mapnamest[15] = CDoom::THUSTR_16.to_unsafe
  CDoom.mapnamest[16] = CDoom::THUSTR_17.to_unsafe
  CDoom.mapnamest[17] = CDoom::THUSTR_18.to_unsafe
  CDoom.mapnamest[18] = CDoom::THUSTR_19.to_unsafe
  CDoom.mapnamest[19] = CDoom::THUSTR_20.to_unsafe

  CDoom.mapnamest[20] = CDoom::THUSTR_21.to_unsafe
  CDoom.mapnamest[21] = CDoom::THUSTR_22.to_unsafe
  CDoom.mapnamest[22] = CDoom::THUSTR_23.to_unsafe
  CDoom.mapnamest[23] = CDoom::THUSTR_24.to_unsafe
  CDoom.mapnamest[24] = CDoom::THUSTR_25.to_unsafe
  CDoom.mapnamest[25] = CDoom::THUSTR_26.to_unsafe
  CDoom.mapnamest[26] = CDoom::THUSTR_27.to_unsafe
  CDoom.mapnamest[27] = CDoom::THUSTR_28.to_unsafe
  CDoom.mapnamest[28] = CDoom::THUSTR_29.to_unsafe
  CDoom.mapnamest[29] = CDoom::THUSTR_30.to_unsafe
  CDoom.mapnamest[30] = CDoom::THUSTR_31.to_unsafe
  CDoom.mapnamest[31] = CDoom::THUSTR_32.to_unsafe

  CDoom.flag = 0

  CDoom.mus_data = Pointer(UInt8).null
  CDoom.mus_offset = 0
  CDoom.mus_delay = 0
  CDoom.mus_loop = 0
  CDoom.mus_playing = 0
  CDoom.mus_volume = 127
  c_array(CDoom.mus_channel_volumes, 127, 127, 127, 127,
    127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127, 127)

  CDoom.looping = 0
  CDoom.musicdies = -1

  CDoom.queue_midi_head = 0
  CDoom.queue_midi_tail = 0

  CDoom.mb_used = 6 * (sizeof(Void*) // 4)

  @@sprnames = ["TROO".to_unsafe, "SHTG".to_unsafe, "PUNG".to_unsafe, "PISG".to_unsafe, "PISF".to_unsafe, "SHTF".to_unsafe, "SHT2".to_unsafe, "CHGG".to_unsafe, "CHGF".to_unsafe, "MISG".to_unsafe,
                "MISF".to_unsafe, "SAWG".to_unsafe, "PLSG".to_unsafe, "PLSF".to_unsafe, "BFGG".to_unsafe, "BFGF".to_unsafe, "BLUD".to_unsafe, "PUFF".to_unsafe, "BAL1".to_unsafe, "BAL2".to_unsafe,
                "PLSS".to_unsafe, "PLSE".to_unsafe, "MISL".to_unsafe, "BFS1".to_unsafe, "BFE1".to_unsafe, "BFE2".to_unsafe, "TFOG".to_unsafe, "IFOG".to_unsafe, "PLAY".to_unsafe, "POSS".to_unsafe,
                "SPOS".to_unsafe, "VILE".to_unsafe, "FIRE".to_unsafe, "FATB".to_unsafe, "FBXP".to_unsafe, "SKEL".to_unsafe, "MANF".to_unsafe, "FATT".to_unsafe, "CPOS".to_unsafe, "SARG".to_unsafe,
                "HEAD".to_unsafe, "BAL7".to_unsafe, "BOSS".to_unsafe, "BOS2".to_unsafe, "SKUL".to_unsafe, "SPID".to_unsafe, "BSPI".to_unsafe, "APLS".to_unsafe, "APBX".to_unsafe, "CYBR".to_unsafe,
                "PAIN".to_unsafe, "SSWV".to_unsafe, "KEEN".to_unsafe, "BBRN".to_unsafe, "BOSF".to_unsafe, "ARM1".to_unsafe, "ARM2".to_unsafe, "BAR1".to_unsafe, "BEXP".to_unsafe, "FCAN".to_unsafe,
                "BON1".to_unsafe, "BON2".to_unsafe, "BKEY".to_unsafe, "RKEY".to_unsafe, "YKEY".to_unsafe, "BSKU".to_unsafe, "RSKU".to_unsafe, "YSKU".to_unsafe, "STIM".to_unsafe, "MEDI".to_unsafe,
                "SOUL".to_unsafe, "PINV".to_unsafe, "PSTR".to_unsafe, "PINS".to_unsafe, "MEGA".to_unsafe, "SUIT".to_unsafe, "PMAP".to_unsafe, "PVIS".to_unsafe, "CLIP".to_unsafe, "AMMO".to_unsafe,
                "ROCK".to_unsafe, "BROK".to_unsafe, "CELL".to_unsafe, "CELP".to_unsafe, "SHEL".to_unsafe, "SBOX".to_unsafe, "BPAK".to_unsafe, "BFUG".to_unsafe, "MGUN".to_unsafe, "CSAW".to_unsafe,
                "LAUN".to_unsafe, "PLAS".to_unsafe, "SHOT".to_unsafe, "SGN2".to_unsafe, "COLU".to_unsafe, "SMT2".to_unsafe, "GOR1".to_unsafe, "POL2".to_unsafe, "POL5".to_unsafe, "POL4".to_unsafe,
                "POL3".to_unsafe, "POL1".to_unsafe, "POL6".to_unsafe, "GOR2".to_unsafe, "GOR3".to_unsafe, "GOR4".to_unsafe, "GOR5".to_unsafe, "SMIT".to_unsafe, "COL1".to_unsafe, "COL2".to_unsafe,
                "COL3".to_unsafe, "COL4".to_unsafe, "CAND".to_unsafe, "CBRA".to_unsafe, "COL6".to_unsafe, "TRE1".to_unsafe, "TRE2".to_unsafe, "ELEC".to_unsafe, "CEYE".to_unsafe, "FSKU".to_unsafe,
                "COL5".to_unsafe, "TBLU".to_unsafe, "TGRN".to_unsafe, "TRED".to_unsafe, "SMBT".to_unsafe, "SMGT".to_unsafe, "SMRT".to_unsafe, "HDB1".to_unsafe, "HDB2".to_unsafe, "HDB3".to_unsafe,
                "HDB4".to_unsafe, "HDB5".to_unsafe, "HDB6".to_unsafe, "POB1".to_unsafe, "POB2".to_unsafe, "BRS1".to_unsafe, "TLMP".to_unsafe, "TLP2".to_unsafe, "\0".to_unsafe]

  CDoom.sprnames = @@sprnames.to_unsafe

  def self.set_action(state : Pointer(CDoom::State), action : CDoom::ActionfP2)
    state.value.action.acp2 = action
  end

  def self.set_action(state : Pointer(CDoom::State), action : CDoom::ActionfV)
    state.value.action.acv = action
  end

  @@statedata : Array(Tuple(CDoom::Spritenum, Int32, Int32, CDoom::ActionfV | CDoom::ActionfP2, CDoom::Statenum, Int32, Int32)) = [
    {CDoom::Spritenum::SPR_TROO, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_NULL
    {CDoom::Spritenum::SPR_SHTG, 4, 0, ->CDoom.a_light0(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                            # S_LIGHTDONE
    {CDoom::Spritenum::SPR_PUNG, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_PUNCH, 0, 0},                                     # S_PUNCH
    {CDoom::Spritenum::SPR_PUNG, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_PUNCHDOWN, 0, 0},                                        # S_PUNCHDOWN
    {CDoom::Spritenum::SPR_PUNG, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_PUNCHUP, 0, 0},                                          # S_PUNCHUP
    {CDoom::Spritenum::SPR_PUNG, 1, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PUNCH2, 0, 0},             # S_PUNCH1
    {CDoom::Spritenum::SPR_PUNG, 2, 4, ->CDoom.a_punch(Void*, Void*), CDoom::Statenum::S_PUNCH3, 0, 0},                                           # S_PUNCH2
    {CDoom::Spritenum::SPR_PUNG, 3, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PUNCH4, 0, 0},             # S_PUNCH3
    {CDoom::Spritenum::SPR_PUNG, 2, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PUNCH5, 0, 0},             # S_PUNCH4
    {CDoom::Spritenum::SPR_PUNG, 1, 5, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_PUNCH, 0, 0},                                           # S_PUNCH5
    {CDoom::Spritenum::SPR_PISG, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_PISTOL, 0, 0},                                    # S_PISTOL
    {CDoom::Spritenum::SPR_PISG, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_PISTOLDOWN, 0, 0},                                       # S_PISTOLDOWN
    {CDoom::Spritenum::SPR_PISG, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_PISTOLUP, 0, 0},                                         # S_PISTOLUP
    {CDoom::Spritenum::SPR_PISG, 0, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PISTOL2, 0, 0},            # S_PISTOL1
    {CDoom::Spritenum::SPR_PISG, 1, 6, ->CDoom.a_fire_pistol(Void*, Void*), CDoom::Statenum::S_PISTOL3, 0, 0},                                    # S_PISTOL2
    {CDoom::Spritenum::SPR_PISG, 2, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PISTOL4, 0, 0},            # S_PISTOL3
    {CDoom::Spritenum::SPR_PISG, 1, 5, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_PISTOL, 0, 0},                                          # S_PISTOL4
    {CDoom::Spritenum::SPR_PISF, 32768, 7, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_PISTOLFLASH
    {CDoom::Spritenum::SPR_SHTG, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_SGUN, 0, 0},                                      # S_SGUN
    {CDoom::Spritenum::SPR_SHTG, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_SGUNDOWN, 0, 0},                                         # S_SGUNDOWN
    {CDoom::Spritenum::SPR_SHTG, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_SGUNUP, 0, 0},                                           # S_SGUNUP
    {CDoom::Spritenum::SPR_SHTG, 0, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SGUN2, 0, 0},              # S_SGUN1
    {CDoom::Spritenum::SPR_SHTG, 0, 7, ->CDoom.a_fire_shotgun(Void*, Void*), CDoom::Statenum::S_SGUN3, 0, 0},                                     # S_SGUN2
    {CDoom::Spritenum::SPR_SHTG, 1, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SGUN4, 0, 0},              # S_SGUN3
    {CDoom::Spritenum::SPR_SHTG, 2, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SGUN5, 0, 0},              # S_SGUN4
    {CDoom::Spritenum::SPR_SHTG, 3, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SGUN6, 0, 0},              # S_SGUN5
    {CDoom::Spritenum::SPR_SHTG, 2, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SGUN7, 0, 0},              # S_SGUN6
    {CDoom::Spritenum::SPR_SHTG, 1, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SGUN8, 0, 0},              # S_SGUN7
    {CDoom::Spritenum::SPR_SHTG, 0, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SGUN9, 0, 0},              # S_SGUN8
    {CDoom::Spritenum::SPR_SHTG, 0, 7, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_SGUN, 0, 0},                                            # S_SGUN9
    {CDoom::Spritenum::SPR_SHTF, 32768, 4, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_SGUNFLASH2, 0, 0},                                  # S_SGUNFLASH1
    {CDoom::Spritenum::SPR_SHTF, 32769, 3, ->CDoom.a_light2(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_SGUNFLASH2
    {CDoom::Spritenum::SPR_SHT2, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_DSGUN, 0, 0},                                     # S_DSGUN
    {CDoom::Spritenum::SPR_SHT2, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_DSGUNDOWN, 0, 0},                                        # S_DSGUNDOWN
    {CDoom::Spritenum::SPR_SHT2, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_DSGUNUP, 0, 0},                                          # S_DSGUNUP
    {CDoom::Spritenum::SPR_SHT2, 0, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_DSGUN2, 0, 0},             # S_DSGUN1
    {CDoom::Spritenum::SPR_SHT2, 0, 7, ->CDoom.a_fire_shotgun2(Void*, Void*), CDoom::Statenum::S_DSGUN3, 0, 0},                                   # S_DSGUN2
    {CDoom::Spritenum::SPR_SHT2, 1, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_DSGUN4, 0, 0},             # S_DSGUN3
    {CDoom::Spritenum::SPR_SHT2, 2, 7, ->CDoom.a_check_reload(Void*, Void*), CDoom::Statenum::S_DSGUN5, 0, 0},                                    # S_DSGUN4
    {CDoom::Spritenum::SPR_SHT2, 3, 7, ->CDoom.a_open_shotgun2(Void*, Void*), CDoom::Statenum::S_DSGUN6, 0, 0},                                   # S_DSGUN5
    {CDoom::Spritenum::SPR_SHT2, 4, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_DSGUN7, 0, 0},             # S_DSGUN6
    {CDoom::Spritenum::SPR_SHT2, 5, 7, ->CDoom.a_load_shotgun2(Void*, Void*), CDoom::Statenum::S_DSGUN8, 0, 0},                                   # S_DSGUN7
    {CDoom::Spritenum::SPR_SHT2, 6, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_DSGUN9, 0, 0},             # S_DSGUN8
    {CDoom::Spritenum::SPR_SHT2, 7, 6, ->CDoom.a_close_shotgun2(Void*, Void*), CDoom::Statenum::S_DSGUN10, 0, 0},                                 # S_DSGUN9
    {CDoom::Spritenum::SPR_SHT2, 0, 5, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_DSGUN, 0, 0},                                           # S_DSGUN10
    {CDoom::Spritenum::SPR_SHT2, 1, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_DSNR2, 0, 0},              # S_DSNR1
    {CDoom::Spritenum::SPR_SHT2, 0, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_DSGUNDOWN, 0, 0},          # S_DSNR2
    {CDoom::Spritenum::SPR_SHT2, 32776, 5, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_DSGUNFLASH2, 0, 0},                                 # S_DSGUNFLASH1
    {CDoom::Spritenum::SPR_SHT2, 32777, 4, ->CDoom.a_light2(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_DSGUNFLASH2
    {CDoom::Spritenum::SPR_CHGG, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_CHAIN, 0, 0},                                     # S_CHAIN
    {CDoom::Spritenum::SPR_CHGG, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_CHAINDOWN, 0, 0},                                        # S_CHAINDOWN
    {CDoom::Spritenum::SPR_CHGG, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_CHAINUP, 0, 0},                                          # S_CHAINUP
    {CDoom::Spritenum::SPR_CHGG, 0, 4, ->CDoom.a_fire_cgun(Void*, Void*), CDoom::Statenum::S_CHAIN2, 0, 0},                                       # S_CHAIN1
    {CDoom::Spritenum::SPR_CHGG, 1, 4, ->CDoom.a_fire_cgun(Void*, Void*), CDoom::Statenum::S_CHAIN3, 0, 0},                                       # S_CHAIN2
    {CDoom::Spritenum::SPR_CHGG, 1, 0, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_CHAIN, 0, 0},                                           # S_CHAIN3
    {CDoom::Spritenum::SPR_CHGF, 32768, 5, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_CHAINFLASH1
    {CDoom::Spritenum::SPR_CHGF, 32769, 5, ->CDoom.a_light2(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_CHAINFLASH2
    {CDoom::Spritenum::SPR_MISG, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_MISSILE, 0, 0},                                   # S_MISSILE
    {CDoom::Spritenum::SPR_MISG, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_MISSILEDOWN, 0, 0},                                      # S_MISSILEDOWN
    {CDoom::Spritenum::SPR_MISG, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_MISSILEUP, 0, 0},                                        # S_MISSILEUP
    {CDoom::Spritenum::SPR_MISG, 1, 8, ->CDoom.a_gun_flash(Void*, Void*), CDoom::Statenum::S_MISSILE2, 0, 0},                                     # S_MISSILE1
    {CDoom::Spritenum::SPR_MISG, 1, 12, ->CDoom.a_fire_missile(Void*, Void*), CDoom::Statenum::S_MISSILE3, 0, 0},                                 # S_MISSILE2
    {CDoom::Spritenum::SPR_MISG, 1, 0, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_MISSILE, 0, 0},                                         # S_MISSILE3
    {CDoom::Spritenum::SPR_MISF, 32768, 3, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_MISSILEFLASH2, 0, 0},                               # S_MISSILEFLASH1
    {CDoom::Spritenum::SPR_MISF, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_MISSILEFLASH3, 0, 0},  # S_MISSILEFLASH2
    {CDoom::Spritenum::SPR_MISF, 32770, 4, ->CDoom.a_light2(Void*, Void*), CDoom::Statenum::S_MISSILEFLASH4, 0, 0},                               # S_MISSILEFLASH3
    {CDoom::Spritenum::SPR_MISF, 32771, 4, ->CDoom.a_light2(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_MISSILEFLASH4
    {CDoom::Spritenum::SPR_SAWG, 2, 4, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_SAWB, 0, 0},                                      # S_SAW
    {CDoom::Spritenum::SPR_SAWG, 3, 4, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_SAW, 0, 0},                                       # S_SAWB
    {CDoom::Spritenum::SPR_SAWG, 2, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_SAWDOWN, 0, 0},                                          # S_SAWDOWN
    {CDoom::Spritenum::SPR_SAWG, 2, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_SAWUP, 0, 0},                                            # S_SAWUP
    {CDoom::Spritenum::SPR_SAWG, 0, 4, ->CDoom.a_saw(Void*, Void*), CDoom::Statenum::S_SAW2, 0, 0},                                               # S_SAW1
    {CDoom::Spritenum::SPR_SAWG, 1, 4, ->CDoom.a_saw(Void*, Void*), CDoom::Statenum::S_SAW3, 0, 0},                                               # S_SAW2
    {CDoom::Spritenum::SPR_SAWG, 1, 0, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_SAW, 0, 0},                                             # S_SAW3
    {CDoom::Spritenum::SPR_PLSG, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_PLASMA, 0, 0},                                    # S_PLASMA
    {CDoom::Spritenum::SPR_PLSG, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_PLASMADOWN, 0, 0},                                       # S_PLASMADOWN
    {CDoom::Spritenum::SPR_PLSG, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_PLASMAUP, 0, 0},                                         # S_PLASMAUP
    {CDoom::Spritenum::SPR_PLSG, 0, 3, ->CDoom.a_fire_plasma(Void*, Void*), CDoom::Statenum::S_PLASMA2, 0, 0},                                    # S_PLASMA1
    {CDoom::Spritenum::SPR_PLSG, 1, 20, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_PLASMA, 0, 0},                                         # S_PLASMA2
    {CDoom::Spritenum::SPR_PLSF, 32768, 4, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_PLASMAFLASH1
    {CDoom::Spritenum::SPR_PLSF, 32769, 4, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_PLASMAFLASH2
    {CDoom::Spritenum::SPR_BFGG, 0, 1, ->CDoom.a_weapon_ready(Void*, Void*), CDoom::Statenum::S_BFG, 0, 0},                                       # S_BFG
    {CDoom::Spritenum::SPR_BFGG, 0, 1, ->CDoom.a_lower(Void*, Void*), CDoom::Statenum::S_BFGDOWN, 0, 0},                                          # S_BFGDOWN
    {CDoom::Spritenum::SPR_BFGG, 0, 1, ->CDoom.a_raise(Void*, Void*), CDoom::Statenum::S_BFGUP, 0, 0},                                            # S_BFGUP
    {CDoom::Spritenum::SPR_BFGG, 0, 20, ->CDoom.a_bfg_sound(Void*, Void*), CDoom::Statenum::S_BFG2, 0, 0},                                        # S_BFG1
    {CDoom::Spritenum::SPR_BFGG, 1, 10, ->CDoom.a_gun_flash(Void*, Void*), CDoom::Statenum::S_BFG3, 0, 0},                                        # S_BFG2
    {CDoom::Spritenum::SPR_BFGG, 1, 10, ->CDoom.a_fire_bfg(Void*, Void*), CDoom::Statenum::S_BFG4, 0, 0},                                         # S_BFG3
    {CDoom::Spritenum::SPR_BFGG, 1, 20, ->CDoom.a_refire(Void*, Void*), CDoom::Statenum::S_BFG, 0, 0},                                            # S_BFG4
    {CDoom::Spritenum::SPR_BFGF, 32768, 11, ->CDoom.a_light1(Void*, Void*), CDoom::Statenum::S_BFGFLASH2, 0, 0},                                  # S_BFGFLASH1
    {CDoom::Spritenum::SPR_BFGF, 32769, 6, ->CDoom.a_light2(Void*, Void*), CDoom::Statenum::S_LIGHTDONE, 0, 0},                                   # S_BFGFLASH2
    {CDoom::Spritenum::SPR_BLUD, 2, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLOOD2, 0, 0},             # S_BLOOD1
    {CDoom::Spritenum::SPR_BLUD, 1, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLOOD3, 0, 0},             # S_BLOOD2
    {CDoom::Spritenum::SPR_BLUD, 0, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},               # S_BLOOD3
    {CDoom::Spritenum::SPR_PUFF, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PUFF2, 0, 0},          # S_PUFF1
    {CDoom::Spritenum::SPR_PUFF, 1, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PUFF3, 0, 0},              # S_PUFF2
    {CDoom::Spritenum::SPR_PUFF, 2, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PUFF4, 0, 0},              # S_PUFF3
    {CDoom::Spritenum::SPR_PUFF, 3, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},               # S_PUFF4
    {CDoom::Spritenum::SPR_BAL1, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TBALL2, 0, 0},         # S_TBALL1
    {CDoom::Spritenum::SPR_BAL1, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TBALL1, 0, 0},         # S_TBALL2
    {CDoom::Spritenum::SPR_BAL1, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TBALLX2, 0, 0},        # S_TBALLX1
    {CDoom::Spritenum::SPR_BAL1, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TBALLX3, 0, 0},        # S_TBALLX2
    {CDoom::Spritenum::SPR_BAL1, 32772, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_TBALLX3
    {CDoom::Spritenum::SPR_BAL2, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RBALL2, 0, 0},         # S_RBALL1
    {CDoom::Spritenum::SPR_BAL2, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RBALL1, 0, 0},         # S_RBALL2
    {CDoom::Spritenum::SPR_BAL2, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RBALLX2, 0, 0},        # S_RBALLX1
    {CDoom::Spritenum::SPR_BAL2, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RBALLX3, 0, 0},        # S_RBALLX2
    {CDoom::Spritenum::SPR_BAL2, 32772, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_RBALLX3
    {CDoom::Spritenum::SPR_PLSS, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLASBALL2, 0, 0},      # S_PLASBALL
    {CDoom::Spritenum::SPR_PLSS, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLASBALL, 0, 0},       # S_PLASBALL2
    {CDoom::Spritenum::SPR_PLSE, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLASEXP2, 0, 0},       # S_PLASEXP
    {CDoom::Spritenum::SPR_PLSE, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLASEXP3, 0, 0},       # S_PLASEXP2
    {CDoom::Spritenum::SPR_PLSE, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLASEXP4, 0, 0},       # S_PLASEXP3
    {CDoom::Spritenum::SPR_PLSE, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLASEXP5, 0, 0},       # S_PLASEXP4
    {CDoom::Spritenum::SPR_PLSE, 32772, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_PLASEXP5
    {CDoom::Spritenum::SPR_MISL, 32768, 1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ROCKET, 0, 0},         # S_ROCKET
    {CDoom::Spritenum::SPR_BFS1, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGSHOT2, 0, 0},       # S_BFGSHOT
    {CDoom::Spritenum::SPR_BFS1, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGSHOT, 0, 0},        # S_BFGSHOT2
    {CDoom::Spritenum::SPR_BFE1, 32768, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGLAND2, 0, 0},       # S_BFGLAND
    {CDoom::Spritenum::SPR_BFE1, 32769, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGLAND3, 0, 0},       # S_BFGLAND2
    {CDoom::Spritenum::SPR_BFE1, 32770, 8, ->CDoom.a_bfg_spray(Void*, Void*), CDoom::Statenum::S_BFGLAND4, 0, 0},                                 # S_BFGLAND3
    {CDoom::Spritenum::SPR_BFE1, 32771, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGLAND5, 0, 0},       # S_BFGLAND4
    {CDoom::Spritenum::SPR_BFE1, 32772, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGLAND6, 0, 0},       # S_BFGLAND5
    {CDoom::Spritenum::SPR_BFE1, 32773, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_BFGLAND6
    {CDoom::Spritenum::SPR_BFE2, 32768, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGEXP2, 0, 0},        # S_BFGEXP
    {CDoom::Spritenum::SPR_BFE2, 32769, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGEXP3, 0, 0},        # S_BFGEXP2
    {CDoom::Spritenum::SPR_BFE2, 32770, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BFGEXP4, 0, 0},        # S_BFGEXP3
    {CDoom::Spritenum::SPR_BFE2, 32771, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_BFGEXP4
    {CDoom::Spritenum::SPR_MISL, 32769, 8, ->CDoom.a_explode(Void*, Void*), CDoom::Statenum::S_EXPLODE2, 0, 0},                                   # S_EXPLODE1
    {CDoom::Spritenum::SPR_MISL, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_EXPLODE3, 0, 0},       # S_EXPLODE2
    {CDoom::Spritenum::SPR_MISL, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_EXPLODE3
    {CDoom::Spritenum::SPR_TFOG, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG01, 0, 0},         # S_TFOG
    {CDoom::Spritenum::SPR_TFOG, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG02, 0, 0},         # S_TFOG01
    {CDoom::Spritenum::SPR_TFOG, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG2, 0, 0},          # S_TFOG02
    {CDoom::Spritenum::SPR_TFOG, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG3, 0, 0},          # S_TFOG2
    {CDoom::Spritenum::SPR_TFOG, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG4, 0, 0},          # S_TFOG3
    {CDoom::Spritenum::SPR_TFOG, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG5, 0, 0},          # S_TFOG4
    {CDoom::Spritenum::SPR_TFOG, 32772, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG6, 0, 0},          # S_TFOG5
    {CDoom::Spritenum::SPR_TFOG, 32773, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG7, 0, 0},          # S_TFOG6
    {CDoom::Spritenum::SPR_TFOG, 32774, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG8, 0, 0},          # S_TFOG7
    {CDoom::Spritenum::SPR_TFOG, 32775, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG9, 0, 0},          # S_TFOG8
    {CDoom::Spritenum::SPR_TFOG, 32776, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TFOG10, 0, 0},         # S_TFOG9
    {CDoom::Spritenum::SPR_TFOG, 32777, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_TFOG10
    {CDoom::Spritenum::SPR_IFOG, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_IFOG01, 0, 0},         # S_IFOG
    {CDoom::Spritenum::SPR_IFOG, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_IFOG02, 0, 0},         # S_IFOG01
    {CDoom::Spritenum::SPR_IFOG, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_IFOG2, 0, 0},          # S_IFOG02
    {CDoom::Spritenum::SPR_IFOG, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_IFOG3, 0, 0},          # S_IFOG2
    {CDoom::Spritenum::SPR_IFOG, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_IFOG4, 0, 0},          # S_IFOG3
    {CDoom::Spritenum::SPR_IFOG, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_IFOG5, 0, 0},          # S_IFOG4
    {CDoom::Spritenum::SPR_IFOG, 32772, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_IFOG5
    {CDoom::Spritenum::SPR_PLAY, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_PLAY
    {CDoom::Spritenum::SPR_PLAY, 0, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_RUN2, 0, 0},          # S_PLAY_RUN1
    {CDoom::Spritenum::SPR_PLAY, 1, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_RUN3, 0, 0},          # S_PLAY_RUN2
    {CDoom::Spritenum::SPR_PLAY, 2, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_RUN4, 0, 0},          # S_PLAY_RUN3
    {CDoom::Spritenum::SPR_PLAY, 3, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_RUN1, 0, 0},          # S_PLAY_RUN4
    {CDoom::Spritenum::SPR_PLAY, 4, 12, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY, 0, 0},              # S_PLAY_ATK1
    {CDoom::Spritenum::SPR_PLAY, 32773, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_ATK1, 0, 0},      # S_PLAY_ATK2
    {CDoom::Spritenum::SPR_PLAY, 6, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_PAIN2, 0, 0},         # S_PLAY_PAIN
    {CDoom::Spritenum::SPR_PLAY, 6, 4, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_PLAY, 0, 0},                                              # S_PLAY_PAIN2
    {CDoom::Spritenum::SPR_PLAY, 7, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_DIE2, 0, 0},         # S_PLAY_DIE1
    {CDoom::Spritenum::SPR_PLAY, 8, 10, ->CDoom.a_player_scream(Void*, Void*), CDoom::Statenum::S_PLAY_DIE3, 0, 0},                               # S_PLAY_DIE2
    {CDoom::Spritenum::SPR_PLAY, 9, 10, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_PLAY_DIE4, 0, 0},                                        # S_PLAY_DIE3
    {CDoom::Spritenum::SPR_PLAY, 10, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_DIE5, 0, 0},        # S_PLAY_DIE4
    {CDoom::Spritenum::SPR_PLAY, 11, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_DIE6, 0, 0},        # S_PLAY_DIE5
    {CDoom::Spritenum::SPR_PLAY, 12, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_DIE7, 0, 0},        # S_PLAY_DIE6
    {CDoom::Spritenum::SPR_PLAY, 13, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_PLAY_DIE7
    {CDoom::Spritenum::SPR_PLAY, 14, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_XDIE2, 0, 0},        # S_PLAY_XDIE1
    {CDoom::Spritenum::SPR_PLAY, 15, 5, ->CDoom.a_xscream(Void*, Void*), CDoom::Statenum::S_PLAY_XDIE3, 0, 0},                                    # S_PLAY_XDIE2
    {CDoom::Spritenum::SPR_PLAY, 16, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_PLAY_XDIE4, 0, 0},                                       # S_PLAY_XDIE3
    {CDoom::Spritenum::SPR_PLAY, 17, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_XDIE5, 0, 0},        # S_PLAY_XDIE4
    {CDoom::Spritenum::SPR_PLAY, 18, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_XDIE6, 0, 0},        # S_PLAY_XDIE5
    {CDoom::Spritenum::SPR_PLAY, 19, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_XDIE7, 0, 0},        # S_PLAY_XDIE6
    {CDoom::Spritenum::SPR_PLAY, 20, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_XDIE8, 0, 0},        # S_PLAY_XDIE7
    {CDoom::Spritenum::SPR_PLAY, 21, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PLAY_XDIE9, 0, 0},        # S_PLAY_XDIE8
    {CDoom::Spritenum::SPR_PLAY, 22, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_PLAY_XDIE9
    {CDoom::Spritenum::SPR_POSS, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_POSS_STND2, 0, 0},                                       # S_POSS_STND
    {CDoom::Spritenum::SPR_POSS, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_POSS_STND, 0, 0},                                        # S_POSS_STND2
    {CDoom::Spritenum::SPR_POSS, 0, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN2, 0, 0},                                        # S_POSS_RUN1
    {CDoom::Spritenum::SPR_POSS, 0, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN3, 0, 0},                                        # S_POSS_RUN2
    {CDoom::Spritenum::SPR_POSS, 1, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN4, 0, 0},                                        # S_POSS_RUN3
    {CDoom::Spritenum::SPR_POSS, 1, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN5, 0, 0},                                        # S_POSS_RUN4
    {CDoom::Spritenum::SPR_POSS, 2, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN6, 0, 0},                                        # S_POSS_RUN5
    {CDoom::Spritenum::SPR_POSS, 2, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN7, 0, 0},                                        # S_POSS_RUN6
    {CDoom::Spritenum::SPR_POSS, 3, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN8, 0, 0},                                        # S_POSS_RUN7
    {CDoom::Spritenum::SPR_POSS, 3, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_POSS_RUN1, 0, 0},                                        # S_POSS_RUN8
    {CDoom::Spritenum::SPR_POSS, 4, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_POSS_ATK2, 0, 0},                                 # S_POSS_ATK1
    {CDoom::Spritenum::SPR_POSS, 5, 8, ->CDoom.a_pos_attack(Void*, Void*), CDoom::Statenum::S_POSS_ATK3, 0, 0},                                   # S_POSS_ATK2
    {CDoom::Spritenum::SPR_POSS, 4, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_RUN1, 0, 0},          # S_POSS_ATK3
    {CDoom::Spritenum::SPR_POSS, 6, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_PAIN2, 0, 0},         # S_POSS_PAIN
    {CDoom::Spritenum::SPR_POSS, 6, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_POSS_RUN1, 0, 0},                                         # S_POSS_PAIN2
    {CDoom::Spritenum::SPR_POSS, 7, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_DIE2, 0, 0},          # S_POSS_DIE1
    {CDoom::Spritenum::SPR_POSS, 8, 5, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_POSS_DIE3, 0, 0},                                       # S_POSS_DIE2
    {CDoom::Spritenum::SPR_POSS, 9, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_POSS_DIE4, 0, 0},                                         # S_POSS_DIE3
    {CDoom::Spritenum::SPR_POSS, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_DIE5, 0, 0},         # S_POSS_DIE4
    {CDoom::Spritenum::SPR_POSS, 11, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_POSS_DIE5
    {CDoom::Spritenum::SPR_POSS, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_XDIE2, 0, 0},        # S_POSS_XDIE1
    {CDoom::Spritenum::SPR_POSS, 13, 5, ->CDoom.a_xscream(Void*, Void*), CDoom::Statenum::S_POSS_XDIE3, 0, 0},                                    # S_POSS_XDIE2
    {CDoom::Spritenum::SPR_POSS, 14, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_POSS_XDIE4, 0, 0},                                       # S_POSS_XDIE3
    {CDoom::Spritenum::SPR_POSS, 15, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_XDIE5, 0, 0},        # S_POSS_XDIE4
    {CDoom::Spritenum::SPR_POSS, 16, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_XDIE6, 0, 0},        # S_POSS_XDIE5
    {CDoom::Spritenum::SPR_POSS, 17, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_XDIE7, 0, 0},        # S_POSS_XDIE6
    {CDoom::Spritenum::SPR_POSS, 18, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_XDIE8, 0, 0},        # S_POSS_XDIE7
    {CDoom::Spritenum::SPR_POSS, 19, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_XDIE9, 0, 0},        # S_POSS_XDIE8
    {CDoom::Spritenum::SPR_POSS, 20, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_POSS_XDIE9
    {CDoom::Spritenum::SPR_POSS, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_RAISE2, 0, 0},       # S_POSS_RAISE1
    {CDoom::Spritenum::SPR_POSS, 9, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_RAISE3, 0, 0},        # S_POSS_RAISE2
    {CDoom::Spritenum::SPR_POSS, 8, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_RAISE4, 0, 0},        # S_POSS_RAISE3
    {CDoom::Spritenum::SPR_POSS, 7, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_POSS_RUN1, 0, 0},          # S_POSS_RAISE4
    {CDoom::Spritenum::SPR_SPOS, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SPOS_STND2, 0, 0},                                       # S_SPOS_STND
    {CDoom::Spritenum::SPR_SPOS, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SPOS_STND, 0, 0},                                        # S_SPOS_STND2
    {CDoom::Spritenum::SPR_SPOS, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN2, 0, 0},                                        # S_SPOS_RUN1
    {CDoom::Spritenum::SPR_SPOS, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN3, 0, 0},                                        # S_SPOS_RUN2
    {CDoom::Spritenum::SPR_SPOS, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN4, 0, 0},                                        # S_SPOS_RUN3
    {CDoom::Spritenum::SPR_SPOS, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN5, 0, 0},                                        # S_SPOS_RUN4
    {CDoom::Spritenum::SPR_SPOS, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN6, 0, 0},                                        # S_SPOS_RUN5
    {CDoom::Spritenum::SPR_SPOS, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN7, 0, 0},                                        # S_SPOS_RUN6
    {CDoom::Spritenum::SPR_SPOS, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN8, 0, 0},                                        # S_SPOS_RUN7
    {CDoom::Spritenum::SPR_SPOS, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPOS_RUN1, 0, 0},                                        # S_SPOS_RUN8
    {CDoom::Spritenum::SPR_SPOS, 4, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SPOS_ATK2, 0, 0},                                 # S_SPOS_ATK1
    {CDoom::Spritenum::SPR_SPOS, 32773, 10, ->CDoom.a_spos_attack(Void*, Void*), CDoom::Statenum::S_SPOS_ATK3, 0, 0},                             # S_SPOS_ATK2
    {CDoom::Spritenum::SPR_SPOS, 4, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_RUN1, 0, 0},         # S_SPOS_ATK3
    {CDoom::Spritenum::SPR_SPOS, 6, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_PAIN2, 0, 0},         # S_SPOS_PAIN
    {CDoom::Spritenum::SPR_SPOS, 6, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_SPOS_RUN1, 0, 0},                                         # S_SPOS_PAIN2
    {CDoom::Spritenum::SPR_SPOS, 7, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_DIE2, 0, 0},          # S_SPOS_DIE1
    {CDoom::Spritenum::SPR_SPOS, 8, 5, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_SPOS_DIE3, 0, 0},                                       # S_SPOS_DIE2
    {CDoom::Spritenum::SPR_SPOS, 9, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SPOS_DIE4, 0, 0},                                         # S_SPOS_DIE3
    {CDoom::Spritenum::SPR_SPOS, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_DIE5, 0, 0},         # S_SPOS_DIE4
    {CDoom::Spritenum::SPR_SPOS, 11, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_SPOS_DIE5
    {CDoom::Spritenum::SPR_SPOS, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_XDIE2, 0, 0},        # S_SPOS_XDIE1
    {CDoom::Spritenum::SPR_SPOS, 13, 5, ->CDoom.a_xscream(Void*, Void*), CDoom::Statenum::S_SPOS_XDIE3, 0, 0},                                    # S_SPOS_XDIE2
    {CDoom::Spritenum::SPR_SPOS, 14, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SPOS_XDIE4, 0, 0},                                       # S_SPOS_XDIE3
    {CDoom::Spritenum::SPR_SPOS, 15, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_XDIE5, 0, 0},        # S_SPOS_XDIE4
    {CDoom::Spritenum::SPR_SPOS, 16, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_XDIE6, 0, 0},        # S_SPOS_XDIE5
    {CDoom::Spritenum::SPR_SPOS, 17, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_XDIE7, 0, 0},        # S_SPOS_XDIE6
    {CDoom::Spritenum::SPR_SPOS, 18, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_XDIE8, 0, 0},        # S_SPOS_XDIE7
    {CDoom::Spritenum::SPR_SPOS, 19, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_XDIE9, 0, 0},        # S_SPOS_XDIE8
    {CDoom::Spritenum::SPR_SPOS, 20, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_SPOS_XDIE9
    {CDoom::Spritenum::SPR_SPOS, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_RAISE2, 0, 0},       # S_SPOS_RAISE1
    {CDoom::Spritenum::SPR_SPOS, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_RAISE3, 0, 0},       # S_SPOS_RAISE2
    {CDoom::Spritenum::SPR_SPOS, 9, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_RAISE4, 0, 0},        # S_SPOS_RAISE3
    {CDoom::Spritenum::SPR_SPOS, 8, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_RAISE5, 0, 0},        # S_SPOS_RAISE4
    {CDoom::Spritenum::SPR_SPOS, 7, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPOS_RUN1, 0, 0},          # S_SPOS_RAISE5
    {CDoom::Spritenum::SPR_VILE, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_VILE_STND2, 0, 0},                                       # S_VILE_STND
    {CDoom::Spritenum::SPR_VILE, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_VILE_STND, 0, 0},                                        # S_VILE_STND2
    {CDoom::Spritenum::SPR_VILE, 0, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN2, 0, 0},                                   # S_VILE_RUN1
    {CDoom::Spritenum::SPR_VILE, 0, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN3, 0, 0},                                   # S_VILE_RUN2
    {CDoom::Spritenum::SPR_VILE, 1, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN4, 0, 0},                                   # S_VILE_RUN3
    {CDoom::Spritenum::SPR_VILE, 1, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN5, 0, 0},                                   # S_VILE_RUN4
    {CDoom::Spritenum::SPR_VILE, 2, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN6, 0, 0},                                   # S_VILE_RUN5
    {CDoom::Spritenum::SPR_VILE, 2, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN7, 0, 0},                                   # S_VILE_RUN6
    {CDoom::Spritenum::SPR_VILE, 3, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN8, 0, 0},                                   # S_VILE_RUN7
    {CDoom::Spritenum::SPR_VILE, 3, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN9, 0, 0},                                   # S_VILE_RUN8
    {CDoom::Spritenum::SPR_VILE, 4, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN10, 0, 0},                                  # S_VILE_RUN9
    {CDoom::Spritenum::SPR_VILE, 4, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN11, 0, 0},                                  # S_VILE_RUN10
    {CDoom::Spritenum::SPR_VILE, 5, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN12, 0, 0},                                  # S_VILE_RUN11
    {CDoom::Spritenum::SPR_VILE, 5, 2, ->CDoom.a_vile_chase(Void*, Void*), CDoom::Statenum::S_VILE_RUN1, 0, 0},                                   # S_VILE_RUN12
    {CDoom::Spritenum::SPR_VILE, 32774, 0, ->CDoom.a_vile_start(Void*, Void*), CDoom::Statenum::S_VILE_ATK2, 0, 0},                               # S_VILE_ATK1
    {CDoom::Spritenum::SPR_VILE, 32774, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK3, 0, 0},                             # S_VILE_ATK2
    {CDoom::Spritenum::SPR_VILE, 32775, 8, ->CDoom.a_vile_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK4, 0, 0},                              # S_VILE_ATK3
    {CDoom::Spritenum::SPR_VILE, 32776, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK5, 0, 0},                              # S_VILE_ATK4
    {CDoom::Spritenum::SPR_VILE, 32777, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK6, 0, 0},                              # S_VILE_ATK5
    {CDoom::Spritenum::SPR_VILE, 32778, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK7, 0, 0},                              # S_VILE_ATK6
    {CDoom::Spritenum::SPR_VILE, 32779, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK8, 0, 0},                              # S_VILE_ATK7
    {CDoom::Spritenum::SPR_VILE, 32780, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK9, 0, 0},                              # S_VILE_ATK8
    {CDoom::Spritenum::SPR_VILE, 32781, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_VILE_ATK10, 0, 0},                             # S_VILE_ATK9
    {CDoom::Spritenum::SPR_VILE, 32782, 8, ->CDoom.a_vile_attack(Void*, Void*), CDoom::Statenum::S_VILE_ATK11, 0, 0},                             # S_VILE_ATK10
    {CDoom::Spritenum::SPR_VILE, 32783, 20, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_RUN1, 0, 0},     # S_VILE_ATK11
    {CDoom::Spritenum::SPR_VILE, 32794, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_HEAL2, 0, 0},    # S_VILE_HEAL1
    {CDoom::Spritenum::SPR_VILE, 32795, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_HEAL3, 0, 0},    # S_VILE_HEAL2
    {CDoom::Spritenum::SPR_VILE, 32796, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_RUN1, 0, 0},     # S_VILE_HEAL3
    {CDoom::Spritenum::SPR_VILE, 16, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_PAIN2, 0, 0},        # S_VILE_PAIN
    {CDoom::Spritenum::SPR_VILE, 16, 5, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_VILE_RUN1, 0, 0},                                        # S_VILE_PAIN2
    {CDoom::Spritenum::SPR_VILE, 16, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_DIE2, 0, 0},         # S_VILE_DIE1
    {CDoom::Spritenum::SPR_VILE, 17, 7, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_VILE_DIE3, 0, 0},                                      # S_VILE_DIE2
    {CDoom::Spritenum::SPR_VILE, 18, 7, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_VILE_DIE4, 0, 0},                                        # S_VILE_DIE3
    {CDoom::Spritenum::SPR_VILE, 19, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_DIE5, 0, 0},         # S_VILE_DIE4
    {CDoom::Spritenum::SPR_VILE, 20, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_DIE6, 0, 0},         # S_VILE_DIE5
    {CDoom::Spritenum::SPR_VILE, 21, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_DIE7, 0, 0},         # S_VILE_DIE6
    {CDoom::Spritenum::SPR_VILE, 22, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_DIE8, 0, 0},         # S_VILE_DIE7
    {CDoom::Spritenum::SPR_VILE, 23, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_DIE9, 0, 0},         # S_VILE_DIE8
    {CDoom::Spritenum::SPR_VILE, 24, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_VILE_DIE10, 0, 0},        # S_VILE_DIE9
    {CDoom::Spritenum::SPR_VILE, 25, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_VILE_DIE10
    {CDoom::Spritenum::SPR_FIRE, 32768, 2, ->CDoom.a_start_fire(Void*, Void*), CDoom::Statenum::S_FIRE2, 0, 0},                                   # S_FIRE1
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE3, 0, 0},                                         # S_FIRE2
    {CDoom::Spritenum::SPR_FIRE, 32768, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE4, 0, 0},                                         # S_FIRE3
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE5, 0, 0},                                         # S_FIRE4
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, ->CDoom.a_fire_crackle(Void*, Void*), CDoom::Statenum::S_FIRE6, 0, 0},                                 # S_FIRE5
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE7, 0, 0},                                         # S_FIRE6
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE8, 0, 0},                                         # S_FIRE7
    {CDoom::Spritenum::SPR_FIRE, 32769, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE9, 0, 0},                                         # S_FIRE8
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE10, 0, 0},                                        # S_FIRE9
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE11, 0, 0},                                        # S_FIRE10
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE12, 0, 0},                                        # S_FIRE11
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE13, 0, 0},                                        # S_FIRE12
    {CDoom::Spritenum::SPR_FIRE, 32770, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE14, 0, 0},                                        # S_FIRE13
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE15, 0, 0},                                        # S_FIRE14
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE16, 0, 0},                                        # S_FIRE15
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE17, 0, 0},                                        # S_FIRE16
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE18, 0, 0},                                        # S_FIRE17
    {CDoom::Spritenum::SPR_FIRE, 32771, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE19, 0, 0},                                        # S_FIRE18
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, ->CDoom.a_fire_crackle(Void*, Void*), CDoom::Statenum::S_FIRE20, 0, 0},                                # S_FIRE19
    {CDoom::Spritenum::SPR_FIRE, 32773, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE21, 0, 0},                                        # S_FIRE20
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE22, 0, 0},                                        # S_FIRE21
    {CDoom::Spritenum::SPR_FIRE, 32773, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE23, 0, 0},                                        # S_FIRE22
    {CDoom::Spritenum::SPR_FIRE, 32772, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE24, 0, 0},                                        # S_FIRE23
    {CDoom::Spritenum::SPR_FIRE, 32773, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE25, 0, 0},                                        # S_FIRE24
    {CDoom::Spritenum::SPR_FIRE, 32774, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE26, 0, 0},                                        # S_FIRE25
    {CDoom::Spritenum::SPR_FIRE, 32775, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE27, 0, 0},                                        # S_FIRE26
    {CDoom::Spritenum::SPR_FIRE, 32774, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE28, 0, 0},                                        # S_FIRE27
    {CDoom::Spritenum::SPR_FIRE, 32775, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE29, 0, 0},                                        # S_FIRE28
    {CDoom::Spritenum::SPR_FIRE, 32774, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_FIRE30, 0, 0},                                        # S_FIRE29
    {CDoom::Spritenum::SPR_FIRE, 32775, 2, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                          # S_FIRE30
    {CDoom::Spritenum::SPR_PUFF, 1, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SMOKE2, 0, 0},             # S_SMOKE1
    {CDoom::Spritenum::SPR_PUFF, 2, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SMOKE3, 0, 0},             # S_SMOKE2
    {CDoom::Spritenum::SPR_PUFF, 1, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SMOKE4, 0, 0},             # S_SMOKE3
    {CDoom::Spritenum::SPR_PUFF, 2, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SMOKE5, 0, 0},             # S_SMOKE4
    {CDoom::Spritenum::SPR_PUFF, 3, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},               # S_SMOKE5
    {CDoom::Spritenum::SPR_FATB, 32768, 2, ->CDoom.a_tracer(Void*, Void*), CDoom::Statenum::S_TRACER2, 0, 0},                                     # S_TRACER
    {CDoom::Spritenum::SPR_FATB, 32769, 2, ->CDoom.a_tracer(Void*, Void*), CDoom::Statenum::S_TRACER, 0, 0},                                      # S_TRACER2
    {CDoom::Spritenum::SPR_FBXP, 32768, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TRACEEXP2, 0, 0},      # S_TRACEEXP1
    {CDoom::Spritenum::SPR_FBXP, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TRACEEXP3, 0, 0},      # S_TRACEEXP2
    {CDoom::Spritenum::SPR_FBXP, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_TRACEEXP3
    {CDoom::Spritenum::SPR_SKEL, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SKEL_STND2, 0, 0},                                       # S_SKEL_STND
    {CDoom::Spritenum::SPR_SKEL, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SKEL_STND, 0, 0},                                        # S_SKEL_STND2
    {CDoom::Spritenum::SPR_SKEL, 0, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN2, 0, 0},                                        # S_SKEL_RUN1
    {CDoom::Spritenum::SPR_SKEL, 0, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN3, 0, 0},                                        # S_SKEL_RUN2
    {CDoom::Spritenum::SPR_SKEL, 1, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN4, 0, 0},                                        # S_SKEL_RUN3
    {CDoom::Spritenum::SPR_SKEL, 1, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN5, 0, 0},                                        # S_SKEL_RUN4
    {CDoom::Spritenum::SPR_SKEL, 2, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN6, 0, 0},                                        # S_SKEL_RUN5
    {CDoom::Spritenum::SPR_SKEL, 2, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN7, 0, 0},                                        # S_SKEL_RUN6
    {CDoom::Spritenum::SPR_SKEL, 3, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN8, 0, 0},                                        # S_SKEL_RUN7
    {CDoom::Spritenum::SPR_SKEL, 3, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN9, 0, 0},                                        # S_SKEL_RUN8
    {CDoom::Spritenum::SPR_SKEL, 4, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN10, 0, 0},                                       # S_SKEL_RUN9
    {CDoom::Spritenum::SPR_SKEL, 4, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN11, 0, 0},                                       # S_SKEL_RUN10
    {CDoom::Spritenum::SPR_SKEL, 5, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN12, 0, 0},                                       # S_SKEL_RUN11
    {CDoom::Spritenum::SPR_SKEL, 5, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKEL_RUN1, 0, 0},                                        # S_SKEL_RUN12
    {CDoom::Spritenum::SPR_SKEL, 6, 0, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SKEL_FIST2, 0, 0},                                 # S_SKEL_FIST1
    {CDoom::Spritenum::SPR_SKEL, 6, 6, ->CDoom.a_skel_whoosh(Void*, Void*), CDoom::Statenum::S_SKEL_FIST3, 0, 0},                                 # S_SKEL_FIST2
    {CDoom::Spritenum::SPR_SKEL, 7, 6, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SKEL_FIST4, 0, 0},                                 # S_SKEL_FIST3
    {CDoom::Spritenum::SPR_SKEL, 8, 6, ->CDoom.a_skel_fist(Void*, Void*), CDoom::Statenum::S_SKEL_RUN1, 0, 0},                                    # S_SKEL_FIST4
    {CDoom::Spritenum::SPR_SKEL, 32777, 0, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SKEL_MISS2, 0, 0},                             # S_SKEL_MISS1
    {CDoom::Spritenum::SPR_SKEL, 32777, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SKEL_MISS3, 0, 0},                            # S_SKEL_MISS2
    {CDoom::Spritenum::SPR_SKEL, 10, 10, ->CDoom.a_skel_missile(Void*, Void*), CDoom::Statenum::S_SKEL_MISS4, 0, 0},                              # S_SKEL_MISS3
    {CDoom::Spritenum::SPR_SKEL, 10, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SKEL_RUN1, 0, 0},                                # S_SKEL_MISS4
    {CDoom::Spritenum::SPR_SKEL, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_PAIN2, 0, 0},        # S_SKEL_PAIN
    {CDoom::Spritenum::SPR_SKEL, 11, 5, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_SKEL_RUN1, 0, 0},                                        # S_SKEL_PAIN2
    {CDoom::Spritenum::SPR_SKEL, 11, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_DIE2, 0, 0},         # S_SKEL_DIE1
    {CDoom::Spritenum::SPR_SKEL, 12, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_DIE3, 0, 0},         # S_SKEL_DIE2
    {CDoom::Spritenum::SPR_SKEL, 13, 7, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_SKEL_DIE4, 0, 0},                                      # S_SKEL_DIE3
    {CDoom::Spritenum::SPR_SKEL, 14, 7, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SKEL_DIE5, 0, 0},                                        # S_SKEL_DIE4
    {CDoom::Spritenum::SPR_SKEL, 15, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_DIE6, 0, 0},         # S_SKEL_DIE5
    {CDoom::Spritenum::SPR_SKEL, 16, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_SKEL_DIE6
    {CDoom::Spritenum::SPR_SKEL, 16, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_RAISE2, 0, 0},       # S_SKEL_RAISE1
    {CDoom::Spritenum::SPR_SKEL, 15, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_RAISE3, 0, 0},       # S_SKEL_RAISE2
    {CDoom::Spritenum::SPR_SKEL, 14, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_RAISE4, 0, 0},       # S_SKEL_RAISE3
    {CDoom::Spritenum::SPR_SKEL, 13, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_RAISE5, 0, 0},       # S_SKEL_RAISE4
    {CDoom::Spritenum::SPR_SKEL, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_RAISE6, 0, 0},       # S_SKEL_RAISE5
    {CDoom::Spritenum::SPR_SKEL, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKEL_RUN1, 0, 0},         # S_SKEL_RAISE6
    {CDoom::Spritenum::SPR_MANF, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATSHOT2, 0, 0},       # S_FATSHOT1
    {CDoom::Spritenum::SPR_MANF, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATSHOT1, 0, 0},       # S_FATSHOT2
    {CDoom::Spritenum::SPR_MISL, 32769, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATSHOTX2, 0, 0},      # S_FATSHOTX1
    {CDoom::Spritenum::SPR_MISL, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATSHOTX3, 0, 0},      # S_FATSHOTX2
    {CDoom::Spritenum::SPR_MISL, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_FATSHOTX3
    {CDoom::Spritenum::SPR_FATT, 0, 15, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_FATT_STND2, 0, 0},                                       # S_FATT_STND
    {CDoom::Spritenum::SPR_FATT, 1, 15, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_FATT_STND, 0, 0},                                        # S_FATT_STND2
    {CDoom::Spritenum::SPR_FATT, 0, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN2, 0, 0},                                        # S_FATT_RUN1
    {CDoom::Spritenum::SPR_FATT, 0, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN3, 0, 0},                                        # S_FATT_RUN2
    {CDoom::Spritenum::SPR_FATT, 1, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN4, 0, 0},                                        # S_FATT_RUN3
    {CDoom::Spritenum::SPR_FATT, 1, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN5, 0, 0},                                        # S_FATT_RUN4
    {CDoom::Spritenum::SPR_FATT, 2, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN6, 0, 0},                                        # S_FATT_RUN5
    {CDoom::Spritenum::SPR_FATT, 2, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN7, 0, 0},                                        # S_FATT_RUN6
    {CDoom::Spritenum::SPR_FATT, 3, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN8, 0, 0},                                        # S_FATT_RUN7
    {CDoom::Spritenum::SPR_FATT, 3, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN9, 0, 0},                                        # S_FATT_RUN8
    {CDoom::Spritenum::SPR_FATT, 4, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN10, 0, 0},                                       # S_FATT_RUN9
    {CDoom::Spritenum::SPR_FATT, 4, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN11, 0, 0},                                       # S_FATT_RUN10
    {CDoom::Spritenum::SPR_FATT, 5, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN12, 0, 0},                                       # S_FATT_RUN11
    {CDoom::Spritenum::SPR_FATT, 5, 4, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_FATT_RUN1, 0, 0},                                        # S_FATT_RUN12
    {CDoom::Spritenum::SPR_FATT, 6, 20, ->CDoom.a_fat_raise(Void*, Void*), CDoom::Statenum::S_FATT_ATK2, 0, 0},                                   # S_FATT_ATK1
    {CDoom::Spritenum::SPR_FATT, 32775, 10, ->CDoom.a_fat_attack1(Void*, Void*), CDoom::Statenum::S_FATT_ATK3, 0, 0},                             # S_FATT_ATK2
    {CDoom::Spritenum::SPR_FATT, 8, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_FATT_ATK4, 0, 0},                                  # S_FATT_ATK3
    {CDoom::Spritenum::SPR_FATT, 6, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_FATT_ATK5, 0, 0},                                  # S_FATT_ATK4
    {CDoom::Spritenum::SPR_FATT, 32775, 10, ->CDoom.a_fat_attack2(Void*, Void*), CDoom::Statenum::S_FATT_ATK6, 0, 0},                             # S_FATT_ATK5
    {CDoom::Spritenum::SPR_FATT, 8, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_FATT_ATK7, 0, 0},                                  # S_FATT_ATK6
    {CDoom::Spritenum::SPR_FATT, 6, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_FATT_ATK8, 0, 0},                                  # S_FATT_ATK7
    {CDoom::Spritenum::SPR_FATT, 32775, 10, ->CDoom.a_fat_attack3(Void*, Void*), CDoom::Statenum::S_FATT_ATK9, 0, 0},                             # S_FATT_ATK8
    {CDoom::Spritenum::SPR_FATT, 8, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_FATT_ATK10, 0, 0},                                 # S_FATT_ATK9
    {CDoom::Spritenum::SPR_FATT, 6, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_FATT_RUN1, 0, 0},                                  # S_FATT_ATK10
    {CDoom::Spritenum::SPR_FATT, 9, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_PAIN2, 0, 0},         # S_FATT_PAIN
    {CDoom::Spritenum::SPR_FATT, 9, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_FATT_RUN1, 0, 0},                                         # S_FATT_PAIN2
    {CDoom::Spritenum::SPR_FATT, 10, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_DIE2, 0, 0},         # S_FATT_DIE1
    {CDoom::Spritenum::SPR_FATT, 11, 6, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_FATT_DIE3, 0, 0},                                      # S_FATT_DIE2
    {CDoom::Spritenum::SPR_FATT, 12, 6, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_FATT_DIE4, 0, 0},                                        # S_FATT_DIE3
    {CDoom::Spritenum::SPR_FATT, 13, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_DIE5, 0, 0},         # S_FATT_DIE4
    {CDoom::Spritenum::SPR_FATT, 14, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_DIE6, 0, 0},         # S_FATT_DIE5
    {CDoom::Spritenum::SPR_FATT, 15, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_DIE7, 0, 0},         # S_FATT_DIE6
    {CDoom::Spritenum::SPR_FATT, 16, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_DIE8, 0, 0},         # S_FATT_DIE7
    {CDoom::Spritenum::SPR_FATT, 17, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_DIE9, 0, 0},         # S_FATT_DIE8
    {CDoom::Spritenum::SPR_FATT, 18, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_DIE10, 0, 0},        # S_FATT_DIE9
    {CDoom::Spritenum::SPR_FATT, 19, -1, ->CDoom.a_boss_death(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                      # S_FATT_DIE10
    {CDoom::Spritenum::SPR_FATT, 17, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RAISE2, 0, 0},       # S_FATT_RAISE1
    {CDoom::Spritenum::SPR_FATT, 16, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RAISE3, 0, 0},       # S_FATT_RAISE2
    {CDoom::Spritenum::SPR_FATT, 15, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RAISE4, 0, 0},       # S_FATT_RAISE3
    {CDoom::Spritenum::SPR_FATT, 14, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RAISE5, 0, 0},       # S_FATT_RAISE4
    {CDoom::Spritenum::SPR_FATT, 13, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RAISE6, 0, 0},       # S_FATT_RAISE5
    {CDoom::Spritenum::SPR_FATT, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RAISE7, 0, 0},       # S_FATT_RAISE6
    {CDoom::Spritenum::SPR_FATT, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RAISE8, 0, 0},       # S_FATT_RAISE7
    {CDoom::Spritenum::SPR_FATT, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FATT_RUN1, 0, 0},         # S_FATT_RAISE8
    {CDoom::Spritenum::SPR_CPOS, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_CPOS_STND2, 0, 0},                                       # S_CPOS_STND
    {CDoom::Spritenum::SPR_CPOS, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_CPOS_STND, 0, 0},                                        # S_CPOS_STND2
    {CDoom::Spritenum::SPR_CPOS, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN2, 0, 0},                                        # S_CPOS_RUN1
    {CDoom::Spritenum::SPR_CPOS, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN3, 0, 0},                                        # S_CPOS_RUN2
    {CDoom::Spritenum::SPR_CPOS, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN4, 0, 0},                                        # S_CPOS_RUN3
    {CDoom::Spritenum::SPR_CPOS, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN5, 0, 0},                                        # S_CPOS_RUN4
    {CDoom::Spritenum::SPR_CPOS, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN6, 0, 0},                                        # S_CPOS_RUN5
    {CDoom::Spritenum::SPR_CPOS, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN7, 0, 0},                                        # S_CPOS_RUN6
    {CDoom::Spritenum::SPR_CPOS, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN8, 0, 0},                                        # S_CPOS_RUN7
    {CDoom::Spritenum::SPR_CPOS, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CPOS_RUN1, 0, 0},                                        # S_CPOS_RUN8
    {CDoom::Spritenum::SPR_CPOS, 4, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_CPOS_ATK2, 0, 0},                                 # S_CPOS_ATK1
    {CDoom::Spritenum::SPR_CPOS, 32773, 4, ->CDoom.a_cpos_attack(Void*, Void*), CDoom::Statenum::S_CPOS_ATK3, 0, 0},                              # S_CPOS_ATK2
    {CDoom::Spritenum::SPR_CPOS, 32772, 4, ->CDoom.a_cpos_attack(Void*, Void*), CDoom::Statenum::S_CPOS_ATK4, 0, 0},                              # S_CPOS_ATK3
    {CDoom::Spritenum::SPR_CPOS, 5, 1, ->CDoom.a_cpos_refire(Void*, Void*), CDoom::Statenum::S_CPOS_ATK2, 0, 0},                                  # S_CPOS_ATK4
    {CDoom::Spritenum::SPR_CPOS, 6, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_PAIN2, 0, 0},         # S_CPOS_PAIN
    {CDoom::Spritenum::SPR_CPOS, 6, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_CPOS_RUN1, 0, 0},                                         # S_CPOS_PAIN2
    {CDoom::Spritenum::SPR_CPOS, 7, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_DIE2, 0, 0},          # S_CPOS_DIE1
    {CDoom::Spritenum::SPR_CPOS, 8, 5, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_CPOS_DIE3, 0, 0},                                       # S_CPOS_DIE2
    {CDoom::Spritenum::SPR_CPOS, 9, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_CPOS_DIE4, 0, 0},                                         # S_CPOS_DIE3
    {CDoom::Spritenum::SPR_CPOS, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_DIE5, 0, 0},         # S_CPOS_DIE4
    {CDoom::Spritenum::SPR_CPOS, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_DIE6, 0, 0},         # S_CPOS_DIE5
    {CDoom::Spritenum::SPR_CPOS, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_DIE7, 0, 0},         # S_CPOS_DIE6
    {CDoom::Spritenum::SPR_CPOS, 13, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_CPOS_DIE7
    {CDoom::Spritenum::SPR_CPOS, 14, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_XDIE2, 0, 0},        # S_CPOS_XDIE1
    {CDoom::Spritenum::SPR_CPOS, 15, 5, ->CDoom.a_xscream(Void*, Void*), CDoom::Statenum::S_CPOS_XDIE3, 0, 0},                                    # S_CPOS_XDIE2
    {CDoom::Spritenum::SPR_CPOS, 16, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_CPOS_XDIE4, 0, 0},                                       # S_CPOS_XDIE3
    {CDoom::Spritenum::SPR_CPOS, 17, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_XDIE5, 0, 0},        # S_CPOS_XDIE4
    {CDoom::Spritenum::SPR_CPOS, 18, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_XDIE6, 0, 0},        # S_CPOS_XDIE5
    {CDoom::Spritenum::SPR_CPOS, 19, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_CPOS_XDIE6
    {CDoom::Spritenum::SPR_CPOS, 13, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_RAISE2, 0, 0},       # S_CPOS_RAISE1
    {CDoom::Spritenum::SPR_CPOS, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_RAISE3, 0, 0},       # S_CPOS_RAISE2
    {CDoom::Spritenum::SPR_CPOS, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_RAISE4, 0, 0},       # S_CPOS_RAISE3
    {CDoom::Spritenum::SPR_CPOS, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_RAISE5, 0, 0},       # S_CPOS_RAISE4
    {CDoom::Spritenum::SPR_CPOS, 9, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_RAISE6, 0, 0},        # S_CPOS_RAISE5
    {CDoom::Spritenum::SPR_CPOS, 8, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_RAISE7, 0, 0},        # S_CPOS_RAISE6
    {CDoom::Spritenum::SPR_CPOS, 7, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CPOS_RUN1, 0, 0},          # S_CPOS_RAISE7
    {CDoom::Spritenum::SPR_TROO, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_TROO_STND2, 0, 0},                                       # S_TROO_STND
    {CDoom::Spritenum::SPR_TROO, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_TROO_STND, 0, 0},                                        # S_TROO_STND2
    {CDoom::Spritenum::SPR_TROO, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN2, 0, 0},                                        # S_TROO_RUN1
    {CDoom::Spritenum::SPR_TROO, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN3, 0, 0},                                        # S_TROO_RUN2
    {CDoom::Spritenum::SPR_TROO, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN4, 0, 0},                                        # S_TROO_RUN3
    {CDoom::Spritenum::SPR_TROO, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN5, 0, 0},                                        # S_TROO_RUN4
    {CDoom::Spritenum::SPR_TROO, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN6, 0, 0},                                        # S_TROO_RUN5
    {CDoom::Spritenum::SPR_TROO, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN7, 0, 0},                                        # S_TROO_RUN6
    {CDoom::Spritenum::SPR_TROO, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN8, 0, 0},                                        # S_TROO_RUN7
    {CDoom::Spritenum::SPR_TROO, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_TROO_RUN1, 0, 0},                                        # S_TROO_RUN8
    {CDoom::Spritenum::SPR_TROO, 4, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_TROO_ATK2, 0, 0},                                  # S_TROO_ATK1
    {CDoom::Spritenum::SPR_TROO, 5, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_TROO_ATK3, 0, 0},                                  # S_TROO_ATK2
    {CDoom::Spritenum::SPR_TROO, 6, 6, ->CDoom.a_troop_attack(Void*, Void*), CDoom::Statenum::S_TROO_RUN1, 0, 0},                                 # S_TROO_ATK3
    {CDoom::Spritenum::SPR_TROO, 7, 2, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_PAIN2, 0, 0},         # S_TROO_PAIN
    {CDoom::Spritenum::SPR_TROO, 7, 2, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_TROO_RUN1, 0, 0},                                         # S_TROO_PAIN2
    {CDoom::Spritenum::SPR_TROO, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_DIE2, 0, 0},          # S_TROO_DIE1
    {CDoom::Spritenum::SPR_TROO, 9, 8, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_TROO_DIE3, 0, 0},                                       # S_TROO_DIE2
    {CDoom::Spritenum::SPR_TROO, 10, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_DIE4, 0, 0},         # S_TROO_DIE3
    {CDoom::Spritenum::SPR_TROO, 11, 6, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_TROO_DIE5, 0, 0},                                        # S_TROO_DIE4
    {CDoom::Spritenum::SPR_TROO, 12, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_TROO_DIE5
    {CDoom::Spritenum::SPR_TROO, 13, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_XDIE2, 0, 0},        # S_TROO_XDIE1
    {CDoom::Spritenum::SPR_TROO, 14, 5, ->CDoom.a_xscream(Void*, Void*), CDoom::Statenum::S_TROO_XDIE3, 0, 0},                                    # S_TROO_XDIE2
    {CDoom::Spritenum::SPR_TROO, 15, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_XDIE4, 0, 0},        # S_TROO_XDIE3
    {CDoom::Spritenum::SPR_TROO, 16, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_TROO_XDIE5, 0, 0},                                       # S_TROO_XDIE4
    {CDoom::Spritenum::SPR_TROO, 17, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_XDIE6, 0, 0},        # S_TROO_XDIE5
    {CDoom::Spritenum::SPR_TROO, 18, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_XDIE7, 0, 0},        # S_TROO_XDIE6
    {CDoom::Spritenum::SPR_TROO, 19, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_XDIE8, 0, 0},        # S_TROO_XDIE7
    {CDoom::Spritenum::SPR_TROO, 20, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_TROO_XDIE8
    {CDoom::Spritenum::SPR_TROO, 12, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_RAISE2, 0, 0},       # S_TROO_RAISE1
    {CDoom::Spritenum::SPR_TROO, 11, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_RAISE3, 0, 0},       # S_TROO_RAISE2
    {CDoom::Spritenum::SPR_TROO, 10, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_RAISE4, 0, 0},       # S_TROO_RAISE3
    {CDoom::Spritenum::SPR_TROO, 9, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_RAISE5, 0, 0},        # S_TROO_RAISE4
    {CDoom::Spritenum::SPR_TROO, 8, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TROO_RUN1, 0, 0},          # S_TROO_RAISE5
    {CDoom::Spritenum::SPR_SARG, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SARG_STND2, 0, 0},                                       # S_SARG_STND
    {CDoom::Spritenum::SPR_SARG, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SARG_STND, 0, 0},                                        # S_SARG_STND2
    {CDoom::Spritenum::SPR_SARG, 0, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN2, 0, 0},                                        # S_SARG_RUN1
    {CDoom::Spritenum::SPR_SARG, 0, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN3, 0, 0},                                        # S_SARG_RUN2
    {CDoom::Spritenum::SPR_SARG, 1, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN4, 0, 0},                                        # S_SARG_RUN3
    {CDoom::Spritenum::SPR_SARG, 1, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN5, 0, 0},                                        # S_SARG_RUN4
    {CDoom::Spritenum::SPR_SARG, 2, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN6, 0, 0},                                        # S_SARG_RUN5
    {CDoom::Spritenum::SPR_SARG, 2, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN7, 0, 0},                                        # S_SARG_RUN6
    {CDoom::Spritenum::SPR_SARG, 3, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN8, 0, 0},                                        # S_SARG_RUN7
    {CDoom::Spritenum::SPR_SARG, 3, 2, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SARG_RUN1, 0, 0},                                        # S_SARG_RUN8
    {CDoom::Spritenum::SPR_SARG, 4, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SARG_ATK2, 0, 0},                                  # S_SARG_ATK1
    {CDoom::Spritenum::SPR_SARG, 5, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SARG_ATK3, 0, 0},                                  # S_SARG_ATK2
    {CDoom::Spritenum::SPR_SARG, 6, 8, ->CDoom.a_sarg_attack(Void*, Void*), CDoom::Statenum::S_SARG_RUN1, 0, 0},                                  # S_SARG_ATK3
    {CDoom::Spritenum::SPR_SARG, 7, 2, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_PAIN2, 0, 0},         # S_SARG_PAIN
    {CDoom::Spritenum::SPR_SARG, 7, 2, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_SARG_RUN1, 0, 0},                                         # S_SARG_PAIN2
    {CDoom::Spritenum::SPR_SARG, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_DIE2, 0, 0},          # S_SARG_DIE1
    {CDoom::Spritenum::SPR_SARG, 9, 8, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_SARG_DIE3, 0, 0},                                       # S_SARG_DIE2
    {CDoom::Spritenum::SPR_SARG, 10, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_DIE4, 0, 0},         # S_SARG_DIE3
    {CDoom::Spritenum::SPR_SARG, 11, 4, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SARG_DIE5, 0, 0},                                        # S_SARG_DIE4
    {CDoom::Spritenum::SPR_SARG, 12, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_DIE6, 0, 0},         # S_SARG_DIE5
    {CDoom::Spritenum::SPR_SARG, 13, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_SARG_DIE6
    {CDoom::Spritenum::SPR_SARG, 13, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_RAISE2, 0, 0},       # S_SARG_RAISE1
    {CDoom::Spritenum::SPR_SARG, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_RAISE3, 0, 0},       # S_SARG_RAISE2
    {CDoom::Spritenum::SPR_SARG, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_RAISE4, 0, 0},       # S_SARG_RAISE3
    {CDoom::Spritenum::SPR_SARG, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_RAISE5, 0, 0},       # S_SARG_RAISE4
    {CDoom::Spritenum::SPR_SARG, 9, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_RAISE6, 0, 0},        # S_SARG_RAISE5
    {CDoom::Spritenum::SPR_SARG, 8, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SARG_RUN1, 0, 0},          # S_SARG_RAISE6
    {CDoom::Spritenum::SPR_HEAD, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_HEAD_STND, 0, 0},                                        # S_HEAD_STND
    {CDoom::Spritenum::SPR_HEAD, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_HEAD_RUN1, 0, 0},                                        # S_HEAD_RUN1
    {CDoom::Spritenum::SPR_HEAD, 1, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_HEAD_ATK2, 0, 0},                                  # S_HEAD_ATK1
    {CDoom::Spritenum::SPR_HEAD, 2, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_HEAD_ATK3, 0, 0},                                  # S_HEAD_ATK2
    {CDoom::Spritenum::SPR_HEAD, 32771, 5, ->CDoom.a_head_attack(Void*, Void*), CDoom::Statenum::S_HEAD_RUN1, 0, 0},                              # S_HEAD_ATK3
    {CDoom::Spritenum::SPR_HEAD, 4, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_PAIN2, 0, 0},         # S_HEAD_PAIN
    {CDoom::Spritenum::SPR_HEAD, 4, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_HEAD_PAIN3, 0, 0},                                        # S_HEAD_PAIN2
    {CDoom::Spritenum::SPR_HEAD, 5, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_RUN1, 0, 0},          # S_HEAD_PAIN3
    {CDoom::Spritenum::SPR_HEAD, 6, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_DIE2, 0, 0},          # S_HEAD_DIE1
    {CDoom::Spritenum::SPR_HEAD, 7, 8, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_HEAD_DIE3, 0, 0},                                       # S_HEAD_DIE2
    {CDoom::Spritenum::SPR_HEAD, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_DIE4, 0, 0},          # S_HEAD_DIE3
    {CDoom::Spritenum::SPR_HEAD, 9, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_DIE5, 0, 0},          # S_HEAD_DIE4
    {CDoom::Spritenum::SPR_HEAD, 10, 8, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_HEAD_DIE6, 0, 0},                                        # S_HEAD_DIE5
    {CDoom::Spritenum::SPR_HEAD, 11, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_HEAD_DIE6
    {CDoom::Spritenum::SPR_HEAD, 11, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_RAISE2, 0, 0},       # S_HEAD_RAISE1
    {CDoom::Spritenum::SPR_HEAD, 10, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_RAISE3, 0, 0},       # S_HEAD_RAISE2
    {CDoom::Spritenum::SPR_HEAD, 9, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_RAISE4, 0, 0},        # S_HEAD_RAISE3
    {CDoom::Spritenum::SPR_HEAD, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_RAISE5, 0, 0},        # S_HEAD_RAISE4
    {CDoom::Spritenum::SPR_HEAD, 7, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_RAISE6, 0, 0},        # S_HEAD_RAISE5
    {CDoom::Spritenum::SPR_HEAD, 6, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEAD_RUN1, 0, 0},          # S_HEAD_RAISE6
    {CDoom::Spritenum::SPR_BAL7, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRBALL2, 0, 0},        # S_BRBALL1
    {CDoom::Spritenum::SPR_BAL7, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRBALL1, 0, 0},        # S_BRBALL2
    {CDoom::Spritenum::SPR_BAL7, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRBALLX2, 0, 0},       # S_BRBALLX1
    {CDoom::Spritenum::SPR_BAL7, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRBALLX3, 0, 0},       # S_BRBALLX2
    {CDoom::Spritenum::SPR_BAL7, 32772, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_BRBALLX3
    {CDoom::Spritenum::SPR_BOSS, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_BOSS_STND2, 0, 0},                                       # S_BOSS_STND
    {CDoom::Spritenum::SPR_BOSS, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_BOSS_STND, 0, 0},                                        # S_BOSS_STND2
    {CDoom::Spritenum::SPR_BOSS, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN2, 0, 0},                                        # S_BOSS_RUN1
    {CDoom::Spritenum::SPR_BOSS, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN3, 0, 0},                                        # S_BOSS_RUN2
    {CDoom::Spritenum::SPR_BOSS, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN4, 0, 0},                                        # S_BOSS_RUN3
    {CDoom::Spritenum::SPR_BOSS, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN5, 0, 0},                                        # S_BOSS_RUN4
    {CDoom::Spritenum::SPR_BOSS, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN6, 0, 0},                                        # S_BOSS_RUN5
    {CDoom::Spritenum::SPR_BOSS, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN7, 0, 0},                                        # S_BOSS_RUN6
    {CDoom::Spritenum::SPR_BOSS, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN8, 0, 0},                                        # S_BOSS_RUN7
    {CDoom::Spritenum::SPR_BOSS, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOSS_RUN1, 0, 0},                                        # S_BOSS_RUN8
    {CDoom::Spritenum::SPR_BOSS, 4, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_BOSS_ATK2, 0, 0},                                  # S_BOSS_ATK1
    {CDoom::Spritenum::SPR_BOSS, 5, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_BOSS_ATK3, 0, 0},                                  # S_BOSS_ATK2
    {CDoom::Spritenum::SPR_BOSS, 6, 8, ->CDoom.a_bruis_attack(Void*, Void*), CDoom::Statenum::S_BOSS_RUN1, 0, 0},                                 # S_BOSS_ATK3
    {CDoom::Spritenum::SPR_BOSS, 7, 2, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_PAIN2, 0, 0},         # S_BOSS_PAIN
    {CDoom::Spritenum::SPR_BOSS, 7, 2, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_BOSS_RUN1, 0, 0},                                         # S_BOSS_PAIN2
    {CDoom::Spritenum::SPR_BOSS, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_DIE2, 0, 0},          # S_BOSS_DIE1
    {CDoom::Spritenum::SPR_BOSS, 9, 8, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_BOSS_DIE3, 0, 0},                                       # S_BOSS_DIE2
    {CDoom::Spritenum::SPR_BOSS, 10, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_DIE4, 0, 0},         # S_BOSS_DIE3
    {CDoom::Spritenum::SPR_BOSS, 11, 8, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_BOSS_DIE5, 0, 0},                                        # S_BOSS_DIE4
    {CDoom::Spritenum::SPR_BOSS, 12, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_DIE6, 0, 0},         # S_BOSS_DIE5
    {CDoom::Spritenum::SPR_BOSS, 13, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_DIE7, 0, 0},         # S_BOSS_DIE6
    {CDoom::Spritenum::SPR_BOSS, 14, -1, ->CDoom.a_boss_death(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                      # S_BOSS_DIE7
    {CDoom::Spritenum::SPR_BOSS, 14, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_RAISE2, 0, 0},       # S_BOSS_RAISE1
    {CDoom::Spritenum::SPR_BOSS, 13, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_RAISE3, 0, 0},       # S_BOSS_RAISE2
    {CDoom::Spritenum::SPR_BOSS, 12, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_RAISE4, 0, 0},       # S_BOSS_RAISE3
    {CDoom::Spritenum::SPR_BOSS, 11, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_RAISE5, 0, 0},       # S_BOSS_RAISE4
    {CDoom::Spritenum::SPR_BOSS, 10, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_RAISE6, 0, 0},       # S_BOSS_RAISE5
    {CDoom::Spritenum::SPR_BOSS, 9, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_RAISE7, 0, 0},        # S_BOSS_RAISE6
    {CDoom::Spritenum::SPR_BOSS, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOSS_RUN1, 0, 0},          # S_BOSS_RAISE7
    {CDoom::Spritenum::SPR_BOS2, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_BOS2_STND2, 0, 0},                                       # S_BOS2_STND
    {CDoom::Spritenum::SPR_BOS2, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_BOS2_STND, 0, 0},                                        # S_BOS2_STND2
    {CDoom::Spritenum::SPR_BOS2, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN2, 0, 0},                                        # S_BOS2_RUN1
    {CDoom::Spritenum::SPR_BOS2, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN3, 0, 0},                                        # S_BOS2_RUN2
    {CDoom::Spritenum::SPR_BOS2, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN4, 0, 0},                                        # S_BOS2_RUN3
    {CDoom::Spritenum::SPR_BOS2, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN5, 0, 0},                                        # S_BOS2_RUN4
    {CDoom::Spritenum::SPR_BOS2, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN6, 0, 0},                                        # S_BOS2_RUN5
    {CDoom::Spritenum::SPR_BOS2, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN7, 0, 0},                                        # S_BOS2_RUN6
    {CDoom::Spritenum::SPR_BOS2, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN8, 0, 0},                                        # S_BOS2_RUN7
    {CDoom::Spritenum::SPR_BOS2, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BOS2_RUN1, 0, 0},                                        # S_BOS2_RUN8
    {CDoom::Spritenum::SPR_BOS2, 4, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_BOS2_ATK2, 0, 0},                                  # S_BOS2_ATK1
    {CDoom::Spritenum::SPR_BOS2, 5, 8, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_BOS2_ATK3, 0, 0},                                  # S_BOS2_ATK2
    {CDoom::Spritenum::SPR_BOS2, 6, 8, ->CDoom.a_bruis_attack(Void*, Void*), CDoom::Statenum::S_BOS2_RUN1, 0, 0},                                 # S_BOS2_ATK3
    {CDoom::Spritenum::SPR_BOS2, 7, 2, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_PAIN2, 0, 0},         # S_BOS2_PAIN
    {CDoom::Spritenum::SPR_BOS2, 7, 2, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_BOS2_RUN1, 0, 0},                                         # S_BOS2_PAIN2
    {CDoom::Spritenum::SPR_BOS2, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_DIE2, 0, 0},          # S_BOS2_DIE1
    {CDoom::Spritenum::SPR_BOS2, 9, 8, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_BOS2_DIE3, 0, 0},                                       # S_BOS2_DIE2
    {CDoom::Spritenum::SPR_BOS2, 10, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_DIE4, 0, 0},         # S_BOS2_DIE3
    {CDoom::Spritenum::SPR_BOS2, 11, 8, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_BOS2_DIE5, 0, 0},                                        # S_BOS2_DIE4
    {CDoom::Spritenum::SPR_BOS2, 12, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_DIE6, 0, 0},         # S_BOS2_DIE5
    {CDoom::Spritenum::SPR_BOS2, 13, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_DIE7, 0, 0},         # S_BOS2_DIE6
    {CDoom::Spritenum::SPR_BOS2, 14, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_BOS2_DIE7
    {CDoom::Spritenum::SPR_BOS2, 14, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_RAISE2, 0, 0},       # S_BOS2_RAISE1
    {CDoom::Spritenum::SPR_BOS2, 13, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_RAISE3, 0, 0},       # S_BOS2_RAISE2
    {CDoom::Spritenum::SPR_BOS2, 12, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_RAISE4, 0, 0},       # S_BOS2_RAISE3
    {CDoom::Spritenum::SPR_BOS2, 11, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_RAISE5, 0, 0},       # S_BOS2_RAISE4
    {CDoom::Spritenum::SPR_BOS2, 10, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_RAISE6, 0, 0},       # S_BOS2_RAISE5
    {CDoom::Spritenum::SPR_BOS2, 9, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_RAISE7, 0, 0},        # S_BOS2_RAISE6
    {CDoom::Spritenum::SPR_BOS2, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BOS2_RUN1, 0, 0},          # S_BOS2_RAISE7
    {CDoom::Spritenum::SPR_SKUL, 32768, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SKULL_STND2, 0, 0},                                  # S_SKULL_STND
    {CDoom::Spritenum::SPR_SKUL, 32769, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SKULL_STND, 0, 0},                                   # S_SKULL_STND2
    {CDoom::Spritenum::SPR_SKUL, 32768, 6, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKULL_RUN2, 0, 0},                                   # S_SKULL_RUN1
    {CDoom::Spritenum::SPR_SKUL, 32769, 6, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SKULL_RUN1, 0, 0},                                   # S_SKULL_RUN2
    {CDoom::Spritenum::SPR_SKUL, 32770, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SKULL_ATK2, 0, 0},                            # S_SKULL_ATK1
    {CDoom::Spritenum::SPR_SKUL, 32771, 4, ->CDoom.a_skull_attack(Void*, Void*), CDoom::Statenum::S_SKULL_ATK3, 0, 0},                            # S_SKULL_ATK2
    {CDoom::Spritenum::SPR_SKUL, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKULL_ATK4, 0, 0},     # S_SKULL_ATK3
    {CDoom::Spritenum::SPR_SKUL, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKULL_ATK3, 0, 0},     # S_SKULL_ATK4
    {CDoom::Spritenum::SPR_SKUL, 32772, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKULL_PAIN2, 0, 0},    # S_SKULL_PAIN
    {CDoom::Spritenum::SPR_SKUL, 32772, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_SKULL_RUN1, 0, 0},                                    # S_SKULL_PAIN2
    {CDoom::Spritenum::SPR_SKUL, 32773, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKULL_DIE2, 0, 0},     # S_SKULL_DIE1
    {CDoom::Spritenum::SPR_SKUL, 32774, 6, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_SKULL_DIE3, 0, 0},                                  # S_SKULL_DIE2
    {CDoom::Spritenum::SPR_SKUL, 32775, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKULL_DIE4, 0, 0},     # S_SKULL_DIE3
    {CDoom::Spritenum::SPR_SKUL, 32776, 6, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SKULL_DIE5, 0, 0},                                    # S_SKULL_DIE4
    {CDoom::Spritenum::SPR_SKUL, 9, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SKULL_DIE6, 0, 0},         # S_SKULL_DIE5
    {CDoom::Spritenum::SPR_SKUL, 10, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SKULL_DIE6
    {CDoom::Spritenum::SPR_SPID, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SPID_STND2, 0, 0},                                       # S_SPID_STND
    {CDoom::Spritenum::SPR_SPID, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SPID_STND, 0, 0},                                        # S_SPID_STND2
    {CDoom::Spritenum::SPR_SPID, 0, 3, ->CDoom.a_metal(Void*, Void*), CDoom::Statenum::S_SPID_RUN2, 0, 0},                                        # S_SPID_RUN1
    {CDoom::Spritenum::SPR_SPID, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN3, 0, 0},                                        # S_SPID_RUN2
    {CDoom::Spritenum::SPR_SPID, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN4, 0, 0},                                        # S_SPID_RUN3
    {CDoom::Spritenum::SPR_SPID, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN5, 0, 0},                                        # S_SPID_RUN4
    {CDoom::Spritenum::SPR_SPID, 2, 3, ->CDoom.a_metal(Void*, Void*), CDoom::Statenum::S_SPID_RUN6, 0, 0},                                        # S_SPID_RUN5
    {CDoom::Spritenum::SPR_SPID, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN7, 0, 0},                                        # S_SPID_RUN6
    {CDoom::Spritenum::SPR_SPID, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN8, 0, 0},                                        # S_SPID_RUN7
    {CDoom::Spritenum::SPR_SPID, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN9, 0, 0},                                        # S_SPID_RUN8
    {CDoom::Spritenum::SPR_SPID, 4, 3, ->CDoom.a_metal(Void*, Void*), CDoom::Statenum::S_SPID_RUN10, 0, 0},                                       # S_SPID_RUN9
    {CDoom::Spritenum::SPR_SPID, 4, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN11, 0, 0},                                       # S_SPID_RUN10
    {CDoom::Spritenum::SPR_SPID, 5, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN12, 0, 0},                                       # S_SPID_RUN11
    {CDoom::Spritenum::SPR_SPID, 5, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SPID_RUN1, 0, 0},                                        # S_SPID_RUN12
    {CDoom::Spritenum::SPR_SPID, 32768, 20, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SPID_ATK2, 0, 0},                             # S_SPID_ATK1
    {CDoom::Spritenum::SPR_SPID, 32774, 4, ->CDoom.a_spos_attack(Void*, Void*), CDoom::Statenum::S_SPID_ATK3, 0, 0},                              # S_SPID_ATK2
    {CDoom::Spritenum::SPR_SPID, 32775, 4, ->CDoom.a_spos_attack(Void*, Void*), CDoom::Statenum::S_SPID_ATK4, 0, 0},                              # S_SPID_ATK3
    {CDoom::Spritenum::SPR_SPID, 32775, 1, ->CDoom.a_spid_refire(Void*, Void*), CDoom::Statenum::S_SPID_ATK2, 0, 0},                              # S_SPID_ATK4
    {CDoom::Spritenum::SPR_SPID, 8, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_PAIN2, 0, 0},         # S_SPID_PAIN
    {CDoom::Spritenum::SPR_SPID, 8, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_SPID_RUN1, 0, 0},                                         # S_SPID_PAIN2
    {CDoom::Spritenum::SPR_SPID, 9, 20, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_SPID_DIE2, 0, 0},                                      # S_SPID_DIE1
    {CDoom::Spritenum::SPR_SPID, 10, 10, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SPID_DIE3, 0, 0},                                       # S_SPID_DIE2
    {CDoom::Spritenum::SPR_SPID, 11, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE4, 0, 0},        # S_SPID_DIE3
    {CDoom::Spritenum::SPR_SPID, 12, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE5, 0, 0},        # S_SPID_DIE4
    {CDoom::Spritenum::SPR_SPID, 13, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE6, 0, 0},        # S_SPID_DIE5
    {CDoom::Spritenum::SPR_SPID, 14, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE7, 0, 0},        # S_SPID_DIE6
    {CDoom::Spritenum::SPR_SPID, 15, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE8, 0, 0},        # S_SPID_DIE7
    {CDoom::Spritenum::SPR_SPID, 16, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE9, 0, 0},        # S_SPID_DIE8
    {CDoom::Spritenum::SPR_SPID, 17, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE10, 0, 0},       # S_SPID_DIE9
    {CDoom::Spritenum::SPR_SPID, 18, 30, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SPID_DIE11, 0, 0},       # S_SPID_DIE10
    {CDoom::Spritenum::SPR_SPID, 18, -1, ->CDoom.a_boss_death(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                      # S_SPID_DIE11
    {CDoom::Spritenum::SPR_BSPI, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_BSPI_STND2, 0, 0},                                       # S_BSPI_STND
    {CDoom::Spritenum::SPR_BSPI, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_BSPI_STND, 0, 0},                                        # S_BSPI_STND2
    {CDoom::Spritenum::SPR_BSPI, 0, 20, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RUN1, 0, 0},         # S_BSPI_SIGHT
    {CDoom::Spritenum::SPR_BSPI, 0, 3, ->CDoom.a_baby_metal(Void*, Void*), CDoom::Statenum::S_BSPI_RUN2, 0, 0},                                   # S_BSPI_RUN1
    {CDoom::Spritenum::SPR_BSPI, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN3, 0, 0},                                        # S_BSPI_RUN2
    {CDoom::Spritenum::SPR_BSPI, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN4, 0, 0},                                        # S_BSPI_RUN3
    {CDoom::Spritenum::SPR_BSPI, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN5, 0, 0},                                        # S_BSPI_RUN4
    {CDoom::Spritenum::SPR_BSPI, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN6, 0, 0},                                        # S_BSPI_RUN5
    {CDoom::Spritenum::SPR_BSPI, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN7, 0, 0},                                        # S_BSPI_RUN6
    {CDoom::Spritenum::SPR_BSPI, 3, 3, ->CDoom.a_baby_metal(Void*, Void*), CDoom::Statenum::S_BSPI_RUN8, 0, 0},                                   # S_BSPI_RUN7
    {CDoom::Spritenum::SPR_BSPI, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN9, 0, 0},                                        # S_BSPI_RUN8
    {CDoom::Spritenum::SPR_BSPI, 4, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN10, 0, 0},                                       # S_BSPI_RUN9
    {CDoom::Spritenum::SPR_BSPI, 4, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN11, 0, 0},                                       # S_BSPI_RUN10
    {CDoom::Spritenum::SPR_BSPI, 5, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN12, 0, 0},                                       # S_BSPI_RUN11
    {CDoom::Spritenum::SPR_BSPI, 5, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_BSPI_RUN1, 0, 0},                                        # S_BSPI_RUN12
    {CDoom::Spritenum::SPR_BSPI, 32768, 20, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_BSPI_ATK2, 0, 0},                             # S_BSPI_ATK1
    {CDoom::Spritenum::SPR_BSPI, 32774, 4, ->CDoom.a_bspi_attack(Void*, Void*), CDoom::Statenum::S_BSPI_ATK3, 0, 0},                              # S_BSPI_ATK2
    {CDoom::Spritenum::SPR_BSPI, 32775, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_ATK4, 0, 0},      # S_BSPI_ATK3
    {CDoom::Spritenum::SPR_BSPI, 32775, 1, ->CDoom.a_spid_refire(Void*, Void*), CDoom::Statenum::S_BSPI_ATK2, 0, 0},                              # S_BSPI_ATK4
    {CDoom::Spritenum::SPR_BSPI, 8, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_PAIN2, 0, 0},         # S_BSPI_PAIN
    {CDoom::Spritenum::SPR_BSPI, 8, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_BSPI_RUN1, 0, 0},                                         # S_BSPI_PAIN2
    {CDoom::Spritenum::SPR_BSPI, 9, 20, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_BSPI_DIE2, 0, 0},                                      # S_BSPI_DIE1
    {CDoom::Spritenum::SPR_BSPI, 10, 7, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_BSPI_DIE3, 0, 0},                                        # S_BSPI_DIE2
    {CDoom::Spritenum::SPR_BSPI, 11, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_DIE4, 0, 0},         # S_BSPI_DIE3
    {CDoom::Spritenum::SPR_BSPI, 12, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_DIE5, 0, 0},         # S_BSPI_DIE4
    {CDoom::Spritenum::SPR_BSPI, 13, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_DIE6, 0, 0},         # S_BSPI_DIE5
    {CDoom::Spritenum::SPR_BSPI, 14, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_DIE7, 0, 0},         # S_BSPI_DIE6
    {CDoom::Spritenum::SPR_BSPI, 15, -1, ->CDoom.a_boss_death(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                      # S_BSPI_DIE7
    {CDoom::Spritenum::SPR_BSPI, 15, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RAISE2, 0, 0},       # S_BSPI_RAISE1
    {CDoom::Spritenum::SPR_BSPI, 14, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RAISE3, 0, 0},       # S_BSPI_RAISE2
    {CDoom::Spritenum::SPR_BSPI, 13, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RAISE4, 0, 0},       # S_BSPI_RAISE3
    {CDoom::Spritenum::SPR_BSPI, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RAISE5, 0, 0},       # S_BSPI_RAISE4
    {CDoom::Spritenum::SPR_BSPI, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RAISE6, 0, 0},       # S_BSPI_RAISE5
    {CDoom::Spritenum::SPR_BSPI, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RAISE7, 0, 0},       # S_BSPI_RAISE6
    {CDoom::Spritenum::SPR_BSPI, 9, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSPI_RUN1, 0, 0},          # S_BSPI_RAISE7
    {CDoom::Spritenum::SPR_APLS, 32768, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARACH_PLAZ2, 0, 0},    # S_ARACH_PLAZ
    {CDoom::Spritenum::SPR_APLS, 32769, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARACH_PLAZ, 0, 0},     # S_ARACH_PLAZ2
    {CDoom::Spritenum::SPR_APBX, 32768, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARACH_PLEX2, 0, 0},    # S_ARACH_PLEX
    {CDoom::Spritenum::SPR_APBX, 32769, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARACH_PLEX3, 0, 0},    # S_ARACH_PLEX2
    {CDoom::Spritenum::SPR_APBX, 32770, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARACH_PLEX4, 0, 0},    # S_ARACH_PLEX3
    {CDoom::Spritenum::SPR_APBX, 32771, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARACH_PLEX5, 0, 0},    # S_ARACH_PLEX4
    {CDoom::Spritenum::SPR_APBX, 32772, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_ARACH_PLEX5
    {CDoom::Spritenum::SPR_CYBR, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_CYBER_STND2, 0, 0},                                      # S_CYBER_STND
    {CDoom::Spritenum::SPR_CYBR, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_CYBER_STND, 0, 0},                                       # S_CYBER_STND2
    {CDoom::Spritenum::SPR_CYBR, 0, 3, ->CDoom.a_hoof(Void*, Void*), CDoom::Statenum::S_CYBER_RUN2, 0, 0},                                        # S_CYBER_RUN1
    {CDoom::Spritenum::SPR_CYBR, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CYBER_RUN3, 0, 0},                                       # S_CYBER_RUN2
    {CDoom::Spritenum::SPR_CYBR, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CYBER_RUN4, 0, 0},                                       # S_CYBER_RUN3
    {CDoom::Spritenum::SPR_CYBR, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CYBER_RUN5, 0, 0},                                       # S_CYBER_RUN4
    {CDoom::Spritenum::SPR_CYBR, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CYBER_RUN6, 0, 0},                                       # S_CYBER_RUN5
    {CDoom::Spritenum::SPR_CYBR, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CYBER_RUN7, 0, 0},                                       # S_CYBER_RUN6
    {CDoom::Spritenum::SPR_CYBR, 3, 3, ->CDoom.a_metal(Void*, Void*), CDoom::Statenum::S_CYBER_RUN8, 0, 0},                                       # S_CYBER_RUN7
    {CDoom::Spritenum::SPR_CYBR, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_CYBER_RUN1, 0, 0},                                       # S_CYBER_RUN8
    {CDoom::Spritenum::SPR_CYBR, 4, 6, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_CYBER_ATK2, 0, 0},                                 # S_CYBER_ATK1
    {CDoom::Spritenum::SPR_CYBR, 5, 12, ->CDoom.a_cyber_attack(Void*, Void*), CDoom::Statenum::S_CYBER_ATK3, 0, 0},                               # S_CYBER_ATK2
    {CDoom::Spritenum::SPR_CYBR, 4, 12, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_CYBER_ATK4, 0, 0},                                # S_CYBER_ATK3
    {CDoom::Spritenum::SPR_CYBR, 5, 12, ->CDoom.a_cyber_attack(Void*, Void*), CDoom::Statenum::S_CYBER_ATK5, 0, 0},                               # S_CYBER_ATK4
    {CDoom::Spritenum::SPR_CYBR, 4, 12, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_CYBER_ATK6, 0, 0},                                # S_CYBER_ATK5
    {CDoom::Spritenum::SPR_CYBR, 5, 12, ->CDoom.a_cyber_attack(Void*, Void*), CDoom::Statenum::S_CYBER_RUN1, 0, 0},                               # S_CYBER_ATK6
    {CDoom::Spritenum::SPR_CYBR, 6, 10, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_CYBER_RUN1, 0, 0},                                       # S_CYBER_PAIN
    {CDoom::Spritenum::SPR_CYBR, 7, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CYBER_DIE2, 0, 0},        # S_CYBER_DIE1
    {CDoom::Spritenum::SPR_CYBR, 8, 10, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_CYBER_DIE3, 0, 0},                                     # S_CYBER_DIE2
    {CDoom::Spritenum::SPR_CYBR, 9, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CYBER_DIE4, 0, 0},        # S_CYBER_DIE3
    {CDoom::Spritenum::SPR_CYBR, 10, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CYBER_DIE5, 0, 0},       # S_CYBER_DIE4
    {CDoom::Spritenum::SPR_CYBR, 11, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CYBER_DIE6, 0, 0},       # S_CYBER_DIE5
    {CDoom::Spritenum::SPR_CYBR, 12, 10, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_CYBER_DIE7, 0, 0},                                      # S_CYBER_DIE6
    {CDoom::Spritenum::SPR_CYBR, 13, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CYBER_DIE8, 0, 0},       # S_CYBER_DIE7
    {CDoom::Spritenum::SPR_CYBR, 14, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CYBER_DIE9, 0, 0},       # S_CYBER_DIE8
    {CDoom::Spritenum::SPR_CYBR, 15, 30, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_CYBER_DIE10, 0, 0},      # S_CYBER_DIE9
    {CDoom::Spritenum::SPR_CYBR, 15, -1, ->CDoom.a_boss_death(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                      # S_CYBER_DIE10
    {CDoom::Spritenum::SPR_PAIN, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_PAIN_STND, 0, 0},                                        # S_PAIN_STND
    {CDoom::Spritenum::SPR_PAIN, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_PAIN_RUN2, 0, 0},                                        # S_PAIN_RUN1
    {CDoom::Spritenum::SPR_PAIN, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_PAIN_RUN3, 0, 0},                                        # S_PAIN_RUN2
    {CDoom::Spritenum::SPR_PAIN, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_PAIN_RUN4, 0, 0},                                        # S_PAIN_RUN3
    {CDoom::Spritenum::SPR_PAIN, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_PAIN_RUN5, 0, 0},                                        # S_PAIN_RUN4
    {CDoom::Spritenum::SPR_PAIN, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_PAIN_RUN6, 0, 0},                                        # S_PAIN_RUN5
    {CDoom::Spritenum::SPR_PAIN, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_PAIN_RUN1, 0, 0},                                        # S_PAIN_RUN6
    {CDoom::Spritenum::SPR_PAIN, 3, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_PAIN_ATK2, 0, 0},                                  # S_PAIN_ATK1
    {CDoom::Spritenum::SPR_PAIN, 4, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_PAIN_ATK3, 0, 0},                                  # S_PAIN_ATK2
    {CDoom::Spritenum::SPR_PAIN, 32773, 5, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_PAIN_ATK4, 0, 0},                              # S_PAIN_ATK3
    {CDoom::Spritenum::SPR_PAIN, 32773, 0, ->CDoom.a_pain_attack(Void*, Void*), CDoom::Statenum::S_PAIN_RUN1, 0, 0},                              # S_PAIN_ATK4
    {CDoom::Spritenum::SPR_PAIN, 6, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_PAIN2, 0, 0},         # S_PAIN_PAIN
    {CDoom::Spritenum::SPR_PAIN, 6, 6, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_PAIN_RUN1, 0, 0},                                         # S_PAIN_PAIN2
    {CDoom::Spritenum::SPR_PAIN, 32775, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_DIE2, 0, 0},      # S_PAIN_DIE1
    {CDoom::Spritenum::SPR_PAIN, 32776, 8, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_PAIN_DIE3, 0, 0},                                   # S_PAIN_DIE2
    {CDoom::Spritenum::SPR_PAIN, 32777, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_DIE4, 0, 0},      # S_PAIN_DIE3
    {CDoom::Spritenum::SPR_PAIN, 32778, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_DIE5, 0, 0},      # S_PAIN_DIE4
    {CDoom::Spritenum::SPR_PAIN, 32779, 8, ->CDoom.a_pain_die(Void*, Void*), CDoom::Statenum::S_PAIN_DIE6, 0, 0},                                 # S_PAIN_DIE5
    {CDoom::Spritenum::SPR_PAIN, 32780, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},           # S_PAIN_DIE6
    {CDoom::Spritenum::SPR_PAIN, 12, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_RAISE2, 0, 0},       # S_PAIN_RAISE1
    {CDoom::Spritenum::SPR_PAIN, 11, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_RAISE3, 0, 0},       # S_PAIN_RAISE2
    {CDoom::Spritenum::SPR_PAIN, 10, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_RAISE4, 0, 0},       # S_PAIN_RAISE3
    {CDoom::Spritenum::SPR_PAIN, 9, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_RAISE5, 0, 0},        # S_PAIN_RAISE4
    {CDoom::Spritenum::SPR_PAIN, 8, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_RAISE6, 0, 0},        # S_PAIN_RAISE5
    {CDoom::Spritenum::SPR_PAIN, 7, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PAIN_RUN1, 0, 0},          # S_PAIN_RAISE6
    {CDoom::Spritenum::SPR_SSWV, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SSWV_STND2, 0, 0},                                       # S_SSWV_STND
    {CDoom::Spritenum::SPR_SSWV, 1, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_SSWV_STND, 0, 0},                                        # S_SSWV_STND2
    {CDoom::Spritenum::SPR_SSWV, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN2, 0, 0},                                        # S_SSWV_RUN1
    {CDoom::Spritenum::SPR_SSWV, 0, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN3, 0, 0},                                        # S_SSWV_RUN2
    {CDoom::Spritenum::SPR_SSWV, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN4, 0, 0},                                        # S_SSWV_RUN3
    {CDoom::Spritenum::SPR_SSWV, 1, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN5, 0, 0},                                        # S_SSWV_RUN4
    {CDoom::Spritenum::SPR_SSWV, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN6, 0, 0},                                        # S_SSWV_RUN5
    {CDoom::Spritenum::SPR_SSWV, 2, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN7, 0, 0},                                        # S_SSWV_RUN6
    {CDoom::Spritenum::SPR_SSWV, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN8, 0, 0},                                        # S_SSWV_RUN7
    {CDoom::Spritenum::SPR_SSWV, 3, 3, ->CDoom.a_chase(Void*, Void*), CDoom::Statenum::S_SSWV_RUN1, 0, 0},                                        # S_SSWV_RUN8
    {CDoom::Spritenum::SPR_SSWV, 4, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SSWV_ATK2, 0, 0},                                 # S_SSWV_ATK1
    {CDoom::Spritenum::SPR_SSWV, 5, 10, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SSWV_ATK3, 0, 0},                                 # S_SSWV_ATK2
    {CDoom::Spritenum::SPR_SSWV, 32774, 4, ->CDoom.a_cpos_attack(Void*, Void*), CDoom::Statenum::S_SSWV_ATK4, 0, 0},                              # S_SSWV_ATK3
    {CDoom::Spritenum::SPR_SSWV, 5, 6, ->CDoom.a_face_target(Void*, Void*), CDoom::Statenum::S_SSWV_ATK5, 0, 0},                                  # S_SSWV_ATK4
    {CDoom::Spritenum::SPR_SSWV, 32774, 4, ->CDoom.a_cpos_attack(Void*, Void*), CDoom::Statenum::S_SSWV_ATK6, 0, 0},                              # S_SSWV_ATK5
    {CDoom::Spritenum::SPR_SSWV, 5, 1, ->CDoom.a_cpos_refire(Void*, Void*), CDoom::Statenum::S_SSWV_ATK2, 0, 0},                                  # S_SSWV_ATK6
    {CDoom::Spritenum::SPR_SSWV, 7, 3, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_PAIN2, 0, 0},         # S_SSWV_PAIN
    {CDoom::Spritenum::SPR_SSWV, 7, 3, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_SSWV_RUN1, 0, 0},                                         # S_SSWV_PAIN2
    {CDoom::Spritenum::SPR_SSWV, 8, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_DIE2, 0, 0},          # S_SSWV_DIE1
    {CDoom::Spritenum::SPR_SSWV, 9, 5, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_SSWV_DIE3, 0, 0},                                       # S_SSWV_DIE2
    {CDoom::Spritenum::SPR_SSWV, 10, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SSWV_DIE4, 0, 0},                                        # S_SSWV_DIE3
    {CDoom::Spritenum::SPR_SSWV, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_DIE5, 0, 0},         # S_SSWV_DIE4
    {CDoom::Spritenum::SPR_SSWV, 12, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_SSWV_DIE5
    {CDoom::Spritenum::SPR_SSWV, 13, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_XDIE2, 0, 0},        # S_SSWV_XDIE1
    {CDoom::Spritenum::SPR_SSWV, 14, 5, ->CDoom.a_xscream(Void*, Void*), CDoom::Statenum::S_SSWV_XDIE3, 0, 0},                                    # S_SSWV_XDIE2
    {CDoom::Spritenum::SPR_SSWV, 15, 5, ->CDoom.a_fall(Void*, Void*), CDoom::Statenum::S_SSWV_XDIE4, 0, 0},                                       # S_SSWV_XDIE3
    {CDoom::Spritenum::SPR_SSWV, 16, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_XDIE5, 0, 0},        # S_SSWV_XDIE4
    {CDoom::Spritenum::SPR_SSWV, 17, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_XDIE6, 0, 0},        # S_SSWV_XDIE5
    {CDoom::Spritenum::SPR_SSWV, 18, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_XDIE7, 0, 0},        # S_SSWV_XDIE6
    {CDoom::Spritenum::SPR_SSWV, 19, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_XDIE8, 0, 0},        # S_SSWV_XDIE7
    {CDoom::Spritenum::SPR_SSWV, 20, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_XDIE9, 0, 0},        # S_SSWV_XDIE8
    {CDoom::Spritenum::SPR_SSWV, 21, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_SSWV_XDIE9
    {CDoom::Spritenum::SPR_SSWV, 12, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_RAISE2, 0, 0},       # S_SSWV_RAISE1
    {CDoom::Spritenum::SPR_SSWV, 11, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_RAISE3, 0, 0},       # S_SSWV_RAISE2
    {CDoom::Spritenum::SPR_SSWV, 10, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_RAISE4, 0, 0},       # S_SSWV_RAISE3
    {CDoom::Spritenum::SPR_SSWV, 9, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_RAISE5, 0, 0},        # S_SSWV_RAISE4
    {CDoom::Spritenum::SPR_SSWV, 8, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SSWV_RUN1, 0, 0},          # S_SSWV_RAISE5
    {CDoom::Spritenum::SPR_KEEN, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_KEENSTND, 0, 0},          # S_KEENSTND
    {CDoom::Spritenum::SPR_KEEN, 0, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN2, 0, 0},          # S_COMMKEEN
    {CDoom::Spritenum::SPR_KEEN, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN3, 0, 0},          # S_COMMKEEN2
    {CDoom::Spritenum::SPR_KEEN, 2, 6, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_COMMKEEN4, 0, 0},                                       # S_COMMKEEN3
    {CDoom::Spritenum::SPR_KEEN, 3, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN5, 0, 0},          # S_COMMKEEN4
    {CDoom::Spritenum::SPR_KEEN, 4, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN6, 0, 0},          # S_COMMKEEN5
    {CDoom::Spritenum::SPR_KEEN, 5, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN7, 0, 0},          # S_COMMKEEN6
    {CDoom::Spritenum::SPR_KEEN, 6, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN8, 0, 0},          # S_COMMKEEN7
    {CDoom::Spritenum::SPR_KEEN, 7, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN9, 0, 0},          # S_COMMKEEN8
    {CDoom::Spritenum::SPR_KEEN, 8, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN10, 0, 0},         # S_COMMKEEN9
    {CDoom::Spritenum::SPR_KEEN, 9, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_COMMKEEN11, 0, 0},         # S_COMMKEEN10
    {CDoom::Spritenum::SPR_KEEN, 10, 6, ->CDoom.a_keen_die(Void*, Void*), CDoom::Statenum::S_COMMKEEN12, 0, 0},                                   # S_COMMKEEN11
    {CDoom::Spritenum::SPR_KEEN, 11, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_COMMKEEN12
    {CDoom::Spritenum::SPR_KEEN, 12, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_KEENPAIN2, 0, 0},         # S_KEENPAIN
    {CDoom::Spritenum::SPR_KEEN, 12, 8, ->CDoom.a_pain(Void*, Void*), CDoom::Statenum::S_KEENSTND, 0, 0},                                         # S_KEENPAIN2
    {CDoom::Spritenum::SPR_BBRN, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_BRAIN
    {CDoom::Spritenum::SPR_BBRN, 1, 36, ->CDoom.a_brain_pain(Void*, Void*), CDoom::Statenum::S_BRAIN, 0, 0},                                      # S_BRAIN_PAIN
    {CDoom::Spritenum::SPR_BBRN, 0, 100, ->CDoom.a_brain_scream(Void*, Void*), CDoom::Statenum::S_BRAIN_DIE2, 0, 0},                              # S_BRAIN_DIE1
    {CDoom::Spritenum::SPR_BBRN, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRAIN_DIE3, 0, 0},        # S_BRAIN_DIE2
    {CDoom::Spritenum::SPR_BBRN, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRAIN_DIE4, 0, 0},        # S_BRAIN_DIE3
    {CDoom::Spritenum::SPR_BBRN, 0, -1, ->CDoom.a_brain_die(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                        # S_BRAIN_DIE4
    {CDoom::Spritenum::SPR_SSWV, 0, 10, ->CDoom.a_look(Void*, Void*), CDoom::Statenum::S_BRAINEYE, 0, 0},                                         # S_BRAINEYE
    {CDoom::Spritenum::SPR_SSWV, 0, 181, ->CDoom.a_brain_awake(Void*, Void*), CDoom::Statenum::S_BRAINEYE1, 0, 0},                                # S_BRAINEYESEE
    {CDoom::Spritenum::SPR_SSWV, 0, 150, ->CDoom.a_brain_spit(Void*, Void*), CDoom::Statenum::S_BRAINEYE1, 0, 0},                                 # S_BRAINEYE1
    {CDoom::Spritenum::SPR_BOSF, 32768, 3, ->CDoom.a_spawn_sound(Void*, Void*), CDoom::Statenum::S_SPAWN2, 0, 0},                                 # S_SPAWN1
    {CDoom::Spritenum::SPR_BOSF, 32769, 3, ->CDoom.a_spawn_fly(Void*, Void*), CDoom::Statenum::S_SPAWN3, 0, 0},                                   # S_SPAWN2
    {CDoom::Spritenum::SPR_BOSF, 32770, 3, ->CDoom.a_spawn_fly(Void*, Void*), CDoom::Statenum::S_SPAWN4, 0, 0},                                   # S_SPAWN3
    {CDoom::Spritenum::SPR_BOSF, 32771, 3, ->CDoom.a_spawn_fly(Void*, Void*), CDoom::Statenum::S_SPAWN1, 0, 0},                                   # S_SPAWN4
    {CDoom::Spritenum::SPR_FIRE, 32768, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_SPAWNFIRE2, 0, 0},                                    # S_SPAWNFIRE1
    {CDoom::Spritenum::SPR_FIRE, 32769, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_SPAWNFIRE3, 0, 0},                                    # S_SPAWNFIRE2
    {CDoom::Spritenum::SPR_FIRE, 32770, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_SPAWNFIRE4, 0, 0},                                    # S_SPAWNFIRE3
    {CDoom::Spritenum::SPR_FIRE, 32771, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_SPAWNFIRE5, 0, 0},                                    # S_SPAWNFIRE4
    {CDoom::Spritenum::SPR_FIRE, 32772, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_SPAWNFIRE6, 0, 0},                                    # S_SPAWNFIRE5
    {CDoom::Spritenum::SPR_FIRE, 32773, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_SPAWNFIRE7, 0, 0},                                    # S_SPAWNFIRE6
    {CDoom::Spritenum::SPR_FIRE, 32774, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_SPAWNFIRE8, 0, 0},                                    # S_SPAWNFIRE7
    {CDoom::Spritenum::SPR_FIRE, 32775, 4, ->CDoom.a_fire(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                          # S_SPAWNFIRE8
    {CDoom::Spritenum::SPR_MISL, 32769, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRAINEXPLODE2, 0, 0}, # S_BRAINEXPLODE1
    {CDoom::Spritenum::SPR_MISL, 32770, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BRAINEXPLODE3, 0, 0}, # S_BRAINEXPLODE2
    {CDoom::Spritenum::SPR_MISL, 32771, 10, ->CDoom.a_brain_explode(Void*, Void*), CDoom::Statenum::S_NULL, 0, 0},                                # S_BRAINEXPLODE3
    {CDoom::Spritenum::SPR_ARM1, 0, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARM1A, 0, 0},              # S_ARM1
    {CDoom::Spritenum::SPR_ARM1, 32769, 7, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARM1, 0, 0},           # S_ARM1A
    {CDoom::Spritenum::SPR_ARM2, 0, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARM2A, 0, 0},              # S_ARM2
    {CDoom::Spritenum::SPR_ARM2, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_ARM2, 0, 0},           # S_ARM2A
    {CDoom::Spritenum::SPR_BAR1, 0, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BAR2, 0, 0},               # S_BAR1
    {CDoom::Spritenum::SPR_BAR1, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BAR1, 0, 0},               # S_BAR2
    {CDoom::Spritenum::SPR_BEXP, 32768, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BEXP2, 0, 0},          # S_BEXP
    {CDoom::Spritenum::SPR_BEXP, 32769, 5, ->CDoom.a_scream(Void*, Void*), CDoom::Statenum::S_BEXP3, 0, 0},                                       # S_BEXP2
    {CDoom::Spritenum::SPR_BEXP, 32770, 5, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BEXP4, 0, 0},          # S_BEXP3
    {CDoom::Spritenum::SPR_BEXP, 32771, 10, ->CDoom.a_explode(Void*, Void*), CDoom::Statenum::S_BEXP5, 0, 0},                                     # S_BEXP4
    {CDoom::Spritenum::SPR_BEXP, 32772, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},          # S_BEXP5
    {CDoom::Spritenum::SPR_FCAN, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BBAR2, 0, 0},          # S_BBAR1
    {CDoom::Spritenum::SPR_FCAN, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BBAR3, 0, 0},          # S_BBAR2
    {CDoom::Spritenum::SPR_FCAN, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BBAR1, 0, 0},          # S_BBAR3
    {CDoom::Spritenum::SPR_BON1, 0, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON1A, 0, 0},              # S_BON1
    {CDoom::Spritenum::SPR_BON1, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON1B, 0, 0},              # S_BON1A
    {CDoom::Spritenum::SPR_BON1, 2, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON1C, 0, 0},              # S_BON1B
    {CDoom::Spritenum::SPR_BON1, 3, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON1D, 0, 0},              # S_BON1C
    {CDoom::Spritenum::SPR_BON1, 2, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON1E, 0, 0},              # S_BON1D
    {CDoom::Spritenum::SPR_BON1, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON1, 0, 0},               # S_BON1E
    {CDoom::Spritenum::SPR_BON2, 0, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON2A, 0, 0},              # S_BON2
    {CDoom::Spritenum::SPR_BON2, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON2B, 0, 0},              # S_BON2A
    {CDoom::Spritenum::SPR_BON2, 2, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON2C, 0, 0},              # S_BON2B
    {CDoom::Spritenum::SPR_BON2, 3, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON2D, 0, 0},              # S_BON2C
    {CDoom::Spritenum::SPR_BON2, 2, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON2E, 0, 0},              # S_BON2D
    {CDoom::Spritenum::SPR_BON2, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BON2, 0, 0},               # S_BON2E
    {CDoom::Spritenum::SPR_BKEY, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BKEY2, 0, 0},             # S_BKEY
    {CDoom::Spritenum::SPR_BKEY, 32769, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BKEY, 0, 0},          # S_BKEY2
    {CDoom::Spritenum::SPR_RKEY, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RKEY2, 0, 0},             # S_RKEY
    {CDoom::Spritenum::SPR_RKEY, 32769, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RKEY, 0, 0},          # S_RKEY2
    {CDoom::Spritenum::SPR_YKEY, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_YKEY2, 0, 0},             # S_YKEY
    {CDoom::Spritenum::SPR_YKEY, 32769, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_YKEY, 0, 0},          # S_YKEY2
    {CDoom::Spritenum::SPR_BSKU, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSKULL2, 0, 0},           # S_BSKULL
    {CDoom::Spritenum::SPR_BSKU, 32769, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BSKULL, 0, 0},        # S_BSKULL2
    {CDoom::Spritenum::SPR_RSKU, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RSKULL2, 0, 0},           # S_RSKULL
    {CDoom::Spritenum::SPR_RSKU, 32769, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RSKULL, 0, 0},        # S_RSKULL2
    {CDoom::Spritenum::SPR_YSKU, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_YSKULL2, 0, 0},           # S_YSKULL
    {CDoom::Spritenum::SPR_YSKU, 32769, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_YSKULL, 0, 0},        # S_YSKULL2
    {CDoom::Spritenum::SPR_STIM, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_STIM
    {CDoom::Spritenum::SPR_MEDI, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_MEDI
    {CDoom::Spritenum::SPR_SOUL, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SOUL2, 0, 0},          # S_SOUL
    {CDoom::Spritenum::SPR_SOUL, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SOUL3, 0, 0},          # S_SOUL2
    {CDoom::Spritenum::SPR_SOUL, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SOUL4, 0, 0},          # S_SOUL3
    {CDoom::Spritenum::SPR_SOUL, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SOUL5, 0, 0},          # S_SOUL4
    {CDoom::Spritenum::SPR_SOUL, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SOUL6, 0, 0},          # S_SOUL5
    {CDoom::Spritenum::SPR_SOUL, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_SOUL, 0, 0},           # S_SOUL6
    {CDoom::Spritenum::SPR_PINV, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINV2, 0, 0},          # S_PINV
    {CDoom::Spritenum::SPR_PINV, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINV3, 0, 0},          # S_PINV2
    {CDoom::Spritenum::SPR_PINV, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINV4, 0, 0},          # S_PINV3
    {CDoom::Spritenum::SPR_PINV, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINV, 0, 0},           # S_PINV4
    {CDoom::Spritenum::SPR_PSTR, 32768, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},          # S_PSTR
    {CDoom::Spritenum::SPR_PINS, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINS2, 0, 0},          # S_PINS
    {CDoom::Spritenum::SPR_PINS, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINS3, 0, 0},          # S_PINS2
    {CDoom::Spritenum::SPR_PINS, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINS4, 0, 0},          # S_PINS3
    {CDoom::Spritenum::SPR_PINS, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PINS, 0, 0},           # S_PINS4
    {CDoom::Spritenum::SPR_MEGA, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_MEGA2, 0, 0},          # S_MEGA
    {CDoom::Spritenum::SPR_MEGA, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_MEGA3, 0, 0},          # S_MEGA2
    {CDoom::Spritenum::SPR_MEGA, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_MEGA4, 0, 0},          # S_MEGA3
    {CDoom::Spritenum::SPR_MEGA, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_MEGA, 0, 0},           # S_MEGA4
    {CDoom::Spritenum::SPR_SUIT, 32768, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},          # S_SUIT
    {CDoom::Spritenum::SPR_PMAP, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PMAP2, 0, 0},          # S_PMAP
    {CDoom::Spritenum::SPR_PMAP, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PMAP3, 0, 0},          # S_PMAP2
    {CDoom::Spritenum::SPR_PMAP, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PMAP4, 0, 0},          # S_PMAP3
    {CDoom::Spritenum::SPR_PMAP, 32771, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PMAP5, 0, 0},          # S_PMAP4
    {CDoom::Spritenum::SPR_PMAP, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PMAP6, 0, 0},          # S_PMAP5
    {CDoom::Spritenum::SPR_PMAP, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PMAP, 0, 0},           # S_PMAP6
    {CDoom::Spritenum::SPR_PVIS, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PVIS2, 0, 0},          # S_PVIS
    {CDoom::Spritenum::SPR_PVIS, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_PVIS, 0, 0},               # S_PVIS2
    {CDoom::Spritenum::SPR_CLIP, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_CLIP
    {CDoom::Spritenum::SPR_AMMO, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_AMMO
    {CDoom::Spritenum::SPR_ROCK, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_ROCK
    {CDoom::Spritenum::SPR_BROK, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_BROK
    {CDoom::Spritenum::SPR_CELL, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_CELL
    {CDoom::Spritenum::SPR_CELP, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_CELP
    {CDoom::Spritenum::SPR_SHEL, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SHEL
    {CDoom::Spritenum::SPR_SBOX, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SBOX
    {CDoom::Spritenum::SPR_BPAK, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_BPAK
    {CDoom::Spritenum::SPR_BFUG, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_BFUG
    {CDoom::Spritenum::SPR_MGUN, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_MGUN
    {CDoom::Spritenum::SPR_CSAW, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_CSAW
    {CDoom::Spritenum::SPR_LAUN, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_LAUN
    {CDoom::Spritenum::SPR_PLAS, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_PLAS
    {CDoom::Spritenum::SPR_SHOT, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SHOT
    {CDoom::Spritenum::SPR_SGN2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SHOT2
    {CDoom::Spritenum::SPR_COLU, 32768, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},          # S_COLU
    {CDoom::Spritenum::SPR_SMT2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_STALAG
    {CDoom::Spritenum::SPR_GOR1, 0, 10, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLOODYTWITCH2, 0, 0},     # S_BLOODYTWITCH
    {CDoom::Spritenum::SPR_GOR1, 1, 15, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLOODYTWITCH3, 0, 0},     # S_BLOODYTWITCH2
    {CDoom::Spritenum::SPR_GOR1, 2, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLOODYTWITCH4, 0, 0},      # S_BLOODYTWITCH3
    {CDoom::Spritenum::SPR_GOR1, 1, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLOODYTWITCH, 0, 0},       # S_BLOODYTWITCH4
    {CDoom::Spritenum::SPR_PLAY, 13, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_DEADTORSO
    {CDoom::Spritenum::SPR_PLAY, 18, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},             # S_DEADBOTTOM
    {CDoom::Spritenum::SPR_POL2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HEADSONSTICK
    {CDoom::Spritenum::SPR_POL5, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_GIBS
    {CDoom::Spritenum::SPR_POL4, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HEADONASTICK
    {CDoom::Spritenum::SPR_POL3, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEADCANDLES2, 0, 0},   # S_HEADCANDLES
    {CDoom::Spritenum::SPR_POL3, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEADCANDLES, 0, 0},    # S_HEADCANDLES2
    {CDoom::Spritenum::SPR_POL1, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_DEADSTICK
    {CDoom::Spritenum::SPR_POL6, 0, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_LIVESTICK2, 0, 0},         # S_LIVESTICK
    {CDoom::Spritenum::SPR_POL6, 1, 8, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_LIVESTICK, 0, 0},          # S_LIVESTICK2
    {CDoom::Spritenum::SPR_GOR2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_MEAT2
    {CDoom::Spritenum::SPR_GOR3, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_MEAT3
    {CDoom::Spritenum::SPR_GOR4, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_MEAT4
    {CDoom::Spritenum::SPR_GOR5, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_MEAT5
    {CDoom::Spritenum::SPR_SMIT, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_STALAGTITE
    {CDoom::Spritenum::SPR_COL1, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_TALLGRNCOL
    {CDoom::Spritenum::SPR_COL2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SHRTGRNCOL
    {CDoom::Spritenum::SPR_COL3, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_TALLREDCOL
    {CDoom::Spritenum::SPR_COL4, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SHRTREDCOL
    {CDoom::Spritenum::SPR_CAND, 32768, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},          # S_CANDLESTIK
    {CDoom::Spritenum::SPR_CBRA, 32768, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},          # S_CANDELABRA
    {CDoom::Spritenum::SPR_COL6, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SKULLCOL
    {CDoom::Spritenum::SPR_TRE1, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_TORCHTREE
    {CDoom::Spritenum::SPR_TRE2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_BIGTREE
    {CDoom::Spritenum::SPR_ELEC, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_TECHPILLAR
    {CDoom::Spritenum::SPR_CEYE, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_EVILEYE2, 0, 0},       # S_EVILEYE
    {CDoom::Spritenum::SPR_CEYE, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_EVILEYE3, 0, 0},       # S_EVILEYE2
    {CDoom::Spritenum::SPR_CEYE, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_EVILEYE4, 0, 0},       # S_EVILEYE3
    {CDoom::Spritenum::SPR_CEYE, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_EVILEYE, 0, 0},        # S_EVILEYE4
    {CDoom::Spritenum::SPR_FSKU, 32768, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FLOATSKULL2, 0, 0},    # S_FLOATSKULL
    {CDoom::Spritenum::SPR_FSKU, 32769, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FLOATSKULL3, 0, 0},    # S_FLOATSKULL2
    {CDoom::Spritenum::SPR_FSKU, 32770, 6, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_FLOATSKULL, 0, 0},     # S_FLOATSKULL3
    {CDoom::Spritenum::SPR_COL5, 0, 14, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEARTCOL2, 0, 0},         # S_HEARTCOL
    {CDoom::Spritenum::SPR_COL5, 1, 14, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_HEARTCOL, 0, 0},          # S_HEARTCOL2
    {CDoom::Spritenum::SPR_TBLU, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLUETORCH2, 0, 0},     # S_BLUETORCH
    {CDoom::Spritenum::SPR_TBLU, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLUETORCH3, 0, 0},     # S_BLUETORCH2
    {CDoom::Spritenum::SPR_TBLU, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLUETORCH4, 0, 0},     # S_BLUETORCH3
    {CDoom::Spritenum::SPR_TBLU, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BLUETORCH, 0, 0},      # S_BLUETORCH4
    {CDoom::Spritenum::SPR_TGRN, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GREENTORCH2, 0, 0},    # S_GREENTORCH
    {CDoom::Spritenum::SPR_TGRN, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GREENTORCH3, 0, 0},    # S_GREENTORCH2
    {CDoom::Spritenum::SPR_TGRN, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GREENTORCH4, 0, 0},    # S_GREENTORCH3
    {CDoom::Spritenum::SPR_TGRN, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GREENTORCH, 0, 0},     # S_GREENTORCH4
    {CDoom::Spritenum::SPR_TRED, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_REDTORCH2, 0, 0},      # S_REDTORCH
    {CDoom::Spritenum::SPR_TRED, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_REDTORCH3, 0, 0},      # S_REDTORCH2
    {CDoom::Spritenum::SPR_TRED, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_REDTORCH4, 0, 0},      # S_REDTORCH3
    {CDoom::Spritenum::SPR_TRED, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_REDTORCH, 0, 0},       # S_REDTORCH4
    {CDoom::Spritenum::SPR_SMBT, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BTORCHSHRT2, 0, 0},    # S_BTORCHSHRT
    {CDoom::Spritenum::SPR_SMBT, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BTORCHSHRT3, 0, 0},    # S_BTORCHSHRT2
    {CDoom::Spritenum::SPR_SMBT, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BTORCHSHRT4, 0, 0},    # S_BTORCHSHRT3
    {CDoom::Spritenum::SPR_SMBT, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_BTORCHSHRT, 0, 0},     # S_BTORCHSHRT4
    {CDoom::Spritenum::SPR_SMGT, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GTORCHSHRT2, 0, 0},    # S_GTORCHSHRT
    {CDoom::Spritenum::SPR_SMGT, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GTORCHSHRT3, 0, 0},    # S_GTORCHSHRT2
    {CDoom::Spritenum::SPR_SMGT, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GTORCHSHRT4, 0, 0},    # S_GTORCHSHRT3
    {CDoom::Spritenum::SPR_SMGT, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_GTORCHSHRT, 0, 0},     # S_GTORCHSHRT4
    {CDoom::Spritenum::SPR_SMRT, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RTORCHSHRT2, 0, 0},    # S_RTORCHSHRT
    {CDoom::Spritenum::SPR_SMRT, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RTORCHSHRT3, 0, 0},    # S_RTORCHSHRT2
    {CDoom::Spritenum::SPR_SMRT, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RTORCHSHRT4, 0, 0},    # S_RTORCHSHRT3
    {CDoom::Spritenum::SPR_SMRT, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_RTORCHSHRT, 0, 0},     # S_RTORCHSHRT4
    {CDoom::Spritenum::SPR_HDB1, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HANGNOGUTS
    {CDoom::Spritenum::SPR_HDB2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HANGBNOBRAIN
    {CDoom::Spritenum::SPR_HDB3, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HANGTLOOKDN
    {CDoom::Spritenum::SPR_HDB4, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HANGTSKULL
    {CDoom::Spritenum::SPR_HDB5, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HANGTLOOKUP
    {CDoom::Spritenum::SPR_HDB6, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_HANGTNOBRAIN
    {CDoom::Spritenum::SPR_POB1, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_COLONGIBS
    {CDoom::Spritenum::SPR_POB2, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_SMALLPOOL
    {CDoom::Spritenum::SPR_BRS1, 0, -1, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_NULL, 0, 0},              # S_BRAINSTEM
    {CDoom::Spritenum::SPR_TLMP, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECHLAMP2, 0, 0},      # S_TECHLAMP
    {CDoom::Spritenum::SPR_TLMP, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECHLAMP3, 0, 0},      # S_TECHLAMP2
    {CDoom::Spritenum::SPR_TLMP, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECHLAMP4, 0, 0},      # S_TECHLAMP3
    {CDoom::Spritenum::SPR_TLMP, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECHLAMP, 0, 0},       # S_TECHLAMP4
    {CDoom::Spritenum::SPR_TLP2, 32768, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECH2LAMP2, 0, 0},     # S_TECH2LAMP
    {CDoom::Spritenum::SPR_TLP2, 32769, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECH2LAMP3, 0, 0},     # S_TECH2LAMP2
    {CDoom::Spritenum::SPR_TLP2, 32770, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECH2LAMP4, 0, 0},     # S_TECH2LAMP3
    {CDoom::Spritenum::SPR_TLP2, 32771, 4, CDoom::ActionfV.new(Pointer(Void).null, Pointer(Void).null), CDoom::Statenum::S_TECH2LAMP, 0, 0},      # S_TECH2LAMP4
  ]
  @@states : Array(CDoom::State) = Array.new(CDoom::Statenum::NUMSTATES.value, CDoom::State.new)
  @@statedata.each_with_index do |elm, i|
    (@@states.to_unsafe + i).value.sprite = elm[0]
    (@@states.to_unsafe + i).value.frame = elm[1]
    (@@states.to_unsafe + i).value.tics = elm[2]
    LibDoom.set_action(@@states.to_unsafe + i, elm[3])
    (@@states.to_unsafe + i).value.nextstate = elm[4]
    (@@states.to_unsafe + i).value.misc1 = elm[5]
    (@@states.to_unsafe + i).value.misc2 = elm[6]
  end

  CDoom.states = @@states.to_unsafe

  c_array_strings(CDoom.gammamsg,
    CDoom::GAMMALVL0,
    CDoom::GAMMALVL1,
    CDoom::GAMMALVL2,
    CDoom::GAMMALVL3,
    CDoom::GAMMALVL4)

  c_array_strings(CDoom.skull_name,
    "M_SKULL1",
    "M_SKULL2")

  c_array(CDoom.menu_custom_texts,
    CDoom::MenuCustomText.new(name: "TXT_MMOV".to_unsafe,
      segs: StaticArray[
        CDoom::MenuCustomTextSeg.new(lump: "M_MSENS", x: 0, w: 74, offx: 0, offy: 0),                   # Mouse
        CDoom::MenuCustomTextSeg.new(lump: "M_MSENS", x: 0, w: 31, offx: 83, offy: 0),                  # Mo
        CDoom::MenuCustomTextSeg.new(lump: "M_MSENS", x: 160, w: 14, offx: 83 + 31, offy: 0),           # v
        CDoom::MenuCustomTextSeg.new(lump: "M_MSENS", x: 60, w: 14, offx: 83 + 31 + 14, offy: 0),       # e
        CDoom::MenuCustomTextSeg.new(lump: "M_DETAIL", x: 169, w: 5, offx: 83 + 31 + 14 + 14, offy: 0), # :
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
      ]),
    CDoom::MenuCustomText.new(name: "TXT_MOPT".to_unsafe,
      segs: StaticArray[
        CDoom::MenuCustomTextSeg.new(lump: "M_MSENS", x: 0, w: 74, offx: 0, offy: 0),       # Mouse
        CDoom::MenuCustomTextSeg.new(lump: "M_OPTION", x: 0, w: 92, offx: 74 + 9, offy: 0), # Options
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
      ]),
    CDoom::MenuCustomText.new(name: "TXT_CROS".to_unsafe,
      segs: StaticArray[
        CDoom::MenuCustomTextSeg.new(lump: "M_SKILL", x: 0, w: 16, offx: 0, offy: 0),                                  # C
        CDoom::MenuCustomTextSeg.new(lump: "M_DETAIL", x: 14, w: 15, offx: 16, offy: 0),                               # r
        CDoom::MenuCustomTextSeg.new(lump: "M_SKILL", x: 46, w: 30, offx: 16 + 15, offy: 0),                           # os
        CDoom::MenuCustomTextSeg.new(lump: "M_SKILL", x: 62, w: 14, offx: 16 + 15 + 30, offy: 0),                      # s
        CDoom::MenuCustomTextSeg.new(lump: "M_SKILL", x: 16, w: 15, offx: 16 + 15 + 30 + 14, offy: 0),                 # h
        CDoom::MenuCustomTextSeg.new(lump: "M_DETAIL", x: 140, w: 19, offx: 16 + 15 + 30 + 14 + 15, offy: 0),          # ai
        CDoom::MenuCustomTextSeg.new(lump: "M_DETAIL", x: 14, w: 15, offx: 16 + 15 + 30 + 14 + 15 + 19, offy: 0),      # r
        CDoom::MenuCustomTextSeg.new(lump: "M_DETAIL", x: 169, w: 5, offx: 16 + 15 + 30 + 14 + 15 + 19 + 15, offy: 0), # :
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
      ]),
    CDoom::MenuCustomText.new(name: "TXT_ARUN".to_unsafe,
      segs: StaticArray[
        CDoom::MenuCustomTextSeg.new(lump: "M_SGTTL", x: 90, w: 17, offx: 0, offy: 0),                                          # A
        CDoom::MenuCustomTextSeg.new(lump: "M_GDLOW", x: 0, w: 10, offx: 17, offy: 3),                                          # l
        CDoom::MenuCustomTextSeg.new(lump: "M_GDLOW", x: 26, w: 16, offx: 17 + 10, offy: 3),                                    #
        CDoom::MenuCustomTextSeg.new(lump: "M_DISP", x: 57, w: 30, offx: 17 + 10 + 16, offy: 0),                                # ay
        CDoom::MenuCustomTextSeg.new(lump: "M_RDTHIS", x: 99, w: 14, offx: 17 + 10 + 16 + 30, offy: 0),                         # s
        CDoom::MenuCustomTextSeg.new(lump: "M_RDTHIS", x: 0, w: 16, offx: 17 + 10 + 16 + 30 + 14 + 7, offy: 0),                 # R
        CDoom::MenuCustomTextSeg.new(lump: "M_SFXVOL", x: 90, w: 15, offx: 17 + 10 + 16 + 30 + 14 + 7 + 16, offy: 0),           # u
        CDoom::MenuCustomTextSeg.new(lump: "M_OPTION", x: 62, w: 15, offx: 17 + 10 + 16 + 30 + 14 + 7 + 16 + 15, offy: 0),      # n
        CDoom::MenuCustomTextSeg.new(lump: "M_DETAIL", x: 169, w: 5, offx: 17 + 10 + 16 + 30 + 14 + 7 + 16 + 15 + 15, offy: 0), # :
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
        CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new, CDoom::MenuCustomTextSeg.new,
      ])
  )

  CDoom.custom_texts_count = sizeof(typeof(CDoom.menu_custom_texts)) // sizeof(CDoom::MenuCustomText)

  c_array_strings(CDoom.detail_names,
    "M_GDHIGH", "M_GDLOW")
  c_array_strings(CDoom.msg_names,
    "M_MSGOFF", "M_MSGON")

  c_array(CDoom.quitsounds,
    CDoom::Sfxenum::SFX_pldeth.value,
    CDoom::Sfxenum::SFX_dmpain.value,
    CDoom::Sfxenum::SFX_popain.value,
    CDoom::Sfxenum::SFX_slop.value,
    CDoom::Sfxenum::SFX_telept.value,
    CDoom::Sfxenum::SFX_posit1.value,
    CDoom::Sfxenum::SFX_posit3.value,
    CDoom::Sfxenum::SFX_sgtatk.value)

  c_array(CDoom.quitsounds2,
    CDoom::Sfxenum::SFX_vilact.value,
    CDoom::Sfxenum::SFX_getpow.value,
    CDoom::Sfxenum::SFX_boscub.value,
    CDoom::Sfxenum::SFX_slop.value,
    CDoom::Sfxenum::SFX_skeswg.value,
    CDoom::Sfxenum::SFX_kntdth.value,
    CDoom::Sfxenum::SFX_bspact.value,
    CDoom::Sfxenum::SFX_sgtatk.value)

  c_array(CDoom.mainmenu,
    CDoom::Menuitem.new(status: 1, name: "M_NGAME".to_unsafe, routine: ->CDoom.m_new_game(Int32), alpha_key: 'n'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_OPTION".to_unsafe, routine: ->CDoom.m_options(Int32), alpha_key: 'o'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_LOADG".to_unsafe, routine: ->CDoom.m_load_game(Int32), alpha_key: 'l'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_SAVEG".to_unsafe, routine: ->CDoom.m_save_game(Int32), alpha_key: 's'.ord),
    # Another hickup with Special edition.
    CDoom::Menuitem.new(status: 1, name: "M_RDTHIS".to_unsafe, routine: ->CDoom.m_readthis(Int32), alpha_key: 'r'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_QUITG".to_unsafe, routine: ->CDoom.m_quitdoom(Int32), alpha_key: 'q'.ord),
  )

  pointerof(CDoom.maindef).value = CDoom::Menu.new(
    numitems: CDoom::Mainenum::MainEnd.value,
    prev_menu: Pointer(CDoom::Menu).null,
    menuitems: CDoom.mainmenu.to_unsafe,
    routine: ->CDoom.m_draw_mainmenu,
    x: 97, y: 64,
    last_on: 0
  )

  c_array(CDoom.episodemenu,
    CDoom::Menuitem.new(status: 1, name: "M_EPI1".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 'k'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_EPI2".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 't'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_EPI3".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 'i'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_EPI4".to_unsafe, routine: ->CDoom.m_episode(Int32), alpha_key: 't'.ord),
  )

  pointerof(CDoom.epidef).value = CDoom::Menu.new(
    numitems: CDoom::Episodesenum::EpEnd.value,
    prev_menu: pointerof(CDoom.maindef),
    menuitems: CDoom.episodemenu.to_unsafe,
    routine: ->CDoom.m_draw_episode,
    x: 48, y: 63,
    last_on: CDoom::Episodesenum::Ep1.value
  )

  c_array(CDoom.newgame_menu,
    CDoom::Menuitem.new(status: 1, name: "M_JKILL".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'i'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_ROUGH".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'h'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_HURT".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'h'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_ULTRA".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'u'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_NMARE".to_unsafe, routine: ->CDoom.m_choose_skill(Int32), alpha_key: 'n'.ord),
  )

  pointerof(CDoom.newdef).value = CDoom::Menu.new(
    numitems: CDoom::NewgameEnum::NewgEnd.value,
    prev_menu: pointerof(CDoom.epidef),
    menuitems: CDoom.newgame_menu.to_unsafe,
    routine: ->CDoom.m_draw_newgame,
    x: 48, y: 63,
    last_on: CDoom::NewgameEnum::Hurtme.value
  )

  c_array(CDoom.options_menu,
    CDoom::Menuitem.new(status: 1, name: "M_ENDGAM".to_unsafe, routine: ->CDoom.m_endgame(Int32), alpha_key: 'e'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_MESSG".to_unsafe, routine: ->CDoom.m_change_messages(Int32), alpha_key: 'm'.ord),
    CDoom::Menuitem.new(status: 1, name: "TXT_CROS".to_unsafe, routine: ->CDoom.m_change_crosshair(Int32), alpha_key: 'c'.ord),
    CDoom::Menuitem.new(status: 1, name: "TXT_ARUN".to_unsafe, routine: ->CDoom.m_change_alwaysrun(Int32), alpha_key: 'r'.ord),
    # CDoom::Menuitem.new(status: 1, name: "M_DETAIL".to_unsafe, routine: ->CDoom.m_change_detail(Int32), alpha_key: 'g'.ord),
    CDoom::Menuitem.new(status: 2, name: "M_SCRNSZ".to_unsafe, routine: ->CDoom.m_size_display(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe),
    CDoom::Menuitem.new(status: 1, name: "TXT_MOPT".to_unsafe, routine: ->CDoom.m_mouse_options(Int32), alpha_key: 'f'.ord),
    CDoom::Menuitem.new(status: 1, name: "M_SVOL".to_unsafe, routine: ->CDoom.m_sound(Int32), alpha_key: 's'.ord),
  )

  pointerof(CDoom.optionsdef).value = CDoom::Menu.new(
    numitems: CDoom::OptionsEnum::OptEnd.value,
    prev_menu: pointerof(CDoom.maindef),
    menuitems: CDoom.options_menu.to_unsafe,
    routine: ->CDoom.m_draw_options,
    x: 60, y: 37,
    last_on: 0
  )

  c_array(CDoom.mouse_options_menu,
    CDoom::Menuitem.new(status: 1, name: "TXT_MMOV".to_unsafe, routine: ->CDoom.m_mouse_move(Int32), alpha_key: 'f'.ord),
    CDoom::Menuitem.new(status: 2, name: "M_MSENS".to_unsafe, routine: ->CDoom.m_change_sensitivity(Int32), alpha_key: 'm'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe)
  )

  pointerof(CDoom.mouseoptionsdef).value = CDoom::Menu.new(
    numitems: CDoom::MouseoptionsEnum::MouseOptEnd.value,
    prev_menu: pointerof(CDoom.optionsdef),
    menuitems: CDoom.mouse_options_menu.to_unsafe,
    routine: ->CDoom.m_draw_mouse_options,
    x: 60, y: 70,
    last_on: 0
  )

  c_array(CDoom.readmenu1,
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_readthis2(Int32))
  )

  pointerof(CDoom.readdef1).value = CDoom::Menu.new(
    numitems: CDoom::Readenum::Read1End.value,
    prev_menu: pointerof(CDoom.maindef),
    menuitems: CDoom.readmenu1.to_unsafe,
    routine: ->CDoom.m_draw_readthis1,
    x: 280, y: 185,
    last_on: 0
  )

  c_array(CDoom.readmenu2,
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_finish_readthis(Int32))
  )

  pointerof(CDoom.readdef2).value = CDoom::Menu.new(
    numitems: CDoom::Read2enum::Read2End.value,
    prev_menu: pointerof(CDoom.readdef1),
    menuitems: CDoom.readmenu2.to_unsafe,
    routine: ->CDoom.m_draw_readthis2,
    x: 330, y: 175,
    last_on: 0
  )

  c_array(CDoom.soundmenu,
    CDoom::Menuitem.new(status: 2, name: "M_SFXVOL".to_unsafe, routine: ->CDoom.m_sfxvol(Int32), alpha_key: 's'.ord),
    CDoom::Menuitem.new(status: -1, name: "".to_unsafe),
    CDoom::Menuitem.new(status: 2, name: "M_MUSVOL".to_unsafe, routine: ->CDoom.m_musicvol(Int32), alpha_key: 'm'.ord),
    CDoom::Menuitem.new(status: -1, name: "".to_unsafe),
  )

  pointerof(CDoom.sounddef).value = CDoom::Menu.new(
    numitems: CDoom::Soundenum::SoundEnd.value,
    prev_menu: pointerof(CDoom.optionsdef),
    menuitems: CDoom.soundmenu.to_unsafe,
    routine: ->CDoom.m_draw_sound,
    x: 80, y: 64,
    last_on: 0
  )

  c_array(CDoom.loadmenu,
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '1'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '2'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '3'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '4'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '5'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_load_select(Int32), alpha_key: '6'.ord),
  )

  pointerof(CDoom.loaddef).value = CDoom::Menu.new(
    numitems: CDoom::Loadenum::LoadEnd.value,
    prev_menu: pointerof(CDoom.maindef),
    menuitems: CDoom.loadmenu.to_unsafe,
    routine: ->CDoom.m_draw_load,
    x: 80, y: 54,
    last_on: 0
  )

  c_array(CDoom.savemenu,
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '1'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '2'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '3'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '4'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '5'.ord),
    CDoom::Menuitem.new(status: 1, name: "".to_unsafe, routine: ->CDoom.m_save_select(Int32), alpha_key: '6'.ord),
  )

  pointerof(CDoom.savedef).value = CDoom::Menu.new(
    numitems: CDoom::Loadenum::LoadEnd.value,
    prev_menu: pointerof(CDoom.maindef),
    menuitems: CDoom.savemenu.to_unsafe,
    routine: ->CDoom.m_draw_save,
    x: 80, y: 54,
    last_on: 0
  )

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
    exit(code)
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
    return c - 'a'.ord + 'A'.ord if c >= 'a'.ord && c <= 'z'.ord
    return c
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

    update_audio

    delta_time.times do |i|
      if CDoom.is_wiping_screen != 0
        CDoom.d_update_wipe
      else
        CDoom.d_doom_loop
      end
    end

    CDoom.last_update_time = now
  end

  def self.doom_draw
    @@screen_texture.try do |st|
      fb = CDoom.doom_get_framebuffer(4)
      break if fb.null?
      Raylib.update_texture(st, fb)

      scalew = Raylib.get_screen_width.to_f / SRES_X.to_f
      scaleh = Raylib.get_screen_height.to_f / SRES_Y.to_f
      scale = [scalew, scaleh].min

      Raylib.begin_drawing
      Raylib.clear_background(Raylib::BLACK)
      Raylib.draw_texture_pro(st,
        Raylib::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: st.width.to_f, height: st.height.to_f),
        Raylib::Rectangle.new(x: (Raylib.get_screen_width - (SRES_X.to_f * scale)) * 0.5_f32, y: (Raylib.get_screen_height - (SRES_Y.to_f * scale)) * 0.5_f32,
          width: SRES_X.to_f * scale, height: SRES_Y.to_f * scale),
        Raylib::Vector2.new, 0, Raylib::WHITE)
      Raylib.end_drawing
    end
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

  def self.doom_tick_midi : UInt64
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
    namebuf = uninitialized StaticArray(UInt8, 9)

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

  @@fl : CDoom::Fline* = Pointer(CDoom::Fline).malloc

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

    if (start - CDoom.bmaporgx).remainder(CDoom::MAPBLOCKUNITS << CDoom::FRACBITS) != 0
      start += (CDoom::MAPBLOCKUNITS << CDoom::FRACBITS) -
               (start - CDoom.bmaporgx).remainder(CDoom::MAPBLOCKUNITS << CDoom::FRACBITS)
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

  def self.am_draw_line_character(lineguy : CDoom::Mline*,
                                  lineguylines : Int32,
                                  scale : CDoom::Fixed,
                                  angle : CDoom::Angle,
                                  color : Int32,
                                  x : CDoom::Fixed,
                                  y : CDoom::Fixed)
    l = CDoom::Mline.new
    lineguylines.times do |i|
      ax = lineguy[i].a.x
      ay = lineguy[i].a.y

      if scale != 0
        ax = CDoom.fixed_mul(scale, ax)
        ay = CDoom.fixed_mul(scale, ay)
      end

      l.a = CDoom::Mpoint.new(x: ax, y: ay)

      CDoom.am_rotate(
        (pointerof(l).as(UInt8*) + offsetof(CDoom::Mline, @a) + offsetof(CDoom::Mpoint, @x)).as(CDoom::Fixed*),
        (pointerof(l).as(UInt8*) + offsetof(CDoom::Mline, @a) + offsetof(CDoom::Mpoint, @y)).as(CDoom::Fixed*),
        angle) if angle != 0

      l.a = CDoom::Mpoint.new(x: l.a.x + x, y: l.a.y + y)

      bx = lineguy[i].b.x
      by = lineguy[i].b.y

      if scale != 0
        bx = CDoom.fixed_mul(scale, bx)
        by = CDoom.fixed_mul(scale, by)
      end

      l.b = CDoom::Mpoint.new(x: bx, y: by)

      CDoom.am_rotate(
        (pointerof(l).as(UInt8*) + offsetof(CDoom::Mline, @b) + offsetof(CDoom::Mpoint, @x)).as(CDoom::Fixed*),
        (pointerof(l).as(UInt8*) + offsetof(CDoom::Mline, @b) + offsetof(CDoom::Mpoint, @y)).as(CDoom::Fixed*),
        angle) if angle != 0

      l.b = CDoom::Mpoint.new(x: l.b.x + x, y: l.b.y + y)

      CDoom.am_draw_mline(pointerof(l), color)
    end
  end

  def self.am_draw_players
    p : CDoom::Player* = Pointer(CDoom::Player).null
    their_colors = [CDoom::GREENS, CDoom::GRAYS, CDoom::BROWNS, CDoom::REDS]
    their_color = -1
    color = 0

    if CDoom.netgame == 0
      if CDoom.cheating != 0
        CDoom.am_draw_line_character(
          CDoom.cheat_player_arrow, CDoom::NUMCHEATPLYRLINES, 0,
          CDoom.plr.value.mo.value.angle, CDoom::WHITE,
          CDoom.plr.value.mo.value.x, CDoom.plr.value.mo.value.y
        )
      else
        CDoom.am_draw_line_character(
          CDoom.player_arrow, CDoom::NUMPLYRLINES, 0, CDoom.plr.value.mo.value.angle,
          CDoom::WHITE, CDoom.plr.value.mo.value.x, CDoom.plr.value.mo.value.y
        )
      end
      return
    end

    CDoom::MAXPLAYERS.times do |i|
      their_color += 1
      p = CDoom.players.to_unsafe + i

      next if (CDoom.deathmatch != 0 && CDoom.singledemo == 0) && p != CDoom.plr
      next if CDoom.playeringame[i] == 0

      if p.value.powers[CDoom::Powertype::Invisibility.value] != 0
        color = 246 # *close* to black
      else
        color = their_colors[their_color]
      end

      CDoom.am_draw_line_character(
        CDoom.player_arrow, CDoom::NUMPLYRLINES, 0, p.value.mo.value.angle,
        color, p.value.mo.value.x, p.value.mo.value.y
      )
    end
  end

  def self.am_draw_things(colors : Int32, colorrange : Int32)
    CDoom.numsectors.times do |i|
      t = CDoom.sectors[i].thinglist
      until t.null?
        CDoom.am_draw_line_character(
          CDoom.thintriangle_guy, CDoom::NUMTHINTRIANGLEGUYLINES,
          16 << CDoom::FRACBITS, t.value.angle, colors + CDoom.lightlev,
          t.value.x, t.value.y
        )
        t = t.value.snext
      end
    end
  end

  def self.am_draw_marks
    CDoom::AM_NUMMARKPOINTS.times do |i|
      if CDoom.markpoints[i].x != -1
        # w = CDoom.marknums[i].value.width.to_i16!
        # h = CDoom.marknums[i].value.height.to_i16!
        w = 5 # because somethings wrong with the wad, i guess
        h = 6 # because somethings wrong with the wad, i guess
        fx = cxmtof(CDoom.markpoints[i].x)
        fy = cymtof(CDoom.markpoints[i].y)
        if fx >= CDoom.f_x && fx <= CDoom.f_w - w && fy >= CDoom.f_y && fy <= CDoom.f_h - h
          CDoom.v_draw_patch(fx, fy, CDoom::FB, CDoom.marknums[i])
        end
      end
    end
  end

  def self.am_draw_crosshair(color : Int32)
    CDoom.fb[(CDoom.f_w * (CDoom.f_h + 1)) // 2] = color.to_u8! # single point for now
  end

  def self.am_drawer
    return if CDoom.automapactive == 0

    CDoom.am_clear_fb(CDoom::BACKGROUND)
    CDoom.am_draw_grid(CDoom::GRIDCOLORS) if CDoom.grid != 0
    CDoom.am_draw_walls
    CDoom.am_draw_players
    CDoom.am_draw_things(CDoom::THINGCOLORS, CDoom::THINGRANGE) if CDoom.cheating == 2
    CDoom.am_draw_crosshair(CDoom::XHAIRCOLORS)

    CDoom.am_draw_marks

    CDoom.v_mark_rect(CDoom.f_x, CDoom.f_y, CDoom.f_w, CDoom.f_h)
  end

  #
  # d_post_event
  # Called by the I/O functions when input is detected
  #
  def self.d_post_event(ev : CDoom::Event*)
    CDoom.events[CDoom.eventhead] = ev.value
    CDoom.eventhead += 1
    CDoom.eventhead = (CDoom.eventhead) & (CDoom::MAXEVENTS - 1)
  end

  #
  # d_process_events
  # Send all the events of the given timestamp down the responder chain
  #
  def self.d_process_events
    # IF STORE DEMO, DO NOT ACCEPT INPUT
    return if CDoom.gamemode == CDoom::GameMode::Commercial &&
              CDoom.w_check_num_for_name("map01") < 0

    while CDoom.eventtail != CDoom.eventhead
      ev = CDoom.events.to_unsafe + CDoom.eventtail
      CDoom.g_responder(ev) if CDoom.m_responder(ev) == 0
      # else menu ate the event
      CDoom.eventtail += 1
      CDoom.eventtail = (CDoom.eventtail) & (CDoom::MAXEVENTS - 1)
    end
  end

  @@viewactivestate = false
  @@menuactivestate = false
  @@inhelpscreenstate = false
  @@fullscreen = false
  @@oldgamestate = -1
  @@borderdrawcount = 0

  #
  # d_display
  #  draw current display, possibly wiping it from the previous
  #
  def self.d_display
    return if CDoom.nodrawers != 0 # for comparative timing / profiling

    redrawsbar = false

    # change the view size if needed
    if CDoom.setsizeneeded != 0
      CDoom.r_execute_set_view_size
      @@oldgamestate = -1 # force background redraw
      @@borderdrawcount = 3
    end

    wipe = false
    # save the current screen if about to wipe
    if CDoom.gamestate != CDoom.wipegamestate
      wipe = true
      CDoom.wipe_start_screen(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)
    end

    CDoom.hu_erase if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.gametic != 0

    # do buffered drawing
    case CDoom.gamestate
    when CDoom::Gamestate::Level
      if CDoom.gametic != 0
        CDoom.am_drawer if CDoom.automapactive != 0
        redrawsbar = true if wipe || (CDoom.viewheight != 200 && @@fullscreen)
        redrawsbar = true if @@inhelpscreenstate && CDoom.inhelpscreens == 0 # just put away the help screen
        CDoom.st_drawer((CDoom.viewheight == 200).to_unsafe, redrawsbar.to_unsafe)
        @@fullscreen = CDoom.viewheight == 200
      end
    when CDoom::Gamestate::Intermission
      CDoom.wi_drawer
    when CDoom::Gamestate::Finale
      CDoom.f_drawer
    when CDoom::Gamestate::Demoscreen
      CDoom.d_page_drawer
    end

    # draw buffered stuff to screen
    CDoom.i_update_no_blit

    # draw the view directly
    if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.automapactive == 0 && CDoom.gametic != 0
      CDoom.r_render_player_view(CDoom.players.to_unsafe + CDoom.displayplayer)
    end

    CDoom.hu_drawer if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.gametic != 0

    # clean up border stuff
    if CDoom.gamestate.value != @@oldgamestate && CDoom.gamestate != CDoom::Gamestate::Level
      CDoom.i_set_palette(CDoom.w_cache_lump_name("PLAYPAL", CDoom::PU_CACHE).as(UInt8*))
    end

    # see if the border needs to be initially drawn
    if CDoom.gamestate == CDoom::Gamestate::Level && @@oldgamestate != CDoom::Gamestate::Level.value
      @@viewactivestate = false # view was not active
      CDoom.r_fill_back_screen  # draw the pattern into the back screen
    end

    # see if the border needs to be updated to the screen
    if CDoom.gamestate == CDoom::Gamestate::Level && CDoom.automapactive == 0 && CDoom.scaledviewwidth != 320
      @@borderdrawcount = 3 if CDoom.menuactive != 0 || @@menuactivestate || !@@viewactivestate
      if @@borderdrawcount != 0
        CDoom.r_draw_view_border # erase old menu stuff
        @@borderdrawcount -= 1
      end
    end

    @@menuactivestate = CDoom.menuactive != 0
    @@viewactivestate = CDoom.viewactive != 0
    @@inhelpscreenstate = CDoom.inhelpscreens != 0
    @@oldgamestate = CDoom.gamestate.value
    CDoom.wipegamestate = CDoom.gamestate

    # draw pause pic
    if CDoom.paused != 0
      y = 0
      if CDoom.automapactive != 0
        y = 4
      else
        y = CDoom.viewwindowy + 4
      end
      CDoom.v_draw_patch_direct(CDoom.viewwindowx + (CDoom.scaledviewwidth - 68) // 2,
        y, 0, CDoom.w_cache_lump_name("M_PAUSE", CDoom::PU_CACHE).as(CDoom::Patch*))
    end

    # menus go directly to the screen
    CDoom.m_drawer   # menu is drawn even on top of everything
    CDoom.net_update # send out any new accumulation

    # normal update
    CDoom.is_wiping_screen = wipe.to_unsafe
    if !wipe
      CDoom.i_finish_update # page flip or blit buffer
      return
    end

    # wipe update
    CDoom.wipe_end_screen(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)
  end

  def self.d_update_wipe
    if CDoom.wipe_screen_wipe(CDoom::WIPE_MELT, 0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT, 1) != 0
      CDoom.is_wiping_screen = 0
    end
  end

  def self.d_doom_loop
    # while true
    # frame syncronous IO operations
    CDoom.i_start_frame

    # process one or more tics
    if CDoom.singletics != 0
      CDoom.i_start_tic
      CDoom.d_process_events
      CDoom.g_build_ticcmd((CDoom.netcmds.to_unsafe + CDoom.consoleplayer).value.to_unsafe + CDoom.maketic % CDoom::BACKUPTICS)
      CDoom.d_do_advance_demo if CDoom.advancedemo != 0
      CDoom.m_ticker
      CDoom.g_ticker
      CDoom.gametic += 1
      CDoom.maketic += 1
    else
      CDoom.try_run_tics # will run at least one tic
    end

    CDoom.s_update_sounds(CDoom.players[CDoom.consoleplayer].mo) # move positional sounds

    # Update display, next frame, with current state.
    CDoom.d_display

    # end
  end

  #
  # d_page_ticker
  # Handles timing for warped projection
  #
  def self.d_page_ticker
    CDoom.pagetic -= 1
    CDoom.d_advance_demo if CDoom.pagetic < 0
  end

  def self.d_page_drawer
    CDoom.v_draw_patch(0, 0, 0, CDoom.w_cache_lump_name(CDoom.pagename, CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # d_advance_demo
  # Called after each demo or intro demosequence finishes
  #
  def self.d_advance_demo
    CDoom.advancedemo = 1
  end

  #
  # This cycles through the demo sequences.
  # Todo: FIXME - version dependend demo numbers?
  #
  def self.d_do_advance_demo
    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.playerstate = CDoom::Playerstate::PST_LIVE # not reborn
    CDoom.advancedemo = 0
    CDoom.usergame = 0 # no save / end game here
    CDoom.paused = 0
    CDoom.gameaction = CDoom::Gameaction::Nothing

    if CDoom.gamemode == CDoom::GameMode::Retail
      CDoom.demosequence = (CDoom.demosequence + 1) % 7
    else
      CDoom.demosequence = (CDoom.demosequence + 1) % 6
    end

    case CDoom.demosequence
    when 0
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.pagetic = 35 * 11
      else
        CDoom.pagetic = 170
      end
      CDoom.gamestate = CDoom::Gamestate::Demoscreen
      CDoom.pagename = "TITLEPIC"
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.s_start_music(CDoom::Musicenum::MUS_dm2ttl)
      else
        CDoom.s_start_music(CDoom::Musicenum::MUS_intro)
      end
    when 1
      CDoom.g_defered_play_demo("demo1")
    when 2
      CDoom.pagetic = 200
      CDoom.gamestate = CDoom::Gamestate::Demoscreen
      CDoom.pagename = "CREDIT"
    when 3
      CDoom.g_defered_play_demo("demo2")
    when 4
      CDoom.gamestate = CDoom::Gamestate::Demoscreen
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.pagetic = 35 * 11
        CDoom.pagename = "TITLEPIC"
        CDoom.s_start_music(CDoom::Musicenum::MUS_dm2ttl)
      else
        CDoom.pagetic = 200

        if CDoom.gamemode == CDoom::GameMode::Retail
          CDoom.pagename = "CREDIT"
        else
          CDoom.pagename = "HELP2"
        end
      end
    when 5
      CDoom.g_defered_play_demo("demo3")
      # THE DEFINITIVE DOOM Special Edition demo
    when 6
      CDoom.g_defered_play_demo("demo4")
    end
  end

  def self.d_start_title
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.demosequence = -1
    CDoom.d_advance_demo
  end

  def self.d_add_file(file : UInt8*)
    numwadfiles = 0
    until CDoom.wadfiles[numwadfiles].null?
      numwadfiles += 1
    end

    newfile = CDoom.doom_malloc.call(doom_strlen(file) + 1)
    CDoom.doom_strcpy(newfile.as(UInt8*), file)

    CDoom.wadfiles[numwadfiles] = newfile.as(UInt8*)
  end

  #
  # identify_version
  # Checks availability of IWAD files by name,
  # to determine whether registered/commercial features
  # should be executed (notably loading PWAD's).
  #
  def self.identify_version
    doomwaddir = CDoom.doom_getenv.call("DOOMWADDIR".to_unsafe)
    doomwaddir = ".".to_unsafe if doomwaddir.null?

    # Commercial.
    doom2wad = CDoom.doom_malloc.call(CDoom.doom_strlen(doomwaddir) + 1 + 9 + 1).as(UInt8*)
    CDoom.doom_strcpy(doom2wad, doomwaddir)
    CDoom.doom_concat(doom2wad, "/doom2.wad")

    # Retail.
    doomuwad = CDoom.doom_malloc.call(CDoom.doom_strlen(doomwaddir) + 1 + 8 + 1).as(UInt8*)
    CDoom.doom_strcpy(doomuwad, doomwaddir)
    CDoom.doom_concat(doomuwad, "/doomu.wad")

    # Registered.
    doomwad = CDoom.doom_malloc.call(CDoom.doom_strlen(doomwaddir) + 1 + 8 + 1).as(UInt8*)
    CDoom.doom_strcpy(doomwad, doomwaddir)
    CDoom.doom_concat(doomwad, "/doom.wad")

    # Shareware.
    doom1wad = CDoom.doom_malloc.call(CDoom.doom_strlen(doomwaddir) + 1 + 9 + 1).as(UInt8*)
    CDoom.doom_strcpy(doom1wad, doomwaddir)
    CDoom.doom_concat(doom1wad, "/doom1.wad")

    # Bug, dear Shawn.
    # Insufficient malloc, caused spurious realloc errors.
    plutoniawad = CDoom.doom_malloc.call(CDoom.doom_strlen(doomwaddir) + 1 + 12 + 1).as(UInt8*)
    CDoom.doom_strcpy(plutoniawad, doomwaddir)
    CDoom.doom_concat(plutoniawad, "/plutonia.wad")

    tntwad = CDoom.doom_malloc.call(CDoom.doom_strlen(doomwaddir) + 1 + 9 + 1).as(UInt8*)
    CDoom.doom_strcpy(tntwad, doomwaddir)
    CDoom.doom_concat(tntwad, "/tnt.wad")

    # French stuff
    doom2fwad = CDoom.doom_malloc.call(CDoom.doom_strlen(doomwaddir) + 1 + 10 + 1).as(UInt8*)
    CDoom.doom_strcpy(doom2fwad, doomwaddir)
    CDoom.doom_concat(doom2fwad, "/doom2f.wad")

    {% if !CDoom.has_constant?("DOOM_WIN32") %}
      home = CDoom.doom_getenv.call("HOME".to_unsafe)
      if home.null?
        CDoom.i_error("Error: Please set $HOME to your home directory")
      end
    {% else %}
      home = ".".to_unsafe
    {% end %}
    home = ".".to_unsafe # Don't be cute. Just use binary dir

    CDoom.doom_strcpy(CDoom.basedefault, home)
    CDoom.doom_concat(CDoom.basedefault, "/config.cfg")

    if CDoom.m_check_parm("-shdev") != 0
      CDoom.gamemode = CDoom::GameMode::Shareware
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.devparm = 1
      CDoom.d_add_file(CDoom::DEVDATA + "doom1.wad")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/texture1.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/pnames.lmp")
      CDoom.doom_strcpy(CDoom.basedefault, CDoom::DEVDATA + "default.cfg")
      return
    end

    if CDoom.m_check_parm("-regdev") != 0
      CDoom.gamemode = CDoom::GameMode::Registered
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.devparm = 1
      CDoom.d_add_file(CDoom::DEVDATA + "doom.wad")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/texture1.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/texture2.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/pnames.lmp")
      CDoom.doom_strcpy(CDoom.basedefault, CDoom::DEVDATA + "default.cfg")
      return
    end

    if CDoom.m_check_parm("-comdev") != 0
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::Doom2
      CDoom.devparm = 1
      CDoom.d_add_file(CDoom::DEVDATA + "doom2.wad")

      CDoom.d_add_file(CDoom::DEVMAPS + "cdata/texture1.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "cdata/pnames.lmp")
      CDoom.doom_strcpy(CDoom.basedefault, CDoom::DEVDATA + "default.cfg")
      return
    end

    if !(f = CDoom.doom_open.call(doom2fwad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::Doom2
      # C'est ridicule!
      # Let's handle languages in config files, okay?
      CDoom.language = CDoom::Language::French
      CDoom.doom_print.call("French version\n".to_unsafe)
      CDoom.d_add_file(doom2fwad)
      return
    end

    if !(f = CDoom.doom_open.call(doom2wad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::Doom2
      CDoom.d_add_file(doom2wad)
      return
    end

    if !(f = CDoom.doom_open.call(plutoniawad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::PackPlut
      CDoom.d_add_file(plutoniawad)
      return
    end

    if !(f = CDoom.doom_open.call(tntwad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.gamemission = CDoom::GameMission::PackTnt
      CDoom.d_add_file(tntwad)
      return
    end

    if !(f = CDoom.doom_open.call(doomuwad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Retail
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.d_add_file(doomuwad)
      return
    end

    if !(f = CDoom.doom_open.call(doomwad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Registered
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.d_add_file(doomwad)
      return
    end

    if !(f = CDoom.doom_open.call(doom1wad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Shareware
      CDoom.gamemission = CDoom::GameMission::Doom
      CDoom.d_add_file(doom1wad)
      return
    end

    CDoom.doom_print.call("Game mode indeterminate.\n".to_unsafe)
    CDoom.gamemode = CDoom::GameMode::Indetermined
  end

  #
  # Find a Response File
  #
  def self.find_response_file
    (CDoom.myargc - 1).times do |i|
      i += 1

      if CDoom.myargv[i][0].chr == '@'
        moreargs = uninitialized StaticArray(UInt8*, 20)

        # READ THE RESPONSE FILE INTO MEMORY
        handle = CDoom.doom_open.call(CDoom.myargv[i] + 1, "rb".to_unsafe)
        if handle.null?
          CDoom.doom_print.call("\nNo such response file!".to_unsafe)
          CDoom.doom_exit.call(1)
        end
        CDoom.doom_print.call("Found response file #{String.new(CDoom.myargv[i] + 1)}!\n".to_unsafe)
        CDoom.doom_seek.call(handle, 0, CDoom::DoomSeek::DOOM_SEEK_END)
        size = CDoom.doom_tell.call(handle)
        CDoom.doom_seek.call(handle, 0, CDoom::DoomSeek::DOOM_SEEK_SET)
        file = CDoom.doom_malloc.call(size)
        CDoom.doom_read.call(handle, file, size * 1)
        CDoom.doom_close.call(handle)

        # KEEP ALL CMDLINE ARGS FOLLOWING @RESPONSEFILE ARG
        index = 0
        k = i + 1
        while k < CDoom.myargc
          moreargs[index] = CDoom.myargv[k]
          index += 1
          k += 1
        end

        firstargv = CDoom.myargv[i]
        CDoom.myargv = CDoom.doom_malloc.call(sizeof(UInt8*) * CDoom::MAXARGVS).as(UInt8**)
        CDoom.doom_memset(CDoom.myargv, 0, sizeof(UInt8*) * CDoom::MAXARGVS)
        CDoom.myargv[0] = firstargv

        infile = file.as(UInt8*)
        indexinfile = 0
        k = 0
        indexinfile += 1 # SKIP PAST ARGV[0] (KEEP IT)
        loop do
          CDoom.myargv[indexinfile] = infile + k
          indexinfile += 1
          while k < size &&
                (((infile + k).value >= ' '.ord + 1) && ((infile + k).value <= 'z'.ord))
            k += 1
          end
          (infile + k).value = 0
          while k < size &&
                (((infile + k).value <= ' '.ord) || ((infile + k).value > 'z'.ord))
            k += 1
          end

          break if !(k < size)
        end

        k = 0
        while k < index
          CDoom.myargv[indexinfile] = moreargs[k]
          indexinfile += 1
          k += 1
        end
        CDoom.myargc = indexinfile

        # DISPLAY ARGS
        CDoom.doom_print.call(CDoom.doom_itoa(CDoom.myargc, 10))
        CDoom.doom_print.call(" command-line args: \n".to_unsafe)
        k = 1
        while k < CDoom.myargc
          CDoom.doom_print.call(CDoom.myargv[k])
          CDoom.doom_print.call("\n".to_unsafe)
          k += 1
        end

        break
      end
    end
  end

  #
  # d_doom_main
  #
  def self.d_doom_main
    file = uninitialized StaticArray(UInt8, 256)

    CDoom.find_response_file

    CDoom.identify_version

    CDoom.modifiedgame = 0

    CDoom.nomonsters = CDoom.m_check_parm("-nomonsters")
    CDoom.respawnparm = CDoom.m_check_parm("-respawn")
    CDoom.fastparm = CDoom.m_check_parm("-fast")
    CDoom.devparm = CDoom.m_check_parm("-devparm")
    if CDoom.m_check_parm("-altdeath") != 0
      CDoom.deathmatch = 2
    elsif CDoom.m_check_parm("-deathmatch") != 0
      CDoom.deathmatch = 1
    end

    case CDoom.gamemode
    when CDoom::GameMode::Retail
      CDoom.doom_strcpy(CDoom.title, "                         " + "The Ultimate DOOM Startup v")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
      CDoom.doom_concat(CDoom.title, ".")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
      CDoom.doom_concat(CDoom.title, "                           ")
    when CDoom::GameMode::Shareware
      CDoom.doom_strcpy(CDoom.title, "                         " + "DOOM Shareware Startup v")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
      CDoom.doom_concat(CDoom.title, ".")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
      CDoom.doom_concat(CDoom.title, "                           ")
    when CDoom::GameMode::Registered
      CDoom.doom_strcpy(CDoom.title, "                         " + "DOOM Registered Startup v")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
      CDoom.doom_concat(CDoom.title, ".")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
      CDoom.doom_concat(CDoom.title, "                           ")
    when CDoom::GameMode::Commercial
      case CDoom.gamemission
      when CDoom::GameMission::PackPlut
        CDoom.doom_strcpy(CDoom.title, "                         " + "Final Doom: The Plutonia Experiment v")
        CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
        CDoom.doom_concat(CDoom.title, ".")
        CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
        CDoom.doom_concat(CDoom.title, "                           ")
      when CDoom::GameMission::PackTnt
        CDoom.doom_strcpy(CDoom.title, "                         " + "Final Doom: TNT: Evilution v")
        CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
        CDoom.doom_concat(CDoom.title, ".")
        CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
        CDoom.doom_concat(CDoom.title, "                           ")
      else
        CDoom.doom_strcpy(CDoom.title, "                         " + "DOOM 2: Hell on Earth v")
        CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
        CDoom.doom_concat(CDoom.title, ".")
        CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
        CDoom.doom_concat(CDoom.title, "                           ")
      end
    else
      CDoom.doom_strcpy(CDoom.title, "                         " + "Public DOOM - v")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
      CDoom.doom_concat(CDoom.title, ".")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
      CDoom.doom_concat(CDoom.title, "                           ")
    end

    CDoom.doom_print.call(CDoom.title.to_unsafe)
    CDoom.doom_print.call("\n".to_unsafe)

    CDoom.doom_print.call(CDoom::D_DEVSTR.to_unsafe) if CDoom.devparm != 0

    {% if false %}
      # [pd] Ignore cdrom
      if CDoom.m_check_parm("-cdrom") != 0
        CDoom.doom_print.call(CDoom::D_CDROM.to_unsafe)
        Dir.mkdir("c:\\doomdata")
        CDoom.doom_strcpy(CDoom.basedefault, "c:/doomdata/default.cfg")
      end
    {% end %}

    # turbo option
    if (p = CDoom.m_check_parm("-turbo")) != 0
      scale = 200

      if p < CDoom.myargc - 1
        scale = CDoom.doom_atoi(CDoom.myargv[p + 1])
      end
      scale = 10 if scale < 10
      scale = 400 if scale > 400
      CDoom.doom_print.call("turbo scale: ".to_unsafe)
      CDoom.doom_print.call(CDoom.doom_itoa(scale, 10))
      CDoom.doom_print.call("%\n".to_unsafe)
      CDoom.forwardmove[0] = CDoom.forwardmove[0] * scale // 100
      CDoom.forwardmove[1] = CDoom.forwardmove[1] * scale // 100
      CDoom.sidemove[0] = CDoom.sidemove[0] * scale // 100
      CDoom.sidemove[1] = CDoom.sidemove[1] * scale // 100
    end

    # add any files specified on the command line with -file wadfile
    # to the wad list
    #
    # convenience hack to allow -wart e m to add a wad file
    # prepend a tilde to the filename so wadfile will be reloadable
    p = CDoom.m_check_parm("-wart")
    if p != 0
      CDoom.myargv[p][4] = 'p'.ord.to_u8 # big hack, change to -warp

      # Map name handling
      case CDoom.gamemode
      when CDoom::GameMode::Shareware, CDoom::GameMode::Retail, CDoom::GameMode::Registered
        CDoom.doom_strcpy(file, "~#{CDoom::DEVMAPS}E")
        CDoom.doom_concat(file, CDoom.doom_ctoa(CDoom.myargv[p + 1][0]))
        CDoom.doom_concat(file, "M")
        CDoom.doom_concat(file, CDoom.doom_ctoa(CDoom.myargv[p + 2][0]))
        CDoom.doom_concat(file, ".wad")

        CDoom.doom_print.call("Warping to Episode ".to_unsafe)
        CDoom.doom_print.call(CDoom.myargv[p + 1])
        CDoom.doom_print.call(", Map ".to_unsafe)
        CDoom.doom_print.call(CDoom.myargv[p + 2])
        CDoom.doom_print.call(".\n".to_unsafe)
        # when CDoom::GameMode::Commercial
      else
        p = CDoom.doom_atoi(CDoom.myargv[p + 1])
        if p < 10
          CDoom.doom_strcpy(file, "~#{CDoom::DEVMAPS}cdata/map0")
          CDoom.doom_concat(file, CDoom.doom_itoa(p, 10))
          CDoom.doom_concat(file, ".wad")
        else
          CDoom.doom_strcpy(file, "~#{CDoom::DEVMAPS}cdata/map")
          CDoom.doom_concat(file, CDoom.doom_itoa(p, 10))
          CDoom.doom_concat(file, ".wad")
        end
      end
      CDoom.d_add_file(file)
    end

    p = CDoom.m_check_parm("-file")
    if p != 0
      # the parms after p are wadfile/lump names,
      # until end of parms or another - preceded parm
      CDoom.modifiedgame = 1 # homebrew levels
      while (p += 1) != CDoom.myargc && CDoom.myargv[p][0].chr != '-'
        CDoom.d_add_file(CDoom.myargv[p])
      end
    end

    p = CDoom.m_check_parm("-playdemo")

    p = CDoom.m_check_parm("-timedemo") if p == 0

    if p != 0 && p < CDoom.myargc - 1
      CDoom.doom_strcpy(file, CDoom.myargv[p + 1])
      CDoom.doom_concat(file, ".lmp")
      CDoom.d_add_file(file)
      CDoom.doom_print.call("Playing demo ".to_unsafe)
      CDoom.doom_print.call(CDoom.myargv[p + 1])
      CDoom.doom_print.call(".lmp.\n".to_unsafe)
    end

    # get skill / episode / map from parms
    CDoom.startskill = CDoom::Skill::Medium
    CDoom.startepisode = 1
    CDoom.startmap = 1
    CDoom.autostart = 0

    p = CDoom.m_check_parm("-skill")
    if p != 0 && p < CDoom.myargc - 1
      CDoom.startskill = CDoom::Skill.new(CDoom.myargv[p + 1][0] - '1'.ord)
      CDoom.autostart = 1
    end

    p = CDoom.m_check_parm("-episode")
    if p != 0 && p < CDoom.myargc - 1
      CDoom.startepisode = CDoom.myargv[p + 1][0] - '0'.ord
      CDoom.startmap = 1
      CDoom.autostart = 1
    end

    CDoom.m_check_parm("-timer")
    if p != 0 && p < CDoom.myargc - 1 && CDoom.deathmatch != 0
      time = CDoom.doom_atoi(CDoom.myargv[p + 1])
      CDoom.doom_print.call("Levels will end after ".to_unsafe)
      CDoom.doom_print.call(CDoom.doom_itoa(time, 10))
      CDoom.doom_print.call(" minute".to_unsafe)
      CDoom.doom_print.call("s".to_unsafe) if time > 1
      CDoom.doom_print.call(".\n".to_unsafe)
    end

    p = CDoom.m_check_parm("-avg")
    if p != 0 && p < CDoom.myargc - 1 && CDoom.deathmatch != 0
      CDoom.doom_print.call("Austin Virtual Gaming: Levels will end after 20 minutes\n".to_unsafe)
    end

    p = CDoom.m_check_parm("-warp")
    if p != 0
      if p < CDoom.myargc - 1 && CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.startmap = CDoom.doom_atoi(CDoom.myargv[p + 1])
      elsif p < CDoom.myargc - 2
        CDoom.startepisode = CDoom.myargv[p + 1][0] - '0'.ord
        CDoom.startmap = CDoom.myargv[p + 2][0] - '0'.ord
      end
      CDoom.autostart = 1
    end

    # init subsystems
    CDoom.doom_print.call("v_init: allocate screens.\n".to_unsafe)
    CDoom.v_init

    CDoom.doom_print.call("m_load_defaults: Load system defaults.\n".to_unsafe)
    CDoom.m_load_defaults # load before initing other systems

    CDoom.doom_print.call("z_init: Init zone memory allocation daemon. \n".to_unsafe)
    CDoom.z_init

    CDoom.doom_print.call("w_init: Init Wadfiles.\n".to_unsafe)
    CDoom.w_init_multiple_files(CDoom.wadfiles)

    # Check for -file in shareware
    if CDoom.modifiedgame != 0
      # These are the lumps that will be checked in IWAD,
      # if any one is not present, execution will be aborted.
      name = [
        "e2m1", "e2m2", "e2m3", "e2m4", "e2m5", "e2m6", "e2m7", "e2m8", "e2m9",
        "e3m1", "e3m3", "e3m3", "e3m4", "e3m5", "e3m6", "e3m7", "e3m8", "e3m9",
        "dphoof", "bfgga0", "heada1", "cybra1", "spida1d1",
      ]

      if CDoom.gamemode == CDoom::GameMode::Shareware
        CDoom.i_error("Error: \nYou cannot -file with the shareware version. Register!")
      end

      # Check for fake IWAD with right name,
      # but w/o all the lumps of the registered version.
      if CDoom.gamemode == CDoom::GameMode::Registered
        23.times do |i|
          if CDoom.w_check_num_for_name(name[i]) < 0
            CDoom.i_error("Error: \nThis is not the registered version.")
          end
        end
      end
    end

    # Iff additonal PWAD files are used, print modified banner
    if CDoom.modifiedgame != 0
      CDoom.doom_print.call(
        ("===========================================================================\n" +
         "ATTENTION:  This version of DOOM has been modified.  If you would like to\n" +
         "get a copy of the original game, call 1-800-IDGAMES or see the readme file.\n" +
         "        You will not receive technical support for modified games.\n" +
         # "                      press enter to continue\n" +
         "===========================================================================\n").to_unsafe
      )
    end

    # Check and print which version is executed.
    case CDoom.gamemode
    when CDoom::GameMode::Shareware, CDoom::GameMode::Indetermined
      CDoom.doom_print.call(
        ("===========================================================================\n" +
         "                                Shareware!\n" +
         "===========================================================================\n").to_unsafe
      )
    when CDoom::GameMode::Registered, CDoom::GameMode::Retail, CDoom::GameMode::Commercial
      CDoom.doom_print.call(
        ("===========================================================================\n" +
         "                 Commercial product - do not distribute!\n" +
         "         Please report software piracy to the SPA: 1-800-388-PIR8\n" +
         "===========================================================================\n").to_unsafe
      )
    else
      # Ouch
    end

    CDoom.doom_print.call("m_init: Init miscellaneous info.\n".to_unsafe)
    CDoom.m_init

    CDoom.doom_print.call("r_init: Init DOOM refresh daemon - ".to_unsafe)
    CDoom.r_init

    CDoom.doom_print.call("\np_init: Init Playloop state.\n".to_unsafe)
    CDoom.p_init

    CDoom.doom_print.call("i_init: Setting up machine state.\n".to_unsafe)
    CDoom.i_init

    CDoom.doom_print.call("d_check_net_game: Checking network game status.\n".to_unsafe)
    CDoom.d_check_net_game

    CDoom.doom_print.call("s_init: Setting up sound.\n".to_unsafe)
    CDoom.s_init(CDoom.snd_sfx_volume, CDoom.snd_music_volume)

    CDoom.doom_print.call("hu_init: Setting up heads up display.\n".to_unsafe)
    CDoom.hu_init

    CDoom.doom_print.call("st_init: Init status bar.\n".to_unsafe)
    CDoom.st_init

    # check for a driver that wants intermission stats
    {% if false %}
      # [pd] Unsure how to test this
      p = CDoom.m_check_parm("-statcopy")
      if p != 0 && p < CDoom.myargc - 1
        # for statistics driver
        CDoom.statcopy = String.new(CDoom.myargv[p + 1]).to_i64.as(Void*)
        CDoom.doom_print.call("External statistics registered.\n".to_unsafe)
      end
    {% end %}

    # start the apropriate game based on parms
    p = CDoom.m_check_parm("-record")

    if p != 0 && p < CDoom.myargc - 1
      CDoom.g_record_demo(CDoom.myargv[p + 1])
      CDoom.autostart = 1
    end

    p = CDoom.m_check_parm("-playdemo")
    if p != 0 && p < CDoom.myargc - 1
      CDoom.singledemo = 0 # quit after one demo
      CDoom.g_defered_play_demo(CDoom.myargv[p + 1])
      CDoom.d_doom_loop # never returns
    end

    p = CDoom.m_check_parm("-timedemo")
    if p != 0 && p < CDoom.myargc - 1
      CDoom.g_time_demo(CDoom.myargv[p + 1])
      CDoom.d_doom_loop # never returns
    end

    p = CDoom.m_check_parm("-loadgame")
    if p != 0 && p < CDoom.myargc - 1
      # [pd] We don't support the cdrom flag
      # if CDoom.m_check_parm("-cdrom")
      #   CDoom.doom_strcpy(file, "c:\\doomdata\\")
      #   CDoom.doom_concat(file, CDoom::SAVEGAMENAME)
      #   CDoom.doom_concat(file, CDoom.doom_ctoa(CDoom.myargv[p + 1][0]))
      #   CDoom.doom_concat(file, ".dsg")
      # else
      CDoom.doom_strcpy(file, CDoom::SAVEGAMENAME)
      CDoom.doom_concat(file, CDoom.doom_ctoa(CDoom.myargv[p + 1][0]))
      CDoom.doom_concat(file, ".dsg")
      # end
      CDoom.g_load_game(file)
    end

    if CDoom.gameaction != CDoom::Gameaction::Loadgame
      if CDoom.autostart != 0 || CDoom.netgame != 0
        CDoom.g_init_new(CDoom.startskill, CDoom.startepisode, CDoom.startmap)
      else
        CDoom.d_start_title # start up intro loop
      end
    end

    # CDoom.d_doom_loop # never returns [ddos] Called by app

    CDoom.g_begin_recording if CDoom.demorecording != 0

    if CDoom.m_check_parm("-debugfile") != 0
      filename = uninitialized StaticArray(UInt8, 20)
      CDoom.doom_strcpy(filename, "debug")
      CDoom.doom_concat(filename, CDoom.doom_itoa(CDoom.consoleplayer, 10))
      CDoom.doom_concat(filename, ".txt")

      CDoom.doom_print.call("debug output to: ".to_unsafe)
      CDoom.doom_print.call(filename.to_unsafe)
      CDoom.doom_print.call("\n".to_unsafe)
      CDoom.debugfile = CDoom.doom_open.call(filename.to_unsafe, "w".to_unsafe)
    end

    CDoom.i_init_graphics
  end

  def self.net_buffer_size : Int32
    return offsetof(CDoom::Doomdata, @cmds) + sizeof(CDoom::Ticcmd) * CDoom.netbuffer.value.numtics
  end

  #
  # Checksum
  #
  def self.net_buffer_checksum : UInt32
    c = 0x1234567_u32

    l = (CDoom.net_buffer_size - offsetof(CDoom::Doomdata, @retransmitfrom)) // 4
    l.times do |i|
      c += (pointerof(CDoom.netbuffer.value.@retransmitfrom)).as(UInt32*)[i] * (i + 1)
    end

    return c & CDoom::NCMD_CHECKSUM
  end

  def self.expand_tics(low : Int32) : Int32
    delta = low - (CDoom.maketic & 0xff)

    if delta >= -64 && delta <= 64
      return (CDoom.maketic & ~0xff) + low
    end
    if delta > 64
      return (CDoom.maketic & ~0xff) - 256 + low
    end
    if delta < -64
      return (CDoom.maketic & ~0xff) + 256 + low
    end

    CDoom.doom_strcpy(CDoom.error_buf, "Error: expand_tics: strange value ")
    CDoom.doom_concat(CDoom.error_buf, CDoom.doom_itoa(low, 10))
    CDoom.doom_concat(CDoom.error_buf, " at maketic ")
    CDoom.doom_concat(CDoom.error_buf, CDoom.doom_itoa(CDoom.maketic, 10))
    CDoom.i_error(CDoom.error_buf)
    return 0
  end

  def self.h_send_packet(node : Int32, flags : Int32)
    CDoom.netbuffer.value.checksum = CDoom.net_buffer_checksum | flags

    if node == 0
      CDoom.reboundstore = CDoom.netbuffer.value
      CDoom.reboundpacket = 1
      return
    end

    return if CDoom.demoplayback != 0

    CDoom.i_error("Error: Tried to transmit to another node") if CDoom.netgame == 0

    CDoom.doomcom.value.command = CDoom::Command::SEND
    CDoom.doomcom.value.remotenode = node
    CDoom.doomcom.value.datalength = CDoom.net_buffer_size

    if !CDoom.debugfile.null?
      realretrans = -1
      if CDoom.netbuffer.value.checksum & CDoom::NCMD_RETRANSMIT != 0
        realretrans = CDoom.expand_tics(CDoom.netbuffer.value.retransmitfrom)
      end

      CDoom.doom_fprint(CDoom.debugfile, "send (")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.expand_tics(CDoom.netbuffer.value.starttic), 10))
      CDoom.doom_fprint(CDoom.debugfile, " + ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.value.numtics, 10))
      CDoom.doom_fprint(CDoom.debugfile, ", R ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realretrans, 10))
      CDoom.doom_fprint(CDoom.debugfile, ") [")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.datalength, 10))
      CDoom.doom_fprint(CDoom.debugfile, "] ")

      CDoom.doomcom.value.datalength.times do |i|
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.as(UInt8*)[i], 10))
        CDoom.doom_fprint(CDoom.debugfile, " ")
      end

      CDoom.doom_fprint(CDoom.debugfile, "\n")
    end

    CDoom.i_net_cmd
  end

  #
  # h_get_packet
  # Returns false if no packet is waiting
  #
  def self.h_get_packet
    if CDoom.reboundpacket != 0
      CDoom.netbuffer.value = CDoom.reboundstore
      CDoom.doomcom.value.remotenode = 0
      CDoom.reboundpacket = 0
      return 1
    end

    return 0 if CDoom.netgame == 0

    return 0 if CDoom.demoplayback != 0

    CDoom.doomcom.value.command = CDoom::Command::GET
    CDoom.i_net_cmd

    return 0 if CDoom.doomcom.value.remotenode == -1

    if CDoom.doomcom.value.datalength != CDoom.net_buffer_size
      if !CDoom.debugfile.null?
        CDoom.doom_fprint(CDoom.debugfile, "bad packet length ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.datalength, 10))
        CDoom.doom_fprint(CDoom.debugfile, "\n")
      end
      return 0
    end

    if CDoom.net_buffer_checksum != CDoom.netbuffer.value.checksum & CDoom::NCMD_CHECKSUM
      if !CDoom.debugfile.null?
        CDoom.doom_fprint(CDoom.debugfile, "bad packet checksum\n")
      end
      return 0
    end

    if !CDoom.debugfile.null?
      if CDoom.netbuffer.value.checksum & CDoom::NCMD_SETUP != 0
        CDoom.doom_fprint(CDoom.debugfile, "setup packet\n")
      else
        realretrans = -1
        if CDoom.netbuffer.value.checksum & CDoom::NCMD_RETRANSMIT != 0
          realretrans = CDoom.expand_tics(CDoom.netbuffer.value.retransmitfrom)
        end

        CDoom.doom_fprint(CDoom.debugfile, "get ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.remotenode, 10))
        CDoom.doom_fprint(CDoom.debugfile, " = (")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.expand_tics(CDoom.netbuffer.value.starttic), 10))
        CDoom.doom_fprint(CDoom.debugfile, " + ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.value.numtics, 10))
        CDoom.doom_fprint(CDoom.debugfile, ", R ")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realretrans, 10))
        CDoom.doom_fprint(CDoom.debugfile, ")[")
        CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.doomcom.value.datalength, 10))
        CDoom.doom_fprint(CDoom.debugfile, "]")

        CDoom.doomcom.value.datalength.times do |i|
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.as(UInt8*)[i], 10))
          CDoom.doom_fprint(CDoom.debugfile, " ")
        end
        CDoom.doom_fprint(CDoom.debugfile, "\n")
      end
    end
    return 1
  end

  #
  # get_packets
  #
  def self.get_packets
    while CDoom.h_get_packet != 0
      next if CDoom.netbuffer.value.checksum & CDoom::NCMD_SETUP != 0 # extra setup packet

      netconsole = CDoom.netbuffer.value.player & ~CDoom::PL_DRONE
      netnode = CDoom.doomcom.value.remotenode

      # to save bytes, only the low byte of tic numbers are sent
      # Figure out what the rest of the bytes are
      realstart = CDoom.expand_tics(CDoom.netbuffer.value.starttic)
      realend = realstart + CDoom.netbuffer.value.numtics

      # check for exiting the game
      if CDoom.netbuffer.value.checksum & CDoom::NCMD_EXIT != 0
        next if CDoom.nodeingame[netnode] == 0
        CDoom.nodeingame[netnode] = 0
        CDoom.playeringame[netconsole] = 0
        CDoom.doom_strcpy(CDoom.exitmsg, "Player 1 left the game")
        CDoom.exitmsg[7] += netconsole
        (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom.exitmsg
        CDoom.g_check_demo_status if CDoom.demorecording != 0
        next
      end

      # check for a remote game kill
      CDoom.i_error("Error: Killed by network driver") if CDoom.netbuffer.value.checksum & CDoom::NCMD_KILL != 0

      CDoom.nodeforplayer[netconsole] = netnode

      # check for retransmit request
      if CDoom.resendcount[netnode] <= 0 &&
         (CDoom.netbuffer.value.checksum & CDoom::NCMD_RETRANSMIT) != 0
        CDoom.resendto[netnode] = CDoom.expand_tics(CDoom.netbuffer.value.retransmitfrom)
        if !CDoom.debugfile.null?
          CDoom.doom_fprint(CDoom.debugfile, "retransmit from ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.resendto[netnode], 10))
          CDoom.doom_fprint(CDoom.debugfile, "\n")
        end
        CDoom.resendcount[netnode] = CDoom::RESENDCOUNT
      else
        CDoom.resendcount[netnode] -= 1
      end

      # check for out of order / duplicated packet
      next if realend == CDoom.nettics[netnode]

      if realend < CDoom.nettics[netnode]
        if !CDoom.debugfile.null?
          CDoom.doom_fprint(CDoom.debugfile, "out of order packet (")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realstart, 10))
          CDoom.doom_fprint(CDoom.debugfile, " + ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.netbuffer.value.numtics, 10))
          CDoom.doom_fprint(CDoom.debugfile, ")\n")
        end
        next
      end

      # check for a missed packet
      if realstart > CDoom.nettics[netnode]
        # stop processing until the other system resends the missed tics
        if !CDoom.debugfile.null?
          CDoom.doom_fprint(CDoom.debugfile, "missed tics from ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(netnode, 10))
          CDoom.doom_fprint(CDoom.debugfile, " (")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realstart, 10))
          CDoom.doom_fprint(CDoom.debugfile, " - ")
          CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(CDoom.nettics[netnode], 10))
          CDoom.doom_fprint(CDoom.debugfile, ")\n")
        end
        CDoom.remoteresend[netnode] = 1
        next
      end

      # update command store from the packet
      CDoom.remoteresend[netnode] = 0

      start = CDoom.nettics[netnode] - realstart
      src = CDoom.netbuffer.value.cmds.to_unsafe + start

      while CDoom.nettics[netnode] < realend
        dest = CDoom.netcmds[netconsole].to_unsafe + CDoom.nettics[netnode] % CDoom::BACKUPTICS
        CDoom.nettics[netnode] += 1
        dest.value = src.value
        src += 1
      end
    end
  end

  #
  # net_update
  # Builds ticcmds for console player,
  # sends out a packet
  #
  def self.net_update
    return if CDoom.singletics != 0 # singletic update is syncronous

    # check time
    nowtime = CDoom.i_get_time // CDoom.ticdup
    newtics = nowtime - CDoom.gametime
    CDoom.gametime = nowtime

    if newtics > 0 # something new to update
      if CDoom.skiptics <= newtics
        newtics -= CDoom.skiptics
        CDoom.skiptics = 0
      else
        CDoom.skiptics -= newtics
        newtics = 0
      end

      CDoom.netbuffer.value.player = CDoom.consoleplayer

      # build new ticcmds for console player
      gameticdiv = CDoom.gametic // CDoom.ticdup
      newtics.times do |i|
        CDoom.i_start_tic
        CDoom.d_process_events
        break if CDoom.maketic - gameticdiv >= CDoom::BACKUPTICS // 2 - 1 # can't hold any more

        CDoom.g_build_ticcmd(CDoom.localcmds.to_unsafe + CDoom.maketic % CDoom::BACKUPTICS)
        CDoom.maketic += 1
      end

      # send the packet to the other nodes
      CDoom.numnodes.times do |i|
        if CDoom.nodeingame[i] != 0
          CDoom.netbuffer.value.starttic = CDoom.resendto[i]
          realstart = CDoom.resendto[i]
          CDoom.netbuffer.value.numtics = CDoom.maketic - realstart
          if CDoom.netbuffer.value.numtics > CDoom::BACKUPTICS
            CDoom.i_error("Error: net_update: netbuffer.value.numtics > BACKUPTICS")
          end

          CDoom.resendto[i] = CDoom.maketic - CDoom.doomcom.value.extratics

          CDoom.netbuffer.value.numtics.times do |j|
            CDoom.netbuffer.value.cmds[j] =
              CDoom.localcmds[(realstart + j) % CDoom::BACKUPTICS]
          end

          if CDoom.remoteresend[i] != 0
            CDoom.netbuffer.value.retransmitfrom = CDoom.nettics[i]
            CDoom.h_send_packet(i, CDoom::NCMD_RETRANSMIT)
          else
            CDoom.netbuffer.value.retransmitfrom = 0
            CDoom.h_send_packet(i, 0)
          end
        end
      end
    end
    # listen for other packets
    CDoom.get_packets
  end

  #
  # check_abort
  #
  def self.check_abort
    stoptic = CDoom.i_get_time + 2
    while CDoom.i_get_time < stoptic
      CDoom.i_start_tic
    end

    CDoom.i_start_tic
    while CDoom.eventtail != CDoom.eventhead
      ev = CDoom.events.to_unsafe + CDoom.eventtail
      if ev.value.type == CDoom::Evtype::Keydown && ev.value.data1 == CDoom::KEY_ESCAPE
        CDoom.i_error("Error: Network game synchronization aborted.")
      end
      CDoom.eventtail += 1
      CDoom.eventtail = (CDoom.eventtail) & (CDoom::MAXEVENTS - 1)
    end
  end

  #
  # d_arbitrate_net_start
  #
  def self.d_arbitrate_net_start
    gotinfo = uninitialized StaticArray(CDoom::DoomBool, CDoom::MAXNETNODES)

    CDoom.autostart = 1
    CDoom.doom_memset(gotinfo, 0, sizeof(typeof(gotinfo)))

    if CDoom.doomcom.value.consoleplayer != 0
      # listen for setup info from key player
      CDoom.doom_print.call("listening for network start info...\n".to_unsafe)
      while true
        CDoom.check_abort
        next if CDoom.h_get_packet == 0
        if CDoom.netbuffer.value.checksum & CDoom::NCMD_SETUP != 0
          if CDoom.netbuffer.value.player != CDoom::VERSION
            CDoom.i_error("Error: Different DOOM versions cannot play a net game!")
          end
          CDoom.startskill = CDoom::Skill.new(CDoom.netbuffer.value.retransmitfrom & 15)
          CDoom.deathmatch = (CDoom.netbuffer.value.retransmitfrom & 0xc0) >> 6
          CDoom.nomonsters = (CDoom.netbuffer.value.retransmitfrom & 0x20) > 0
          CDoom.respawnparm = (CDoom.netbuffer.value.retransmitfrom & 0x10) > 0
          CDoom.startmap = CDoom.netbuffer.value.starttic & 0x3f
          CDoom.startepisode = CDoom.netbuffer.value.starttic >> 6
          return
        end
      end
    else
      # key player, send the setup info
      CDoom.doom_print.call("sending network start info...\n".to_unsafe)
      loop do
        CDoom.check_abort
        CDoom.doomcom.value.numnodes.times do |i|
          CDoom.netbuffer.value.retransmitfrom = CDoom.startskill
          if CDoom.deathmatch != 0
            CDoom.netbuffer.value.retransmitfrom |= (CDoom.deathmatch << 6)
          end
          if CDoom.nomonsters != 0
            CDoom.netbuffer.value.retransmitfrom |= 0x20
          end
          if CDoom.respawnparm != 0
            CDoom.netbuffer.value.retransmitfrom |= 0x10
          end
          CDoom.netbuffer.value.starttic = CDoom.startepisode * 64 + CDoom.startmap
          CDoom.netbuffer.value.player = CDoom::VERSION
          CDoom.netbuffer.value.numtics = 0
          CDoom.h_send_packet(i, CDoom::NCMD_SETUP)
        end

        {% if true %}
          i = 10
          while i != 0 && CDoom.h_get_packet != 0
            if (CDoom.netbuffer.value.player & 0x7f) < CDoom::MAXNETNODES
              gotinfo[CDoom.netbuffer.value.player & 0x7f] = 1
              i -= 1
            end
          end
        {% else %}
          while CDoom.h_get_packet
            CDoom.gotinfo[CDoom.netbuffer.value.player & 0x7f] = 1
          end
        {% end %}

        i = 1
        while i < CDoom.doomcom.value.numnodes
          break if gotinfo[i] == 0
          i += 1
        end

        break unless i < CDoom.doomcom.value.numnodes
      end
    end
  end

  #
  # d_check_net_game
  # Works out player numbers among the net participants
  #
  def self.d_check_net_game
    CDoom::MAXNETNODES.times do |i|
      CDoom.nodeingame[i] = 0
      CDoom.nettics[i] = 0
      CDoom.remoteresend[i] = 0 # set when local needs tics
      CDoom.resendto[i] = 0     # which tic to start sending
    end

    # i_init_network sets doomcom and netgame
    CDoom.i_init_network
    CDoom.i_error("Error: Doomcom buffer invalid!") if CDoom.doomcom.value.id != CDoom::DOOMCOM_ID

    CDoom.netbuffer = (CDoom.doomcom + offsetof(CDoom::Doomcom, @data)).as(CDoom::Doomdata*)
    CDoom.consoleplayer = CDoom.doomcom.value.consoleplayer
    CDoom.displayplayer = CDoom.consoleplayer
    CDoom.d_arbitrate_net_start if CDoom.netgame != 0

    CDoom.doom_print.call("startskill ".to_unsafe)
    CDoom.doom_print.call(CDoom.doom_itoa(CDoom.startskill, 10))
    CDoom.doom_print.call("  deathmatch: ".to_unsafe)
    CDoom.doom_print.call(CDoom.doom_itoa(CDoom.deathmatch, 10))
    CDoom.doom_print.call("  startmap: ".to_unsafe)
    CDoom.doom_print.call(CDoom.doom_itoa(CDoom.startmap, 10))
    CDoom.doom_print.call("  startepisode: ".to_unsafe)
    CDoom.doom_print.call(CDoom.doom_itoa(CDoom.startepisode, 10))
    CDoom.doom_print.call("\n".to_unsafe)

    # read values out of doomcom
    CDoom.ticdup = CDoom.doomcom.value.ticdup
    CDoom.maxsend = CDoom::BACKUPTICS // (2 * CDoom.ticdup) - 1
    CDoom.maxsend = 1 if CDoom.maxsend < 1

    CDoom.doomcom.value.numplayers.times { |i| CDoom.playeringame[i] = 1 }
    CDoom.doomcom.value.numnodes.times { |i| CDoom.nodeingame[i] = 1 }

    CDoom.doom_print.call("player ".to_unsafe)
    CDoom.doom_print.call(CDoom.doom_itoa(CDoom.consoleplayer + 1, 10))
    CDoom.doom_print.call(" of ".to_unsafe)
    CDoom.doom_print.call(CDoom.doom_itoa(CDoom.doomcom.value.numplayers, 10))
    CDoom.doom_print.call(" (".to_unsafe)
    CDoom.doom_print.call(CDoom.doom_itoa(CDoom.doomcom.value.numnodes, 10))
    CDoom.doom_print.call(" nodes)\n".to_unsafe)
  end

  #
  # d_quit_net_game
  # Called before quitting to leave a net game
  # without hanging the other players
  #
  def self.d_quit_net_game
    CDoom.doom_close.call(CDoom.debugfile) if !CDoom.debugfile.null?

    return if CDoom.netgame == 0 || CDoom.usergame == 0 || CDoom.consoleplayer == -1 || CDoom.demoplayback == 1

    # send a bunch of packets for security
    CDoom.netbuffer.value.player = CDoom.consoleplayer
    CDoom.netbuffer.value.numtics = 0
    4.times do |i|
      (CDoom.doomcom.value.numnodes - 1).times do |j|
        j += 1
        CDoom.h_send_packet(j, CDoom::NCMD_EXIT) if CDoom.nodeingame[j] != 0
        CDoom.i_wait_vbl(1)
      end
    end
  end

  @@oldentertics : Int32 = 0

  #
  # try_run_tics
  #
  def self.try_run_tics
    # get real tics
    entertic = CDoom.i_get_time // CDoom.ticdup
    realtics = entertic - @@oldentertics
    @@oldentertics = entertic

    # get available tics
    CDoom.net_update

    lowtic = Int32::MAX
    numplaying = 0
    CDoom.doomcom.value.numnodes.times do |i|
      if CDoom.nodeingame[i] != 0
        numplaying += 1
        lowtic = CDoom.nettics[i] if CDoom.nettics[i] < lowtic
      end
    end
    availabletics = lowtic - CDoom.gametic // CDoom.ticdup

    counts = availabletics
    # decide how many tics to run
    if realtics < availabletics - 1
      counts = realtics + 1
    elsif realtics < availabletics
      counts = realtics
    end

    counts = 1 if counts < 1

    CDoom.frameon += 1

    if !CDoom.debugfile.null?
      CDoom.doom_fprint(CDoom.debugfile, "=======real: ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(realtics, 10))
      CDoom.doom_fprint(CDoom.debugfile, "  avail: ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(availabletics, 10))
      CDoom.doom_fprint(CDoom.debugfile, "  game: ")
      CDoom.doom_fprint(CDoom.debugfile, CDoom.doom_itoa(counts, 10))
      CDoom.doom_fprint(CDoom.debugfile, "\n")
    end

    if CDoom.demoplayback == 0
      i = 0
      while i < CDoom::MAXPLAYERS
        break if CDoom.playeringame[i] != 0
        i += 1
      end
      if CDoom.consoleplayer == i
        # the key player does not adapt
      else
        if CDoom.nettics[0] <= CDoom.nettics[CDoom.nodeforplayer[i]]
          CDoom.gametime -= 1
        end
        CDoom.frameskip[CDoom.frameon & 3] = (CDoom.oldnettics > CDoom.nettics[CDoom.nodeforplayer[i]]).to_unsafe
        CDoom.oldnettics = CDoom.nettics[0]
        if CDoom.frameskip[0] != 0 && CDoom.frameskip[1] != 0 && CDoom.frameskip[2] != 0 && CDoom.frameskip[3] != 0
          CDoom.skiptics = 1
        end
      end
    end

    # wait for new tics if needed
    while lowtic < CDoom.gametic // CDoom.ticdup + counts
      CDoom.net_update
      lowtic = Int32::MAX

      CDoom.doomcom.value.numnodes.times do |i|
        lowtic = CDoom.nettics[i] if CDoom.nodeingame[i] != 0 && CDoom.nettics[i] < lowtic
      end

      CDoom.i_error("Error: try_run_tics: lowtic < CDoom.gametic") if lowtic < CDoom.gametic // CDoom.ticdup

      # don't stay in here forever -- give the menu a chance to work
      if CDoom.i_get_time // CDoom.ticdup - entertic >= 20
        CDoom.m_ticker
        return
      end
    end

    # run the count * ticdup dics
    while counts != 0
      CDoom.ticdup.times do |i|
        CDoom.i_error("Error: gametic>lowtic") if CDoom.gametic // CDoom.ticdup > lowtic
        CDoom.d_do_advance_demo if CDoom.advancedemo != 0
        CDoom.m_ticker
        CDoom.g_ticker
        CDoom.gametic += 1

        # modify command for duplicated tics
        if i != CDoom.ticdup - 1
          buf = (CDoom.gametic // CDoom.ticdup) % CDoom::BACKUPTICS
          CDoom::MAXPLAYERS.times do |j|
            cmd = CDoom.netcmds[j].to_unsafe + buf
            cmd.value.chatchar = 0
            cmd.value.buttons = 0 if cmd.value.buttons & CDoom::Buttoncode::BT_SPECIAL.value != 0
          end
        end
      end
      CDoom.net_update # check for new console commands

      counts -= 1
    end
  end

  #
  # f_start_finale
  #
  def self.f_start_finale
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.gamestate = CDoom::Gamestate::Finale
    CDoom.viewactive = 0
    CDoom.automapactive = 0

    # Okay - IWAD dependend stuff.
    # This has been changed severly, and
    #  some stuff might have changed in the process.
    case CDoom.gamemode
    # DOOM 1 - E1, E3 or E4, but each nine missions
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered, CDoom::GameMode::Retail
      CDoom.s_change_music(CDoom::Musicenum::MUS_victor, 1)

      case CDoom.gameepisode
      when 1
        CDoom.finaleflat = "FLOOR4_8"
        CDoom.finaletext = CDoom.e1text
      when 2
        CDoom.finaleflat = "SFLR6_1"
        CDoom.finaletext = CDoom.e2text
      when 3
        CDoom.finaleflat = "MFLR8_4"
        CDoom.finaletext = CDoom.e3text
      when 4
        CDoom.finaleflat = "MFLR8_3"
        CDoom.finaletext = CDoom.e4text
      else
        # Ouch.
      end
      # DOOM II and missions packs with E1, M34
    when CDoom::GameMode::Commercial
      CDoom.s_change_music(CDoom::Musicenum::MUS_read_m, 1)

      case CDoom.gamemap
      when 6
        CDoom.finaleflat = "SLIME16"
        CDoom.finaletext = CDoom.c1text
      when 11
        CDoom.finaleflat = "RROCK14"
        CDoom.finaletext = CDoom.c2text
      when 20
        CDoom.finaleflat = "RROCK07"
        CDoom.finaletext = CDoom.c3text
      when 30
        CDoom.finaleflat = "RROCK17"
        CDoom.finaletext = CDoom.c4text
      when 15
        CDoom.finaleflat = "RROCK13"
        CDoom.finaletext = CDoom.c5text
      when 31
        CDoom.finaleflat = "RROCK19"
        CDoom.finaletext = CDoom.c6text
      else
        # Ouch
      end

      # Indeterminate.
    else
      CDoom.s_change_music(CDoom::Musicenum::MUS_read_m, 1)
      CDoom.finaleflat = "F_SKY1"     # Not used anywhere else.
      CDoom.finaletext = CDoom.c1text # FIXME - other text, music?
    end

    CDoom.finalestage = 0
    CDoom.finalecount = 0
  end

  def self.f_responder(event : CDoom::Event*) : CDoom::DoomBool
    return CDoom.f_cast_responder(event) if CDoom.finalestage == 2

    return 0
  end

  #
  # f_ticker
  #
  def self.f_ticker
    # check for skipping
    if CDoom.gamemode == CDoom::GameMode::Commercial && CDoom.finalecount > 50
      # go on to the next level
      i = 0
      CDoom::MAXPLAYERS.times do |j|
        break if CDoom.players[i].cmd.buttons != 0
        i += 1
      end

      if i < CDoom::MAXPLAYERS
        if CDoom.gamemap == 30
          CDoom.f_start_cast
        else
          CDoom.gameaction = CDoom::Gameaction::Worlddone
        end
      end
    end

    # advance animation
    CDoom.finalecount += 1

    if CDoom.finalestage == 2
      CDoom.f_cast_ticker
      return
    end

    return if CDoom.gamemode == CDoom::GameMode::Commercial

    if CDoom.finalestage == 0 && CDoom.finalecount > CDoom.doom_strlen(CDoom.finaletext) * CDoom::TEXTSPEED + CDoom::TEXTWAIT
      CDoom.finalecount = 0
      CDoom.finalestage = 1
      CDoom.wipegamestate = CDoom::Gamestate::Needwipe # force a wipe
      if CDoom.gameepisode == 3
        CDoom.s_start_music(CDoom::Musicenum::MUS_bunny)
      end
    end
  end

  #
  # f_text_write
  #
  def self.f_text_write
    # erase the entire screen to a tiled background
    src = CDoom.w_cache_lump_name(CDoom.finaleflat, CDoom::PU_CACHE)
    dest = CDoom.screens[0]

    CDoom::SCREENHEIGHT.times do |y|
      (CDoom::SCREENWIDTH // 64).times do |x|
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), 64)
        dest += 64
      end
      if CDoom::SCREENWIDTH & 63 != 0
        CDoom.doom_memcpy(dest, src + ((y & 63) << 6), CDoom::SCREENWIDTH & 63)
        dest += CDoom::SCREENWIDTH & 63
      end
    end

    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)

    # draw some of the text onto the screen
    cx = 10
    cy = 10
    ch = CDoom.finaletext

    count = (CDoom.finalecount - 10) // CDoom::TEXTSPEED
    count = 0 if count < 0
    while count != 0
      c = ch.value
      ch += 1
      break if c == '\0'.ord
      if c == '\n'.ord
        cx = 10
        cy += 11
        next
      end

      c = CDoom.doom_toupper(c) - CDoom::HU_FONTSTART
      if c < 0 || c > CDoom::HU_FONTSIZE
        cx += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      break if cx + w > CDoom::SCREENWIDTH
      CDoom.v_draw_patch(cx, cy, 0, CDoom.hu_font[c])
      cx += w

      count -= 1
    end
  end

  #
  # Final DOOM 2 animation
  # Casting by id Software.
  #   in order of appearance
  #
  def self.f_start_cast
    return if CDoom.finalestage == 2

    CDoom.wipegamestate = CDoom::Gamestate::Needwipe # force a screen wipe
    CDoom.castnum = 0
    CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
    CDoom.casttics = CDoom.caststate.value.tics
    CDoom.castdeath = 0
    CDoom.finalestage = 2
    CDoom.castframes = 0
    CDoom.castonmelee = 0
    CDoom.castattacking = 0
    CDoom.s_change_music(CDoom::Musicenum::MUS_evil, 1)
  end

  #
  # f_cast_ticker
  #
  def self.f_cast_ticker
    CDoom.casttics -= 1
    return if CDoom.casttics > 0 # not time to change state yet

    if CDoom.caststate.value.tics == -1 || CDoom.caststate.value.nextstate == CDoom::Statenum::S_NULL
      # switch from deathstate to next monster
      CDoom.castnum += 1
      CDoom.castdeath = 0
      CDoom.castnum = 0 if CDoom.castorder[CDoom.castnum].name.null?
      if CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seesound != 0
        CDoom.s_start_sound(Pointer(Void).null, CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seesound)
      end
      CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
      CDoom.castframes = 0
    else
      # just advance to next state in amnimation
      if CDoom.caststate == CDoom.states.to_unsafe + CDoom::Statenum::S_PLAY_ATK1.value
        # Yes, it is a gross hack!
        CDoom.castattacking = 0
        CDoom.castframes = 0
        CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
        CDoom.casttics = CDoom.caststate.value.tics
        CDoom.casttics = 15 if CDoom.casttics == -1
        return
      end
      st = CDoom.caststate.value.nextstate
      CDoom.caststate = CDoom.states.to_unsafe + st.value
      CDoom.castframes += 1

      sfx = 0
      # sound hacks....
      case st
      when CDoom::Statenum::S_PLAY_ATK1
        sfx = CDoom::Sfxenum::SFX_dshtgn
      when CDoom::Statenum::S_POSS_ATK2
        sfx = CDoom::Sfxenum::SFX_pistol
      when CDoom::Statenum::S_SPOS_ATK2
        sfx = CDoom::Sfxenum::SFX_shotgn
      when CDoom::Statenum::S_VILE_ATK2
        sfx = CDoom::Sfxenum::SFX_vilatk
      when CDoom::Statenum::S_SKEL_FIST2
        sfx = CDoom::Sfxenum::SFX_skeswg
      when CDoom::Statenum::S_SKEL_FIST4
        sfx = CDoom::Sfxenum::SFX_skepch
      when CDoom::Statenum::S_SKEL_MISS2
        sfx = CDoom::Sfxenum::SFX_skeatk
      when CDoom::Statenum::S_FATT_ATK8, CDoom::Statenum::S_FATT_ATK5, CDoom::Statenum::S_FATT_ATK2
        sfx = CDoom::Sfxenum::SFX_firsht
      when CDoom::Statenum::S_CPOS_ATK2, CDoom::Statenum::S_CPOS_ATK3, CDoom::Statenum::S_CPOS_ATK4
        sfx = CDoom::Sfxenum::SFX_shotgn
      when CDoom::Statenum::S_TROO_ATK3
        sfx = CDoom::Sfxenum::SFX_claw
      when CDoom::Statenum::S_SARG_ATK2
        sfx = CDoom::Sfxenum::SFX_sgtatk
      when CDoom::Statenum::S_BOSS_ATK2, CDoom::Statenum::S_BOS2_ATK2, CDoom::Statenum::S_HEAD_ATK2
        sfx = CDoom::Sfxenum::SFX_firsht
      when CDoom::Statenum::S_SKULL_ATK2
        sfx = CDoom::Sfxenum::SFX_sklatk
      when CDoom::Statenum::S_SPID_ATK2, CDoom::Statenum::S_SPID_ATK3
        sfx = CDoom::Sfxenum::SFX_shotgn
      when CDoom::Statenum::S_BSPI_ATK2
        sfx = CDoom::Sfxenum::SFX_plasma
      when CDoom::Statenum::S_CYBER_ATK2, CDoom::Statenum::S_CYBER_ATK4, CDoom::Statenum::S_CYBER_ATK6
        sfx = CDoom::Sfxenum::SFX_rlaunc
      when CDoom::Statenum::S_PAIN_ATK3
        sfx = CDoom::Sfxenum::SFX_sklatk
      end

      CDoom.s_start_sound(Pointer(Void).null, sfx) if sfx != 0
    end

    if CDoom.castframes == 12
      # go into attack frame
      CDoom.castattacking = 1
      if CDoom.castonmelee != 0
        CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].meleestate
      else
        CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].missilestate
      end
      CDoom.castonmelee ^= 1
      if CDoom.caststate == CDoom.states.to_unsafe + CDoom::Statenum::S_NULL.value
        if CDoom.castonmelee != 0
          CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].meleestate
        else
          CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].missilestate
        end
      end
    end

    if CDoom.castattacking != 0
      if CDoom.castframes == 24 ||
         CDoom.caststate == CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
        CDoom.castattacking = 0
        CDoom.castframes = 0
        CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].seestate
      end
    end

    CDoom.casttics = CDoom.caststate.value.tics
    CDoom.casttics = 15 if CDoom.casttics == -1
  end

  def self.f_cast_responder(ev : CDoom::Event*) : CDoom::DoomBool
    return 0 if ev.value.type != CDoom::Evtype::Keydown

    return 1 if CDoom.castdeath != 0 # already in dying frames

    # go into death frame
    CDoom.castdeath = 1
    CDoom.caststate = CDoom.states.to_unsafe + CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].deathstate
    CDoom.casttics = CDoom.caststate.value.tics
    CDoom.castframes = 0
    CDoom.castattacking = 0
    if CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].deathsound != 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom.mobjinfo[CDoom.castorder[CDoom.castnum].type.value].deathsound)
    end

    return 1
  end

  def self.f_cast_print(text : UInt8*)
    # find width
    ch = text
    width = 0

    while ch != 0
      c = ch.value
      ch += 1
      break if c == '\0'.ord
      c = CDoom.doom_toupper(c) - CDoom::HU_FONTSTART
      if c < 0 || c > CDoom::HU_FONTSIZE
        width += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      width += w
    end

    # draw it
    cx = 160 - width // 2
    ch = text
    while ch != 0
      c = ch.value
      ch += 1
      break if c == '\0'.ord
      c = CDoom.doom_toupper(c) - CDoom::HU_FONTSTART
      if c < 0 || c > CDoom::HU_FONTSIZE
        cx += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      CDoom.v_draw_patch(cx, 180, 0, CDoom.hu_font[c])
      cx += w
    end
  end

  #
  # f_cast_drawer
  #
  def self.f_cast_drawer
    # erase the entire screen to a background
    CDoom.v_draw_patch(0, 0, 0, CDoom.w_cache_lump_name("BOSSBACK", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.f_cast_print(CDoom.castorder[CDoom.castnum].name)

    # draw the current frame in the middle of the screen
    sprdef = CDoom.sprites + CDoom.caststate.value.sprite.value
    sprframe = sprdef.value.spriteframes + (CDoom.caststate.value.frame & CDoom::FF_FRAMEMASK)
    lump = sprframe.value.lump[0]
    flip = sprframe.value.flip[0]

    patch = CDoom.w_cache_lump_num(lump + CDoom.firstspritelump, CDoom::PU_CACHE).as(CDoom::Patch*)
    if flip != 0
      CDoom.v_draw_patch_flipped(160, 170, 0, patch)
    else
      CDoom.v_draw_patch(160, 170, 0, patch)
    end
  end

  #
  # f_draw_patch_col
  #
  def self.f_draw_patch_col(x : Int32, patch : CDoom::Patch*, col : Int32)
    column = (patch.as(UInt8*) + (patch.value.columnofs.to_unsafe + col).value.to_i32!).as(CDoom::Column*)
    desttop = CDoom.screens[0] + x

    # step through the posts in a column
    while column.value.topdelta != 0xff
      source = column.as(UInt8*) + 3
      dest = desttop + column.value.topdelta * CDoom::SCREENWIDTH
      count = column.value.length

      while count != 0
        dest.value = source.value
        source += 1
        dest += CDoom::SCREENWIDTH
        count -= 1
      end
      column = (column.as(UInt8*) + column.value.length + 4).as(CDoom::Column*)
    end
  end

  @@laststage = 0

  #
  # f_bunny_scroll
  #
  def self.f_bunny_scroll
    p1 = CDoom.w_cache_lump_name("PFUB2", CDoom::PU_LEVEL).as(CDoom::Patch*)
    p2 = CDoom.w_cache_lump_name("PFUB1", CDoom::PU_LEVEL).as(CDoom::Patch*)

    CDoom.v_mark_rect(0, 0, CDoom::SCREENWIDTH, CDoom::SCREENHEIGHT)

    scrolled = 320 - (CDoom.finalecount - 230) // 2
    scrolled = 320 if scrolled > 320
    scrolled = 0 if scrolled < 0

    CDoom::SCREENWIDTH.times do |x|
      if x + scrolled < 320
        CDoom.f_draw_patch_col(x, p1, x + scrolled)
      else
        CDoom.f_draw_patch_col(x, p2, x + scrolled - 320)
      end
    end

    return if CDoom.finalecount < 1130
    if CDoom.finalecount < 1180
      CDoom.v_draw_patch((CDoom::SCREENWIDTH - 13 * 8) // 2,
        (CDoom::SCREENHEIGHT - 8 * 8) // 2, 0, CDoom.w_cache_lump_name("END0", CDoom::PU_CACHE).as(CDoom::Patch*))
      @@laststage = 0
      return
    end

    stage = (CDoom.finalecount - 1180) // 5
    stage = 6 if stage > 6
    if stage > @@laststage
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol)
      @@laststage = stage
    end

    name = uninitialized StaticArray(UInt8, 10)

    CDoom.doom_strcpy(name.to_unsafe, "END")
    CDoom.doom_concat(name.to_unsafe, CDoom.doom_itoa(stage, 10))
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - 13 * 8) // 2, (CDoom::SCREENHEIGHT - 8 * 8) // 2, 0, CDoom.w_cache_lump_name(name.to_unsafe, CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.f_drawer
    if CDoom.finalestage == 2
      CDoom.f_cast_drawer
      return
    end

    if CDoom.finalestage == 0
      CDoom.f_text_write
    else
      case CDoom.gameepisode
      when 1
        if CDoom.gamemode == CDoom::GameMode::Retail
          CDoom.v_draw_patch(0, 0, 0,
            CDoom.w_cache_lump_name("CREDIT", CDoom::PU_CACHE).as(CDoom::Patch*))
        else
          CDoom.v_draw_patch(0, 0, 0,
            CDoom.w_cache_lump_name("HELP2", CDoom::PU_CACHE).as(CDoom::Patch*))
        end
      when 2
        CDoom.v_draw_patch(0, 0, 0,
          CDoom.w_cache_lump_name("VICTORY2", CDoom::PU_CACHE).as(CDoom::Patch*))
      when 3
        CDoom.f_bunny_scroll
      when 4
        CDoom.v_draw_patch(0, 0, 0,
          CDoom.w_cache_lump_name("ENDPIC", CDoom::PU_CACHE).as(CDoom::Patch*))
      end
    end
  end

  def self.wipe_shitty_col_major_x_form(array : Int16*, width : Int32, height : Int32)
    dest = CDoom.z_malloc(width * height * sizeof(Int16), CDoom::PU_STATIC, Pointer(Void).null).as(Int16*)

    height.times do |y|
      width.times do |x|
        dest[x * height + y] = array[y * width + x]
      end
    end

    CDoom.doom_memcpy(array, dest, width * height * 2)

    CDoom.z_free(dest)
  end

  def self.wipe_init_color_x_form(width : Int32, height : Int32, ticks : Int32) : Int32
    CDoom.doom_memcpy(CDoom.wipe_scr, CDoom.wipe_scr_start, width * height)
    return 0
  end

  def self.wipe_do_color_x_form(width : Int32, height : Int32, ticks : Int32) : Int32
    changes = 0
    w = CDoom.wipe_scr
    e = CDoom.wipe_scr_end
    newval = 0

    while w != CDoom.wipe_scr + width * height
      if w.value != e.value
        if w.value > e.value
          newval = w.value - ticks
          if newval < e.value
            w.value = e.value
          else
            w.value = newval
          end
          changed = 1
        elsif w.value < e.value
          newval = w.value + ticks
          if newval > e.value
            w.value = e.value
          else
            w.value = newval
          end
          changed = 1
        end
      end
      w += 1
      e += 1
    end

    return (changed == 0).to_unsafe
  end

  def self.wipe_exit_color_x_form(width : Int32, height : Int32, ticks : Int32) : Int32
    return 0
  end

  def self.wipe_init_melt(width : Int32, height : Int32, ticks : Int32) : Int32
    # copy start screen to main screen
    CDoom.doom_memcpy(CDoom.wipe_scr, CDoom.wipe_scr_start, width * height)

    # makes this wipe faster (in theory)
    # to have stuff in column-major format
    CDoom.wipe_shitty_col_major_x_form(CDoom.wipe_scr_start.as(Int16*), width // 2, height)
    CDoom.wipe_shitty_col_major_x_form(CDoom.wipe_scr_end.as(Int16*), width // 2, height)

    # setup initial column positions
    # (y<0 => not ready to scroll yet)
    CDoom.y = CDoom.z_malloc(width * sizeof(Int32), CDoom::PU_STATIC, Pointer(Void).null).as(Int32*)
    CDoom.y[0] = -(CDoom.m_random % 16)
    i = 1
    while i < width
      r = (CDoom.m_random % 3) - 1
      CDoom.y[i] = CDoom.y[i - 1] + r
      if (CDoom.y[i] > 0)
        CDoom.y[i] = 0
      elsif CDoom.y[i] == -16
        CDoom.y[i] = -15
      end
      i += 1
    end

    return 0
  end

  def self.wipe_do_melt(width : Int32, height : Int32, ticks : Int32) : Int32
    done = 1

    width //= 2

    while ticks != 0
      width.times do |i|
        if CDoom.y[i] < 0
          CDoom.y[i] += 1
          done = 0
        elsif CDoom.y[i] < height
          dy = (CDoom.y[i] < 16) ? CDoom.y[i] + 1 : 8
          dy = height - CDoom.y[i] if CDoom.y[i] + dy >= height
          s = CDoom.wipe_scr_end.as(Int16*) + (i * height + CDoom.y[i])
          d = CDoom.wipe_scr.as(Int16*) + (CDoom.y[i] * width + i)
          idx = 0
          j = dy
          while j != 0
            d[idx] = s.value
            s += 1
            idx += width
            j -= 1
          end
          CDoom.y[i] += dy
          s = CDoom.wipe_scr_start.as(Int16*) + (i * height)
          d = CDoom.wipe_scr.as(Int16*) + (CDoom.y[i] * width + i)
          idx = 0
          j = height - CDoom.y[i]
          while j != 0
            d[idx] = s.value
            s += 1
            idx += width
            j -= 1
          end
          done = 0
        end
      end

      ticks -= 1
    end

    return done
  end

  def self.wipe_exit_melt(width : Int32, height : Int32, ticks : Int32) : Int32
    CDoom.z_free(CDoom.y)
    return 0
  end

  def self.wipe_start_screen(x : Int32, y : Int32, width : Int32, height : Int32) : Int32
    CDoom.wipe_scr_start = CDoom.screens[2]
    CDoom.i_read_screen(CDoom.wipe_scr_start)
    return 0
  end

  def self.wipe_end_screen(x : Int32, y : Int32, width : Int32, height : Int32) : Int32
    CDoom.wipe_scr_end = CDoom.screens[3]
    CDoom.i_read_screen(CDoom.wipe_scr_end)
    CDoom.v_draw_block(x, y, 0, width, height, CDoom.wipe_scr_start) # restore start scr
    return 0
  end

  @@wipes : Array(Proc(Int32, Int32, Int32, Int32)) = [
    ->CDoom.wipe_init_color_x_form(Int32, Int32, Int32), ->CDoom.wipe_do_color_x_form(Int32, Int32, Int32),
    ->CDoom.wipe_exit_color_x_form(Int32, Int32, Int32), ->CDoom.wipe_init_melt(Int32, Int32, Int32),
    ->CDoom.wipe_do_melt(Int32, Int32, Int32), ->CDoom.wipe_exit_melt(Int32, Int32, Int32),
  ]

  def self.wipe_screen_wipe(wipeno : Int32, x : Int32, y : Int32, width : Int32, height : Int32, ticks : Int32) : Int32
    # initial stuff
    if CDoom.go == 0
      CDoom.go = 1
      CDoom.wipe_scr = CDoom.screens[0]
      @@wipes[wipeno * 3].call(width, height, ticks)
    end

    # do a piece of wipe-in
    CDoom.v_mark_rect(0, 0, width, height)
    rc = @@wipes[wipeno * 3 + 1].call(width, height, ticks)

    # final stuff
    if rc != 0
      CDoom.go = 0
      @@wipes[wipeno * 3 + 2].call(width, height, ticks)
    end

    return (CDoom.go == 0).to_unsafe
  end

  #
  # g_build_ticcmd
  # Builds a ticcmd from all of the available inputs
  # or reads it from the demo buffer.
  # If recording a demo, write it out
  #
  def self.g_build_ticcmd(cmd : CDoom::Ticcmd*)
    base = CDoom.i_base_ticcmd # empty, or external driver
    CDoom.doom_memcpy(cmd, base, sizeof(typeof(cmd.value)))

    cmd.value.consistancy =
      CDoom.consistancy[CDoom.consoleplayer][CDoom.maketic % CDoom::BACKUPTICS]

    strafe = (CDoom.gamekeydown[CDoom.key_strafe] != 0 || CDoom.mousebuttons[CDoom.mousebstrafe] != 0 ||
              CDoom.joybuttons[CDoom.joybstrafe] != 0).to_unsafe

    running = CDoom.always_run != 0 ? (CDoom.gamekeydown[CDoom.key_speed] != 0 ? false : true) : (CDoom.gamekeydown[CDoom.key_speed] != 0 ? true : false)
    speed = (running || CDoom.joybuttons[CDoom.joybspeed] != 0).to_unsafe

    forward = 0
    side = 0

    # use two stage accelerative turning
    # on the keyboard and joystick
    if CDoom.joyxmove < 0 ||
       CDoom.joyxmove > 0 ||
       CDoom.gamekeydown[CDoom.key_right] != 0 ||
       CDoom.gamekeydown[CDoom.key_left] != 0
      CDoom.turnheld += CDoom.ticdup
    else
      CDoom.turnheld = 0
    end

    tspeed = speed
    tspeed = 2 if CDoom.turnheld < CDoom::SLOWTURNTICS # slow turn

    # let movement keys cancel each other out
    if strafe != 0
      side += CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_right] != 0
      side -= CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_left] != 0
      side += CDoom.sidemove[speed] if CDoom.joyxmove > 0
      side -= CDoom.sidemove[speed] if CDoom.joyxmove < 0
    else
      cmd.value.angleturn = cmd.value.angleturn - CDoom.angleturn[tspeed] if CDoom.gamekeydown[CDoom.key_right] != 0
      cmd.value.angleturn = cmd.value.angleturn + CDoom.angleturn[tspeed] if CDoom.gamekeydown[CDoom.key_left] != 0
      cmd.value.angleturn = cmd.value.angleturn - CDoom.angleturn[tspeed] if CDoom.joyxmove > 0
      cmd.value.angleturn = cmd.value.angleturn + CDoom.angleturn[tspeed] if CDoom.joyxmove < 0
    end

    forward += CDoom.forwardmove[speed] if CDoom.gamekeydown[CDoom.key_up] != 0
    forward -= CDoom.forwardmove[speed] if CDoom.gamekeydown[CDoom.key_down] != 0
    forward += CDoom.forwardmove[speed] if CDoom.joyymove < 0
    forward -= CDoom.forwardmove[speed] if CDoom.joyymove > 0

    side += CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_straferight] != 0
    side -= CDoom.sidemove[speed] if CDoom.gamekeydown[CDoom.key_strafeleft] != 0

    # buttons
    cmd.value.chatchar = CDoom.hu_dequeue_chat_char

    if CDoom.gamekeydown[CDoom.key_fire] != 0 || CDoom.mousebuttons[CDoom.mousebfire] != 0 ||
       CDoom.joybuttons[CDoom.joybfire] != 0
      cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_ATTACK.value
    end

    if CDoom.gamekeydown[CDoom.key_use] != 0 || CDoom.joybuttons[CDoom.joybuse] != 0
      cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_USE.value
      # clear double clicks if hit use button
      CDoom.dclicks = 0
    end

    # chainsaw overrides
    (CDoom::Weapontype::NUMWEAPONS.value - 1).times do |i|
      if CDoom.gamekeydown['1'.ord + i] != 0
        cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_CHANGE.value
        cmd.value.buttons = cmd.value.buttons | i << CDoom::Buttoncode::BT_WEAPONSHIFT.value
        break
      end
    end

    # mouse
    forward += CDoom.forwardmove[speed] if CDoom.mousebuttons[CDoom.mousebforward] != 0

    # forward double click
    if CDoom.mousebuttons[CDoom.mousebforward] != CDoom.dclickstate && CDoom.dclicktime > 1
      CDoom.dclickstate = CDoom.mousebuttons[CDoom.mousebforward]
      CDoom.dclicks += 1 if CDoom.dclickstate != 0
      if CDoom.dclicks == 2
        cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_USE.value
        CDoom.dclicks = 0
      else
        CDoom.dclicktime = 0
      end
    else
      CDoom.dclicktime += CDoom.ticdup
      if CDoom.dclicktime > 20
        CDoom.dclicks = 0
        CDoom.dclickstate = 0
      end
    end

    # strafe double click
    bstrafe =
      (CDoom.mousebuttons[CDoom.mousebstrafe] != 0 ||
        CDoom.joybuttons[CDoom.joybstrafe] != 0).to_unsafe
    if bstrafe != CDoom.dclickstate2 && CDoom.dclicktime2 > 1
      CDoom.dclickstate2 = bstrafe
      CDoom.dclicks2 += 1 if CDoom.dclickstate2 != 0
      if CDoom.dclicks2 == 2
        cmd.value.buttons = cmd.value.buttons | CDoom::Buttoncode::BT_USE.value
        CDoom.dclicks2 = 0
      else
        CDoom.dclicktime2 = 0
      end
    else
      CDoom.dclicktime2 += CDoom.ticdup
      if CDoom.dclicktime2 > 20
        CDoom.dclicks2 = 0
        CDoom.dclickstate2 = 0
      end
    end

    forward += @@mousey if CDoom.mousemove != 0
    if strafe != 0
      side += @@mousex * 2
    else
      cmd.value.angleturn = cmd.value.angleturn - @@mousex * 0x8
    end

    @@mousex = 0
    @@mousey = 0

    if forward > CDoom::MAXPLMOVE
      forward = CDoom::MAXPLMOVE
    elsif forward < -CDoom::MAXPLMOVE
      forward = -CDoom::MAXPLMOVE
    end
    if side > CDoom::MAXPLMOVE
      side = CDoom::MAXPLMOVE
    elsif side < -CDoom::MAXPLMOVE
      side = -CDoom::MAXPLMOVE
    end

    cmd.value.forwardmove = cmd.value.forwardmove + forward
    cmd.value.sidemove = cmd.value.sidemove + side

    # special buttons
    if CDoom.sendpause != 0
      CDoom.sendpause = 0
      cmd.value.buttons = CDoom::Buttoncode::BT_SPECIAL.value | CDoom::Buttoncode::BTS_PAUSE.value
    end

    if CDoom.sendsave != 0
      CDoom.sendsave = 0
      cmd.value.buttons = CDoom::Buttoncode::BT_SPECIAL.value | CDoom::Buttoncode::BTS_SAVEGAME.value | (CDoom.savegameslot << CDoom::Buttoncode::BTS_SAVESHIFT.value)
    end
  end

  #
  # g_do_load_level
  #
  def self.g_do_load_level
    # Set the sky map.
    # First thing, we have a dummy sky texture name,
    #  a flat. The data is in the WAD only because
    #  we look for an actual index, instead of simply
    #  setting one.
    CDoom.skyflatnum = CDoom.r_flat_num_for_name(CDoom::SKYFLATNAME)

    # DOOM determines the sky texture to be used
    # depending on the current episode, and the game version.
    if CDoom.gamemode == CDoom::GameMode::Commercial ||
       CDoom.gamemission == CDoom::GameMission::PackTnt ||
       CDoom.gamemission == CDoom::GameMission::PackPlut
      CDoom.skytexture = CDoom.r_texture_num_for_name("SKY3")
      if CDoom.gamemap < 12
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY1")
      elsif CDoom.gamemap < 21
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY2")
      end
    end

    CDoom.levelstarttic = CDoom.gametic # for time calculation

    CDoom.wipegamestate = CDoom::Gamestate::Needwipe if CDoom.wipegamestate == CDoom::Gamestate::Level # force a wipe

    CDoom.gamestate = CDoom::Gamestate::Level

    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0 && CDoom.players[i].playerstate == CDoom::Playerstate::PST_DEAD
        (CDoom.players.to_unsafe + i).value.playerstate = CDoom::Playerstate::PST_REBORN
      end
      CDoom.doom_memset(CDoom.players[i].frags, 0, sizeof(typeof(CDoom.players[i].frags)))
    end

    CDoom.p_setup_level(CDoom.gameepisode, CDoom.gamemap, 0, CDoom.gameskill)
    CDoom.displayplayer = CDoom.consoleplayer # view the guy you are playing
    CDoom.starttime = CDoom.i_get_time
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.z_check_heap

    # clear cmd building stuff
    CDoom.doom_memset(CDoom.gamekeydown, 0, sizeof(typeof(CDoom.gamekeydown)))
    CDoom.joyxmove = 0
    CDoom.joyymove = 0
    @@mousex = 0
    @@mousey = 0
    CDoom.sendpause = 0
    CDoom.sendsave = 0
    CDoom.paused = 0
    CDoom.doom_memset(CDoom.mousebuttons, 0, sizeof(typeof(CDoom.mousebuttons.value)) * 3)
    CDoom.doom_memset(CDoom.joybuttons, 0, sizeof(typeof(CDoom.joybuttons.value)) * 3)
  end

  def self.g_responder(ev : CDoom::Event*) : CDoom::DoomBool
    # allow spy mode changes even during the demo
    if CDoom.gamestate == CDoom::Gamestate::Level && ev.value.type == CDoom::Evtype::Keydown &&
       ev.value.data1 == CDoom::KEY_F12 && (CDoom.singledemo != 0 || CDoom.deathmatch == 0)
      # spy mode
      loop do
        CDoom.displayplayer += 1
        CDoom.displayplayer = 0 if CDoom.displayplayer == CDoom::MAXPLAYERS

        break unless CDoom.playeringame[CDoom.displayplayer] == 0 && CDoom.displayplayer != CDoom.consoleplayer
      end
      return 1
    end

    # any other key pops up menu if in demos
    if CDoom.gameaction == CDoom::Gameaction::Nothing && CDoom.singledemo == 0 &&
       (CDoom.demoplayback != 0 || CDoom.gamestate == CDoom::Gamestate::Demoscreen)
      if ev.value.type == CDoom::Evtype::Keydown ||
         (ev.value.type == CDoom::Evtype::Mouse && ev.value.data1 != 0) ||
         (ev.value.type == CDoom::Evtype::Joystick && ev.value.data1 != 0)
        CDoom.m_start_control_panel
        return 1
      end
      return 0
    end

    if CDoom.gamestate == CDoom::Gamestate::Level
      {% if false %}
        if CDoom.devparm != 0 && ev.value.type == CDoom::Evtype::Keydown && ev.value.data1 == ';'.ord
          CDoom.g_deathmatch_spawn_player(0)
          return 1
        end
      {% end %}
      return 1 if CDoom.hu_responder(ev) != 0 # chat ate the event
      return 1 if CDoom.st_responder(ev) != 0 # status window ate it
      return 1 if CDoom.am_responder(ev) != 0 # automap ate it
    end

    if CDoom.gamestate == CDoom::Gamestate::Finale
      return 1 if CDoom.f_responder(ev) != 0 # finale ate the event
    end

    case ev.value.type
    when CDoom::Evtype::Keydown
      if ev.value.data1 == CDoom::KEY_PAUSE
        CDoom.sendpause = 1
        return 1
      end
      CDoom.gamekeydown[ev.value.data1] = 1 if ev.value.data1 < CDoom::NUMKEYS
      return 1 # eat key down events
    when CDoom::Evtype::Keyup
      CDoom.gamekeydown[ev.value.data1] = 0 if ev.value.data1 < CDoom::NUMKEYS
      return 0 # always let key up events filter down
    when CDoom::Evtype::Mouse
      CDoom.mousebuttons[0] = ev.value.data1 & 1
      CDoom.mousebuttons[1] = ev.value.data1 & 2
      CDoom.mousebuttons[2] = ev.value.data1 & 4
      @@mousex = ev.value.data2 * (CDoom.mouse_sensitivity + 5) // 10
      @@mousey = ev.value.data3 * (CDoom.mouse_sensitivity + 5) // 10
      return 1 # eat events
    when CDoom::Evtype::Joystick
      CDoom.joybuttons[0] = ev.value.data1 & 1
      CDoom.joybuttons[1] = ev.value.data1 & 2
      CDoom.joybuttons[2] = ev.value.data1 & 4
      CDoom.joybuttons[3] = ev.value.data1 & 8
      CDoom.joyxmove = ev.value.data2
      CDoom.joyymove = ev.value.data3
      return 1 # eat events
    end

    return 0
  end

  @@turbomessage = uninitialized StaticArray(UInt8, 80)

  #
  # g_ticker
  # Make ticcmds for the players.
  def self.g_ticker
    # do player reborns if needed
    CDoom::MAXPLAYERS.times do |i|
      CDoom.g_do_reborn(i) if CDoom.playeringame[i] != 0 && CDoom.players[i].playerstate == CDoom::Playerstate::PST_REBORN
    end

    # do things to change the game state
    while CDoom.gameaction != CDoom::Gameaction::Nothing
      case CDoom.gameaction
      when CDoom::Gameaction::Loadlevel
        CDoom.g_do_load_level
      when CDoom::Gameaction::Newgame
        CDoom.g_do_new_game
      when CDoom::Gameaction::Loadgame
        CDoom.g_do_load_game
      when CDoom::Gameaction::Savegame
        CDoom.g_do_save_game
      when CDoom::Gameaction::Playdemo
        CDoom.g_do_play_demo
      when CDoom::Gameaction::Completed
        CDoom.g_do_completed
      when CDoom::Gameaction::Victory
        CDoom.f_start_finale
      when CDoom::Gameaction::Worlddone
        CDoom.g_do_world_done
      when CDoom::Gameaction::Screenshot
        CDoom.m_screenshot
        CDoom.gameaction = CDoom::Gameaction::Nothing
      when CDoom::Gameaction::Nothing
      end
    end

    # get commands, check consistancy,
    # and build new consistancy check
    buf = (CDoom.gametic // CDoom.ticdup) % CDoom::BACKUPTICS

    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i] != 0
        cmd = ((CDoom.players.to_unsafe + i).as(UInt8*) + offsetof(CDoom::Player, @cmd)).as(CDoom::Ticcmd*) # Gotta be a better way to do this

        CDoom.doom_memcpy(cmd, (CDoom.netcmds.to_unsafe + i).value.to_unsafe + buf, sizeof(CDoom::Ticcmd))

        CDoom.g_read_demo_ticcmd(cmd) if CDoom.demoplayback != 0
        CDoom.g_write_demo_ticcmd(cmd) if CDoom.demorecording != 0

        # check for turbo cheats
        if cmd.value.forwardmove > CDoom::TURBOTHRESHOLD &&
           (CDoom.gametic & 31) == 0 && (CDoom.gametic >> 5) & 3 == i
          CDoom.doom_strcpy(@@turbomessage, CDoom.player_names[i])
          CDoom.doom_concat(@@turbomessage, " is turbo!")
          (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = @@turbomessage
        end

        if CDoom.netgame != 0 && CDoom.netdemo == 0 && (CDoom.gametic % CDoom.ticdup) == 0
          if CDoom.gametic > CDoom::BACKUPTICS &&
             CDoom.consistancy[i][buf] != cmd.value.consistancy
            CDoom.doom_strcpy(CDoom.error_buf, "Error: consistency failure (")
            CDoom.doom_concat(CDoom.error_buf, CDoom.doom_itoa(cmd.value.consistancy, 10))
            CDoom.doom_concat(CDoom.error_buf, " should be ")
            CDoom.doom_concat(CDoom.error_buf, CDoom.doom_itoa(CDoom.consistancy[i][buf], 10))
            CDoom.doom_concat(CDoom.error_buf, ")")
            CDoom.i_error(CDoom.error_buf)
          end
          if !CDoom.players[i].mo.null?
            CDoom.consistancy[i][buf] = CDoom.players[i].mo.value.x.to_i16!
          else
            CDoom.consistancy[i][buf] = CDoom.rndindex.to_i16!
          end
        end
      end
    end

    # check for special buttons
    CDoom::MAXPLAYERS.times do |i|
      if CDoom.playeringame[i]
        !+0
        if CDoom.players[i].cmd.buttons & CDoom::Buttoncode::BT_SPECIAL.value != 0
          case CDoom::Buttoncode.new(CDoom.players[i].cmd.buttons & CDoom::Buttoncode::BT_SPECIALMASK.value)
          when CDoom::Buttoncode::BTS_PAUSE
            CDoom.paused ^= 1
            if CDoom.paused != 0
              CDoom.s_pause_sound
            else
              CDoom.s_resume_sound
            end
          when CDoom::Buttoncode::BTS_SAVEGAME
            CDoom.doom_strcpy(CDoom.savedescription, "NET GAME") if CDoom.savedescription[0] == '\0'.ord
            CDoom.savegameslot =
              (CDoom.players[i].cmd.buttons & CDoom::Buttoncode::BTS_SAVEMASK.value) >> CDoom::Buttoncode::BTS_SAVESHIFT.value
            CDoom.gameaction = CDoom::Gameaction::Savegame
          end
        end
      end
    end

    # do main actions
    case CDoom.gamestate
    when CDoom::Gamestate::Level
      CDoom.p_ticker
      CDoom.st_ticker
      CDoom.am_ticker
      CDoom.hu_ticker
    when CDoom::Gamestate::Intermission
      CDoom.wi_ticker
    when CDoom::Gamestate::Finale
      CDoom.f_ticker
    when CDoom::Gamestate::Demoscreen
      CDoom.d_page_ticker
    end
  end

  #
  # g_init_player
  # Called at the start.
  # Called by the game initialization functions.
  #
  def self.g_init_player(player : Int32)
    # set up the saved info
    p = CDoom.players.to_unsafe + player

    # clear everything else to defaults
    CDoom.g_player_reborn(player)
  end

  #
  # g_player_finish_level
  # Can when a player completes a level.
  #
  def self.g_player_finish_level(player : Int32)
    p = CDoom.players.to_unsafe + player

    CDoom.doom_memset(p.value.powers.to_unsafe, 0, sizeof(typeof(p.value.powers)))
    CDoom.doom_memset(p.value.cards.to_unsafe, 0, sizeof(typeof(p.value.cards)))
    p.value.mo.value.flags = p.value.mo.value.flags & ~CDoom::Mobjflag::MF_SHADOW.value # cancel invisibility
    p.value.extralight = 0                                                              # cancel gun flashes
    p.value.fixedcolormap = 0                                                           # cancel ir gogles
    p.value.damagecount = 0                                                             # no palette changes
    p.value.bonuscount = 0
  end

  #
  # g_player_reborn
  # Called after a player dies
  # almost everything is cleared and initialized
  #
  def self.g_player_reborn(player : Int32)
    frags = uninitialized StaticArray(Int32, CDoom::MAXPLAYERS)

    CDoom.doom_memcpy(frags.to_unsafe, CDoom.players[player].frags.to_unsafe, sizeof(typeof(frags)))
    killcount = CDoom.players[player].killcount
    itemcount = CDoom.players[player].itemcount
    secretcount = CDoom.players[player].secretcount

    p = CDoom.players.to_unsafe + player
    CDoom.doom_memset(p, 0, sizeof(typeof(p.value)))

    CDoom.doom_memcpy(p.value.frags.to_unsafe, frags.to_unsafe, sizeof(typeof(CDoom.players[player].frags)))
    (CDoom.players.to_unsafe + player).value.killcount = killcount
    (CDoom.players.to_unsafe + player).value.itemcount = itemcount
    (CDoom.players.to_unsafe + player).value.secretcount = secretcount

    p.value.usedown = 0 # don't do anything immediately
    p.value.attackdown = 0
    p.value.playerstate = CDoom::Playerstate::PST_LIVE
    p.value.health = CDoom::MAXHEALTH
    p.value.readyweapon = CDoom::Weapontype::Pistol
    p.value.pendingweapon = CDoom::Weapontype::Pistol
    p.value.weaponowned[CDoom::Weapontype::Fist.value] = 1
    p.value.weaponowned[CDoom::Weapontype::Pistol.value] = 1
    p.value.ammo[CDoom::Ammotype::Clip.value] = 50

    CDoom::Ammotype::NUMAMMO.value.times do |i|
      p.value.maxammo[i] = CDoom.maxammo[i]
    end
  end

  def self.g_check_spot(playernum : Int32, mthing : CDoom::Mapthing*) : CDoom::DoomBool
    if CDoom.players[playernum].mo.null?
      # first spawn of level, before corpses
      playernum.times do |i|
        return 0 if (CDoom.players[i].mo.value.x == mthing.value.x << CDoom::FRACBITS &&
                    CDoom.players[i].mo.value.y == mthing.value.y << CDoom::FRACBITS)
      end
      return 1
    end

    x = mthing.value.x << CDoom::FRACBITS
    y = mthing.value.y << CDoom::FRACBITS

    return 0 if CDoom.p_check_position(CDoom.players[playernum].mo, x, y) == 0

    # flush an old corpse if needed
    if CDoom.bodyqueslot >= CDoom::BODYQUESIZE
      CDoom.p_remove_mobj(CDoom.bodyque[CDoom.bodyqueslot % CDoom::BODYQUESIZE])
    end
    CDoom.bodyque[CDoom.bodyqueslot % CDoom::BODYQUESIZE] = CDoom.players[playernum].mo
    CDoom.bodyqueslot += 1

    # spawn a teleport fog
    ss = CDoom.r_point_in_subsector(x, y)
    an = (CDoom::ANG45 * (mthing.value.angle // 45)) >> CDoom::ANGLETOFINESHIFT

    mo = CDoom.p_spawn_mobj(x + 20 * CDoom.finecosine[an], y + 20 * CDoom.finesine[an],
      ss.value.sector.value.floorheight, CDoom::Mobjtype::MT_TFOG)

    CDoom.s_start_sound(mo, CDoom::Sfxenum::SFX_telept) if CDoom.players[CDoom.consoleplayer].viewz != 1 # don't start sound on first frame

    return 1
  end

  def self.g_deathmatch_spawn_player(playernum : Int32)
    selections = (CDoom.deathmatch_p - CDoom.deathmatchstarts.to_unsafe).to_i32!
    if selections < 4
      CDoom.doom_strcpy(CDoom.error_buf, "Error: Only ")
      CDoom.doom_concat(CDoom.error_buf, CDoom.doom_itoa(selections, 10))
      CDoom.doom_concat(CDoom.error_buf, " deathmatch spots, 4 required")
      CDoom.i_error(CDoom.error_buf)
    end

    20.times do |j|
      i = CDoom.p_random % selections
      if CDoom.g_check_spot(playernum, CDoom.deathmatchstarts.to_unsafe + i) != 0
        (CDoom.deathmatchstarts.to_unsafe + i).value.type = playernum + 1
        CDoom.p_spawn_player(CDoom.deathmatchstarts.to_unsafe + i)
        return
      end
    end

    # no good spot, so the player will probably get stuck
    CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + playernum)
  end

  #
  # g_do_reborn
  #
  def self.g_do_reborn(playernum : Int32)
    if CDoom.netgame == 0
      # reload the level from scatch
      CDoom.gameaction = CDoom::Gameaction::Loadlevel
    else
      # respawn at the start

      # first dissasociate the corpse
      CDoom.players[playernum].mo.value.player = Pointer(CDoom::Player).null

      # spawn at random spot if in death match
      if CDoom.deathmatch != 0
        CDoom.g_deathmatch_spawn_player(playernum)
        return
      end

      if CDoom.g_check_spot(playernum, CDoom.playerstarts.to_unsafe + playernum) != 0
        CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + playernum)
        return
      end

      # try to spawn at one of the other players spots
      CDoom::MAXPLAYERS.times do |i|
        if CDoom.g_check_spot(playernum, CDoom.playerstarts.to_unsafe + i) != 0
          (CDoom.playerstarts.to_unsafe + i).value.type = playernum + 1 # fake as other player
          CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + i)        # restore
          return
        end
        # he's going to be inside something. Too bad.
      end
      CDoom.p_spawn_player(CDoom.playerstarts.to_unsafe + playernum)
    end
  end

  def self.g_screenshot
    CDoom.gameaction = CDoom::Gameaction::Screenshot
  end

  def self.g_exit_level
    CDoom.secretexit = 0
    CDoom.gameaction = CDoom::Gameaction::Completed
  end

  # Here's for the german edition. Literally 1984
  def self.g_secret_exit_level
    # IF NO WOLF3D LEVELS, NO SECRET EXIT!
    if CDoom.gamemode == CDoom::GameMode::Commercial &&
       CDoom.w_check_num_for_name("map31") < 0
      CDoom.secretexit = 0
    else
      CDoom.secretexit = 1
    end
    CDoom.gameaction = CDoom::Gameaction::Completed
  end

  def self.g_do_completed
    CDoom.gameaction = CDoom::Gameaction::Nothing

    CDoom::MAXPLAYERS.times do |i|
      CDoom.g_player_finish_level(i) if CDoom.playeringame[i] != 0 # take away cards and stuff
    end

    CDoom.am_stop if CDoom.automapactive != 0

    if CDoom.gamemode != CDoom::GameMode::Commercial
      case CDoom.gamemap
      when 8
        # victory
        CDoom.gameaction = CDoom::Gameaction::Victory
      when 9
        # exit secret level
        CDoom::MAXPLAYERS.times do |i|
          (CDoom.players.to_unsafe + i).value.didsecret = 1
        end
      end
    end

    CDoom.wminfo.didsecret = (CDoom.players.to_unsafe + CDoom.consoleplayer).value.didsecret
    CDoom.wminfo.epsd = CDoom.gameepisode - 1
    CDoom.wminfo.last = CDoom.gamemap - 1

    # wminfo.next is 0 biased, unlike gamemap
    if CDoom.gamemode == CDoom::GameMode::Commercial
      if CDoom.secretexit != 0
        case CDoom.gamemap
        when 15
          CDoom.wminfo.next = 30
        when 31
          CDoom.wminfo.next = 31
        end
      else
        case CDoom.gamemap
        when 31, 32
          CDoom.wminfo.next = 15
        else CDoom.wminfo.next = CDoom.gamemap
        end
      end
    else
      if CDoom.secretexit != 0
        CDoom.wminfo.next = 8 # go to secret level
      elsif CDoom.gamemap == 9
        # returning from secret level
        case CDoom.gameepisode
        when 1
          CDoom.wminfo.next = 3
        when 2
          CDoom.wminfo.next = 5
        when 3
          CDoom.wminfo.next = 6
        when 4
          CDoom.wminfo.next = 2
        end
      else
        CDoom.wminfo.next = CDoom.gamemap # go to next level
      end
    end

    CDoom.wminfo.maxkills = CDoom.totalkills
    CDoom.wminfo.maxitems = CDoom.totalitems
    CDoom.wminfo.maxsecret = CDoom.totalsecret
    CDoom.wminfo.maxfrags = 0
    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.wminfo.partime = 35 * CDoom.cpars[CDoom.gamemap - 1]
    else
      CDoom.wminfo.partime = 35 * CDoom.pars[CDoom.gameepisode][CDoom.gamemap]
    end
    CDoom.wminfo.pnum = CDoom.consoleplayer

    CDoom::MAXPLAYERS.times do |i|
      (CDoom.wminfo.plyr.to_unsafe + i).value.in = CDoom.playeringame[i]
      (CDoom.wminfo.plyr.to_unsafe + i).value.skills = CDoom.players[i].killcount
      (CDoom.wminfo.plyr.to_unsafe + i).value.sitems = CDoom.players[i].itemcount
      (CDoom.wminfo.plyr.to_unsafe + i).value.ssecret = CDoom.players[i].secretcount
      (CDoom.wminfo.plyr.to_unsafe + i).value.stime = CDoom.leveltime
      CDoom.doom_memcpy(CDoom.wminfo.plyr[i].frags, CDoom.players[i].frags,
        sizeof(typeof(CDoom.wminfo.plyr[i].frags)))
    end

    CDoom.gamestate = CDoom::Gamestate::Intermission
    CDoom.viewactive = 0
    CDoom.automapactive = 0

    if !CDoom.statcopy.null?
      CDoom.doom_memcpy(CDoom.statcopy, pointerof(CDoom.wminfo), sizeof(typeof(CDoom.wminfo)))
    end

    CDoom.wi_start(pointerof(CDoom.wminfo))
  end

  #
  # g_world_done
  #
  def self.g_world_done
    CDoom.gameaction = CDoom::Gameaction::Worlddone

    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.didsecret = 1 if CDoom.secretexit != 0

    if CDoom.gamemode == CDoom::GameMode::Commercial
      case CDoom.gamemap
      when 15, 31
        CDoom.f_start_finale if CDoom.secretexit == 0
      when 6, 11, 20, 30
        CDoom.f_start_finale
      end
    end
  end

  #
  # g_do_world_done
  #
  def self.g_do_world_done
    CDoom.gamestate = CDoom::Gamestate::Level
    CDoom.gamemap = CDoom.wminfo.next + 1
    CDoom.g_do_load_level
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.viewactive = 1
  end

  #
  # g_load_game
  # Can be called by the startup code or the menu task.
  #
  def self.g_load_game(name : UInt8*)
    CDoom.doom_strcpy(CDoom.savename, name)
    CDoom.gameaction = CDoom::Gameaction::Loadgame
  end

  def self.g_do_load_game
    CDoom.gameaction = CDoom::Gameaction::Nothing

    length = CDoom.m_read_file(CDoom.savename, pointerof(CDoom.savebuffer))
    CDoom.save_p = CDoom.savebuffer + CDoom::SAVESTRINGSIZE

    vcheck = uninitialized StaticArray(UInt8, CDoom::VERSIONSIZE)

    # skip the description field
    CDoom.doom_memset(vcheck.to_unsafe, 0, sizeof(typeof(vcheck)))
    CDoom.doom_strcpy(vcheck.to_unsafe, "version ")
    CDoom.doom_concat(vcheck.to_unsafe, CDoom.doom_itoa(CDoom::VERSION, 10))
    return if CDoom.doom_strcmp(CDoom.save_p.as(UInt8*), vcheck.to_unsafe) != 0 # bad version
    CDoom.save_p += CDoom::VERSIONSIZE

    CDoom.gameskill = CDoom::Skill.new(CDoom.save_p.value)
    CDoom.save_p += 1
    CDoom.gameepisode = CDoom.save_p.value
    CDoom.save_p += 1
    CDoom.gamemap = CDoom.save_p.value
    CDoom.save_p += 1
    CDoom::MAXPLAYERS.times do |i|
      CDoom.playeringame[i] = CDoom.save_p.value
      CDoom.save_p += 1
    end

    # load a base level
    CDoom.g_init_new(CDoom.gameskill, CDoom.gameepisode, CDoom.gamemap)

    # get the times
    a = CDoom.save_p.value
    CDoom.save_p += 1
    b = CDoom.save_p.value
    CDoom.save_p += 1
    c = CDoom.save_p.value
    CDoom.save_p += 1
    CDoom.leveltime = (a << 16) + (b << 8) + c

    # dearchive all the modifications
    CDoom.p_unarchive_players
    CDoom.p_unarchive_world
    CDoom.p_unarchive_thinkers
    CDoom.p_unarchive_specials

    CDoom.i_error("Error: Bad savegame") if CDoom.save_p.value != 0x1d

    # done
    CDoom.z_free(CDoom.savebuffer)

    CDoom.r_execute_set_view_size if CDoom.setsizeneeded != 0

    # draw the pattern into the back screen
    CDoom.r_fill_back_screen
  end

  #
  # g_save_game
  # Called by the menu task.
  # Description is a 24 byte text string
  #
  def self.g_save_game(slot : Int32, description : UInt8*)
    CDoom.savegameslot = slot
    CDoom.doom_strcpy(CDoom.savedescription, description)
    CDoom.sendsave = 1
  end

  def self.g_do_save_game
    name = uninitialized StaticArray(UInt8, 100)
    name2 = uninitialized StaticArray(UInt8, CDoom::VERSIONSIZE)

    CDoom.doom_strcpy(name, CDoom::SAVEGAMENAME)
    CDoom.doom_concat(name, CDoom.doom_itoa(CDoom.savegameslot, 10))
    CDoom.doom_concat(name, ".dsg")
    description = CDoom.savedescription

    CDoom.save_p = CDoom.screens[1] + 0x4000
    CDoom.savebuffer = CDoom.save_p

    CDoom.doom_memcpy(CDoom.save_p, description, CDoom::SAVESTRINGSIZE)
    CDoom.save_p += CDoom::SAVESTRINGSIZE
    CDoom.doom_memset(name2, 0, sizeof(typeof(name2)))
    CDoom.doom_strcpy(name2, "version ")
    CDoom.doom_concat(name2, CDoom.doom_itoa(CDoom::VERSION, 10))
    CDoom.doom_memcpy(CDoom.save_p, name2, CDoom::VERSIONSIZE)
    CDoom.save_p += CDoom::VERSIONSIZE

    CDoom.save_p.value = CDoom.gameskill.value.to_u8!
    CDoom.save_p += 1
    CDoom.save_p.value = CDoom.gameepisode.to_u8!
    CDoom.save_p += 1
    CDoom.save_p.value = CDoom.gamemap.to_u8!
    CDoom.save_p += 1
    CDoom::MAXPLAYERS.times do |i|
      CDoom.save_p.value = CDoom.playeringame[i].to_u8!
      CDoom.save_p += 1
    end
    CDoom.save_p.value = (CDoom.leveltime >> 16).to_u8!
    CDoom.save_p += 1
    CDoom.save_p.value = (CDoom.leveltime >> 8).to_u8!
    CDoom.save_p += 1
    CDoom.save_p.value = (CDoom.leveltime).to_u8!
    CDoom.save_p += 1

    CDoom.p_archive_players
    CDoom.p_archive_world
    CDoom.p_archive_thinkers
    CDoom.p_archive_specials

    CDoom.save_p.value = 0x1d # consistancy marker
    CDoom.save_p += 1

    length = (CDoom.save_p - CDoom.savebuffer).to_i32!
    CDoom.i_error("Error: Savegame buffer overrun") if length > CDoom::SAVEGAMESIZE
    CDoom.m_write_file(name, CDoom.savebuffer, length)
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.savedescription[0] = 0

    (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom::GGSAVED

    # draw the pattern into the back screen
    CDoom.r_fill_back_screen
  end

  #
  # g_init_new
  # Can be called by the startup code or the menu task,
  # consoleplayer, displayplayer, playeringame[] should be set.
  #
  def self.g_defered_init_new(skill : CDoom::Skill, episode : Int32, map : Int32)
    CDoom.d_skill = skill
    CDoom.d_episode = episode
    CDoom.d_map = map
    CDoom.gameaction = CDoom::Gameaction::Newgame
  end

  def self.g_do_new_game
    CDoom.demoplayback = 0
    CDoom.netdemo = 0
    CDoom.netgame = 0
    CDoom.deathmatch = 0
    CDoom.playeringame[1] = 0
    CDoom.playeringame[2] = 0
    CDoom.playeringame[3] = 0
    CDoom.respawnparm = 0
    CDoom.fastparm = 0
    CDoom.nomonsters = 0
    CDoom.consoleplayer = 0
    CDoom.g_init_new(CDoom.d_skill, CDoom.d_episode, CDoom.d_map)
    CDoom.gameaction = CDoom::Gameaction::Nothing
  end

  def self.g_init_new(skill : CDoom::Skill, episode : Int32, map : Int32)
    if CDoom.paused != 0
      CDoom.paused = 0
      CDoom.s_resume_sound
    end

    skill = CDoom::Skill::Nightmare if skill > CDoom::Skill::Nightmare

    # This was quite messy with SPECIAL and commented parts.
    # Supposedly hacks to make the latest edition work.
    # It might not work properly.
    episode = 1 if episode < 1

    if CDoom.gamemode == CDoom::GameMode::Retail
      episode = 4 if episode > 4
    elsif CDoom.gamemode == CDoom::GameMode::Shareware
      episode = 1 if episode > 1 # only start episode 1 on shareware
    else
      episode = 3 if episode > 3
    end

    map = 1 if map < 1

    map = 9 if map > 9 && CDoom.gamemode != CDoom::GameMode::Commercial

    CDoom.m_clear_random

    if skill == CDoom::Skill::Nightmare || CDoom.respawnparm != 0
      CDoom.respawnmonsters = 1
    else
      CDoom.respawnmonsters = 0
    end

    if CDoom.fastparm != 0 || (skill == CDoom::Skill::Nightmare && CDoom.gameskill != CDoom::Skill::Nightmare)
      i = CDoom::Statenum::S_SARG_RUN1.value
      while i <= CDoom::Statenum::S_SARG_PAIN2.value
        CDoom.states[i].tics = CDoom.states[i].tics >> 1
        i += 1
      end
      CDoom.mobjinfo[CDoom::Mobjtype::MT_BRUISERSHOT.value].speed = 20 * CDoom::FRACUNIT
      CDoom.mobjinfo[CDoom::Mobjtype::MT_HEADSHOT.value].speed = 20 * CDoom::FRACUNIT
      CDoom.mobjinfo[CDoom::Mobjtype::MT_TROOPSHOT.value].speed = 20 * CDoom::FRACUNIT
    elsif skill != CDoom::Skill::Nightmare && CDoom.gameskill == CDoom::Skill::Nightmare
      i = CDoom::Statenum::S_SARG_RUN1.value
      while i <= CDoom::Statenum::S_SARG_PAIN2.value
        CDoom.states[i].tics = CDoom.states[i].tics << 1
        i += 1
      end
      CDoom.mobjinfo[CDoom::Mobjtype::MT_BRUISERSHOT.value].speed = 15 * CDoom::FRACUNIT
      CDoom.mobjinfo[CDoom::Mobjtype::MT_HEADSHOT.value].speed = 10 * CDoom::FRACUNIT
      CDoom.mobjinfo[CDoom::Mobjtype::MT_TROOPSHOT.value].speed = 10 * CDoom::FRACUNIT
    end

    # force players to be initialized upon first level load
    CDoom::MAXPLAYERS.times { |i| (CDoom.players.to_unsafe + i).value.playerstate = CDoom::Playerstate::PST_REBORN }

    CDoom.usergame = 1 # will be set false if a demo
    CDoom.paused = 0
    CDoom.demoplayback = 0
    CDoom.automapactive = 0
    CDoom.viewactive = 1
    CDoom.gameepisode = episode
    CDoom.gamemap = map
    CDoom.gameskill = skill

    # set the sky map for the episode
    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.skytexture = CDoom.r_texture_num_for_name("SKY3")
      if CDoom.gamemap < 12
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY1")
      elsif CDoom.gamemap < 21
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY2")
      end
    else
      case episode
      when 1
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY1")
      when 2
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY2")
      when 3
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY3")
      when 4 # Special Edition sky
        CDoom.skytexture = CDoom.r_texture_num_for_name("SKY4")
      end
    end

    CDoom.g_do_load_level
  end

  #
  # DEMO RECORDING
  #
  def self.g_read_demo_ticcmd(cmd : CDoom::Ticcmd*)
    if CDoom.demo_p.value == CDoom::DEMOMARKER
      # end of demo data stream
      CDoom.g_check_demo_status
      return
    end
    cmd.value.forwardmove = CDoom.demo_p.value.to_i8!
    CDoom.demo_p += 1
    cmd.value.sidemove = CDoom.demo_p.value.to_i8!
    CDoom.demo_p += 1
    cmd.value.angleturn = (CDoom.demo_p.value.to_u8!).to_i32 << 8
    CDoom.demo_p += 1
    cmd.value.buttons = CDoom.demo_p.value.to_u8!
    CDoom.demo_p += 1
  end

  def self.g_write_demo_ticcmd(cmd : CDoom::Ticcmd*)
    CDoom.g_check_demo_status if CDoom.gamekeydown['q'.ord] != 0 # press q to end demo recording
    CDoom.demo_p.value = cmd.value.forwardmove.to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p.value = cmd.value.sidemove.to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p.value = ((cmd.value.angleturn.to_i32 + 128) >> 8).to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p.value = cmd.value.buttons.to_u8!
    CDoom.demo_p += 1
    CDoom.demo_p -= 4
    if CDoom.demo_p > CDoom.demoend - 16
      # no more space
      CDoom.g_check_demo_status
      return
    end

    CDoom.g_read_demo_ticcmd(cmd) # make SURE it is exactly the same
  end

  #
  # g_record_demo
  #
  def self.g_record_demo(name : UInt8*)
    CDoom.usergame = 0
    CDoom.doom_strcpy(CDoom.demoname, name)
    CDoom.doom_concat(CDoom.demoname, ".lmp")
    maxsize = 0x20000
    i = CDoom.m_check_parm("-maxdemo")
    maxsize = CDoom.doom_atoi(CDoom.myargv[i + 1]) * 1024 if i != 0 && i < CDoom.myargc - 1
    CDoom.demobuffer = CDoom.z_malloc(maxsize, CDoom::PU_STATIC, Pointer(Void).null).as(UInt8*)
    CDoom.demoend = CDoom.demobuffer + maxsize

    CDoom.demorecording = 1
  end

  def self.g_begin_recording
    CDoom.demo_p = CDoom.demobuffer

    CDoom.demo_p.value = CDoom::VERSION.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.gameskill.value.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.gameepisode.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.gamemap.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.deathmatch.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.respawnparm.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.fastparm.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.nomonsters.to_u8
    CDoom.demo_p += 1
    CDoom.demo_p.value = CDoom.consoleplayer.to_u8
    CDoom.demo_p += 1

    CDoom::MAXPLAYERS.times do |i|
      CDoom.demo_p.value = CDoom.playeringame[i].to_u8
      CDoom.demo_p += 1
    end
  end

  #
  # g_play_demo
  #

  def self.g_defered_play_demo(name : UInt8*)
    CDoom.defdemoname = name
    CDoom.gameaction = CDoom::Gameaction::Playdemo
  end

  def self.g_do_play_demo
    CDoom.gameaction = CDoom::Gameaction::Nothing
    CDoom.demobuffer = CDoom.w_cache_lump_name(CDoom.defdemoname, CDoom::PU_STATIC).as(UInt8*)
    CDoom.demo_p = CDoom.demobuffer
    demo_version = CDoom.demo_p.value
    CDoom.demo_p += 1
    if demo_version != CDoom::VERSION && demo_version != 109 # Demos seem to run fine with version 109
      CDoom.doom_print.call("Demo is from a different game version! Demo Verson = ".to_unsafe)
      CDoom.doom_print.call(CDoom.doom_itoa(demo_version, 10))
      CDoom.doom_print.call(", this version = ".to_unsafe)
      CDoom.doom_print.call(CDoom.doom_itoa(CDoom::VERSION, 10))
      CDoom.doom_print.call("\n".to_unsafe)
      CDoom.gameaction = CDoom::Gameaction::Nothing
      return
    end

    skill = CDoom::Skill.new(CDoom.demo_p.value)
    CDoom.demo_p += 1
    episode = CDoom.demo_p.value
    CDoom.demo_p += 1
    map = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.deathmatch = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.respawnparm = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.fastparm = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.nomonsters = CDoom.demo_p.value
    CDoom.demo_p += 1
    CDoom.consoleplayer = CDoom.demo_p.value
    CDoom.demo_p += 1

    CDoom::MAXPLAYERS.times do |i|
      CDoom.playeringame[i] = CDoom.demo_p.value
      CDoom.demo_p += 1
    end
    if CDoom.playeringame[1] != 0
      CDoom.netgame = 1
      CDoom.netdemo = 1
    end

    # don't spend a lot of time in loadlevel
    CDoom.precache = 0
    CDoom.g_init_new(skill, episode, map)
    CDoom.precache = 1

    CDoom.usergame = 0
    CDoom.demoplayback = 1
  end

  #
  # g_time_demo
  #
  def self.g_time_demo(name : UInt8*)
    CDoom.nodrawers = CDoom.m_check_parm("-nodraw")
    CDoom.noblit = CDoom.m_check_parm("-noblit")
    CDoom.timingdemo = 1
    CDoom.singletics = 1

    CDoom.defdemoname = name
    CDoom.gameaction = CDoom::Gameaction::Playdemo
  end

  # ===================
  # =
  # = g_check_demo_status
  # =
  # = Called after a death or level completion to allow demos to be cleaned up
  # = Returns true if a new demo loop action will take place
  # ===================
  def self.g_check_demo_status : CDoom::DoomBool
    if CDoom.timingdemo != 0
      endtime = CDoom.i_get_time

      CDoom.doom_strcpy(CDoom.error_buf, "Error: timed ")
      CDoom.doom_concat(CDoom.error_buf, CDoom.doom_itoa(CDoom.gametic, 10))
      CDoom.doom_concat(CDoom.error_buf, " gametics in ")
      CDoom.doom_concat(CDoom.error_buf, CDoom.doom_itoa(endtime - CDoom.starttime, 10))
      CDoom.doom_concat(CDoom.error_buf, " realtics")
      CDoom.i_error(CDoom.error_buf)
    end

    if CDoom.demoplayback != 0
      CDoom.i_quit if CDoom.singledemo != 0

      z_change_tag(CDoom.demobuffer, CDoom::PU_CACHE)
      CDoom.demoplayback = 0
      CDoom.netdemo = 0
      CDoom.netgame = 0
      CDoom.deathmatch = 0
      CDoom.playeringame[1] = 0
      CDoom.playeringame[2] = 0
      CDoom.playeringame[3] = 0
      CDoom.respawnparm = 0
      CDoom.fastparm = 0
      CDoom.nomonsters = 0
      CDoom.consoleplayer = 0
      CDoom.d_advance_demo
      return 1
    end

    if CDoom.demorecording != 0
      CDoom.demo_p.value = CDoom::DEMOMARKER.to_u8
      CDoom.demo_p += 1
      CDoom.m_write_file(CDoom.demoname, CDoom.demobuffer, (CDoom.demo_p - CDoom.demobuffer).to_i32!)
      CDoom.z_free(CDoom.demobuffer)
      CDoom.demorecording = 0

      CDoom.doom_strcpy(CDoom.error_buf, "Error: Demo ")
      CDoom.doom_concat(CDoom.error_buf, CDoom.demoname)
      CDoom.doom_concat(CDoom.error_buf, " recorded")
      CDoom.i_error(CDoom.error_buf)
    end

    return 0
  end

  def self.hulib_clear_text_line(t : CDoom::HU_Textline*)
    t.value.len = 0
    t.value.l[0] = 0
    t.value.needsupdate = true
  end

  def self.hulib_init_text_line(t : CDoom::HU_Textline*, x : Int32, y : Int32, f : CDoom::Patch**, sc : Int32)
    t.value.x = x
    t.value.y = y
    t.value.f = f
    t.value.sc = sc
    CDoom.hulib_clear_text_line(t)
  end

  def self.hulib_add_char_to_text_line(t : CDoom::HU_Textline*, ch : UInt8) : CDoom::DoomBool
    if t.value.len == CDoom::HU_MAXLINELENGTH
      return 0
    else
      t.value.l[t.value.len] = ch
      t.value.len = t.value.len + 1
      t.value.l[t.value.len] = 0
      t.value.needsupdate = 4
      return 1
    end
  end

  def self.hulib_del_char_from_text_line(t : CDoom::HU_Textline*) : CDoom::DoomBool
    if t.value.len == 0
      return 0
    else
      t.value.len = t.value.len - 1
      t.value.l[t.value.len] = 0
      t.value.needsupdate = 4
      return 1
    end
  end

  def self.hulib_draw_text_line(l : CDoom::HU_Textline*, drawcursor : CDoom::DoomBool)
    # draw the new stuff
    x = l.value.x
    l.value.len.times do |i|
      c = CDoom.doom_toupper(l.value.l[i])
      if c != ' '.ord &&
         c >= l.value.sc &&
         c <= '_'.ord
        w = l.value.f[c - l.value.sc].value.width.to_i16!
        break if x + w > CDoom::SCREENWIDTH
        CDoom.v_draw_patch_direct(x, l.value.y, CDoom::FG, l.value.f[c - l.value.sc])
        x += w
      else
        x += 4
        break if x >= CDoom::SCREENWIDTH
      end
    end

    # draw the cursor if requested
    if drawcursor != 0 && x + l.value.f['_'.ord - l.value.sc].value.width.to_i16! <= CDoom::SCREENWIDTH
      CDoom.v_draw_patch_direct(x, l.value.y, CDoom::FG, l.value.f['_'.ord - l.value.sc])
    end
  end

  @@lastautomapactive = 1

  # sorta called by hu_erase and just better darn get things straight
  def self.hulib_erase_text_line(l : CDoom::HU_Textline*)
    # Only erases when NOT in automap and the screen is reduced,
    # and the text must either need updating or refreshing
    # (because of a recent change back from the automap)

    if CDoom.automapactive == 0 && CDoom.viewwindowx != 0 && l.value.needsupdate != 0
      lh = l.value.f[0].value.height.to_i16! + 1
      y = l.value.y
      yoffset = y * CDoom::SCREENWIDTH
      while y < l.value.y + lh
        if y < CDoom.viewwindowy || y >= CDoom.viewwindowy + CDoom.viewheight
          CDoom.r_video_erase(yoffset, CDoom::SCREENWIDTH) # erase entire line
        else
          CDoom.r_video_erase(yoffset, CDoom.viewwindowx)                                       # erase left border
          CDoom.r_video_erase(yoffset + CDoom.viewwindowx + CDoom.viewwidth, CDoom.viewwindowx) # erase right border
        end

        y += 1
        yoffset += CDoom::SCREENWIDTH
      end
    end

    @@lastautomapactive = CDoom.automapactive
    l.value.needsupdate = l.value.needsupdate - 1 if l.value.needsupdate != 0
  end

  def self.hulib_init_s_text(s : CDoom::HU_Stext*,
                             x : Int32,
                             y : Int32,
                             h : Int32,
                             font : CDoom::Patch**,
                             startchar : Int32,
                             on : CDoom::DoomBool*)
    s.value.h = h
    s.value.on = on
    s.value.laston = 1
    s.value.cl = 0
    h.times do |i|
      CDoom.hulib_init_text_line(s.value.l.to_unsafe + i,
        x, y - i * (font[0].value.height.to_i16! + 1),
        font, startchar)
    end
  end

  def self.hulib_add_line_to_s_text(s : CDoom::HU_Stext*)
    # add a clear line
    s.value.cl = s.value.cl + 1
    s.value.cl = 0 if s.value.cl == s.value.h
    CDoom.hulib_clear_text_line(s.value.l.to_unsafe + s.value.cl)

    # everything needs updating
    s.value.h.times do |i|
      (s.value.l.to_unsafe + i).value.needsupdate = 4
    end
  end

  def self.hulib_add_message_to_s_text(s : CDoom::HU_Stext*, prefix : UInt8*, msg : UInt8*)
    CDoom.hulib_add_line_to_s_text(s)
    if !prefix.null?
      while prefix.value != 0
        CDoom.hulib_add_char_to_text_line(s.value.l.to_unsafe + s.value.cl, prefix.value)
        prefix += 1
      end
    end

    while msg.value != 0
      CDoom.hulib_add_char_to_text_line(s.value.l.to_unsafe + s.value.cl, msg.value)
      msg += 1
    end
  end

  def self.hulib_draw_s_text(s : CDoom::HU_Stext*)
    return if s.value.on.value == 0 # if not on, don't draw

    # draw everything
    s.value.h.times do |i|
      idx = s.value.cl - i
      idx += s.value.h if idx < 0 # handle queue of lines
      l = s.value.l.to_unsafe + idx

      # need a decision made here on whether to skip the draw
      CDoom.hulib_draw_text_line(l, 0) # no cursor, please
    end
  end

  def self.hulib_erase_s_text(s : CDoom::HU_Stext*)
    s.value.h.times do |i|
      if s.value.laston != 0 && s.value.on.value == 0
        (s.value.l.to_unsafe + i).value.needsupdate = 4
      end
      CDoom.hulib_erase_text_line(s.value.l.to_unsafe + i)
    end
    s.value.laston = s.value.on.value
  end

  def self.hulib_init_i_text(it : CDoom::HU_Itext*,
                             x : Int32,
                             y : Int32,
                             font : CDoom::Patch**,
                             startchar : Int32,
                             on : CDoom::DoomBool*)
    it.value.lm = 0 # default left margin is start of text
    it.value.on = on
    it.value.laston = 1
    CDoom.hulib_init_text_line((it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*), x, y, font, startchar)
  end

  # The following deletion routines adhere to the left margin restriction
  def self.hulib_del_char_from_i_text(it : CDoom::HU_Itext*)
    CDoom.hulib_del_char_from_text_line((it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*)) if it.value.l.len != it.value.lm
  end

  def self.hulib_erase_line_from_i_text(it : CDoom::HU_Itext*)
    while it.value.lm != it.value.l.len
      CDoom.hulib_del_char_from_text_line((it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*))
    end
  end

  # Resets left margin as well
  def self.hulib_reset_i_text(it : CDoom::HU_Itext*)
    it.value.lm = 0
    CDoom.hulib_clear_text_line((it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*))
  end

  def self.hulib_add_prefix_to_i_text(it : CDoom::HU_Itext*, str : UInt8*)
    while str.value != 0
      CDoom.hulib_add_char_to_text_line((it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*), str.value)
      str += 1
    end
    it.value.lm = it.value.l.len
  end

  # wrapper function for handling general keyed input.
  # returns true if it ate the key
  def self.hulib_key_in_i_text(it : CDoom::HU_Itext*, ch : UInt8) : CDoom::DoomBool
    if ch >= ' '.ord && ch <= '_'.ord
      CDoom.hulib_add_char_to_text_line((it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*), ch.to_i8!)
    else
      if ch == CDoom::KEY_BACKSPACE
        CDoom.hulib_del_char_from_i_text(it)
      elsif ch != CDoom::KEY_ENTER
        return 0 # did not eat key
      end
    end

    return 1 # ate the key
  end

  def self.hulib_draw_i_text(it : CDoom::HU_Itext*)
    l = (it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*)

    return if it.value.on.value == 0
    CDoom.hulib_draw_text_line(l, 1) # draw the line w/ cursor
  end

  def self.hulib_erase_i_text(it : CDoom::HU_Itext*)
    if it.value.laston != 0 && it.value.on.value == 0
      it.value.l.needsupdate = 4
    end

    CDoom.hulib_erase_text_line((it + offsetof(CDoom::HU_Itext, @l)).as(CDoom::HU_Textline*))
    it.value.laston = it.value.on.value
  end

  def self.foreign_translation(ch : UInt8) : UInt8
    return ch < 128 ? CDoom.french_key_map[ch] : ch
  end

  def self.hu_init
    buffer = uninitialized StaticArray(UInt8, 9)

    if CDoom.language == CDoom::Language::French
      CDoom.shiftxform = CDoom.french_shiftxform
    else
      CDoom.shiftxform = CDoom.english_shiftxform
    end

    # load the heads-up font
    j = CDoom::HU_FONTSTART
    CDoom::HU_FONTSIZE.times do |i|
      CDoom.doom_strcpy(buffer, "STCFN")
      CDoom.doom_concat(buffer, "0") if j < 100
      CDoom.doom_concat(buffer, "0") if j < 10
      CDoom.doom_concat(buffer, CDoom.doom_itoa(j, 10))
      j += 1
      CDoom.hu_font[i] = CDoom.w_cache_lump_name(buffer, CDoom::PU_STATIC).as(CDoom::Patch*)
    end
  end

  def self.hu_stop
    CDoom.headsupactive = 0
  end

  def self.hu_start
    CDoom.hu_stop if CDoom.headsupactive != 0

    CDoom.plr = CDoom.players.to_unsafe + CDoom.consoleplayer
    CDoom.message_on = 0
    CDoom.message_dontfuckwithme = 0
    CDoom.message_nottobefuckedwith = 0
    CDoom.chat_on = 0

    # create the message widget
    CDoom.hulib_init_s_text(pointerof(CDoom.w_message),
      CDoom::HU_MSGX, CDoom::HU_MSGY, CDoom::HU_MSGHEIGHT,
      CDoom.hu_font, CDoom::HU_FONTSTART, pointerof(CDoom.message_on))

    # # create the map title widget
    CDoom.hulib_init_text_line(pointerof(CDoom.w_title),
      0, 167 - CDoom.hu_font[0].value.height.to_i16!,
      CDoom.hu_font, CDoom::HU_FONTSTART)

    s = CDoom::HU_TITLE2
    case CDoom.gamemode
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered, CDoom::GameMode::Retail
      s = CDoom::HU_TITLE
    when CDoom::GameMode::Commercial
    end

    while s.value != 0
      CDoom.hulib_add_char_to_text_line(pointerof(CDoom.w_title), s.value)
      s += 1
    end

    # create the chat widget
    CDoom.hulib_init_i_text(pointerof(CDoom.w_chat), CDoom::HU_MSGX, CDoom::HU_MSGY + CDoom::HU_MSGHEIGHT*(CDoom.hu_font[0].value.height.to_i16! + 1),
      CDoom.hu_font, CDoom::HU_FONTSTART, pointerof(CDoom.chat_on))

    # create the inputbuffer widgets
    CDoom::MAXPLAYERS.times do |i|
      CDoom.hulib_init_i_text(CDoom.w_inputbuffer.to_unsafe + i, 0, 0, Pointer(Pointer(CDoom::Patch)).null, 0, pointerof(CDoom.always_off))
    end

    CDoom.headsupactive = 1
  end

  def self.hu_drawer
    CDoom.hulib_draw_s_text(pointerof(CDoom.w_message))
    CDoom.hulib_draw_i_text(pointerof(CDoom.w_chat))
    CDoom.hulib_draw_text_line(pointerof(CDoom.w_title), 0) if CDoom.automapactive != 0
  end

  def self.hu_erase
    CDoom.hulib_erase_s_text(pointerof(CDoom.w_message))
    CDoom.hulib_erase_i_text(pointerof(CDoom.w_chat))
    CDoom.hulib_erase_text_line(pointerof(CDoom.w_title))
  end

  def self.hu_ticker
    # tick down message counter if message is up
    if CDoom.message_counter != 0 && (CDoom.message_counter -= 1) == 0
      CDoom.message_on = 0
      CDoom.message_nottobefuckedwith = 0
    end

    if CDoom.show_messages != 0 || CDoom.message_dontfuckwithme != 0
      # display message if necessary
      if (!CDoom.plr.value.message.null? && CDoom.message_nottobefuckedwith == 0) ||
         (!CDoom.plr.value.message.null? && CDoom.message_dontfuckwithme != 0)
        CDoom.hulib_add_message_to_s_text(pointerof(CDoom.w_message), Pointer(UInt8).null, CDoom.plr.value.message)
        CDoom.plr.value.message = Pointer(UInt8).null
        CDoom.message_on = 1
        CDoom.message_counter = CDoom::HU_MSGTIMEOUT
        CDoom.message_nottobefuckedwith = CDoom.message_dontfuckwithme
        CDoom.message_dontfuckwithme = 0
      end
    end

    # check for incoming chat characters
    if CDoom.netgame != 0
      CDoom::MAXPLAYERS.times do |i|
        next if CDoom.playeringame[i] == 0
        if i != CDoom.consoleplayer && (c = CDoom.players[i].cmd.chatchar) != 0
          if c <= CDoom::HU_BROADCAST
            CDoom.chat_dest[i] = c
          else
            if c >= 'a'.ord && c <= 'z'.ord
              c = CDoom.shiftxform[c]
            end
            rc = CDoom.hulib_key_in_i_text(CDoom.w_inputbuffer.to_unsafe + i, c)
            if rc != 0 && c == CDoom::KEY_ENTER
              if CDoom.w_inputbuffer[i].l.len != 0 &&
                 (CDoom.chat_dest[i] == CDoom.consoleplayer + 1 ||
                 CDoom.chat_dest[i] == CDoom::HU_BROADCAST)
                CDoom.hulib_add_message_to_s_text(pointerof(CDoom.w_message),
                  CDoom.player_names[i],
                  CDoom.w_inputbuffer[i].l.l)

                CDoom.message_nottobefuckedwith = 1
                CDoom.message_on = 1
                CDoom.message_counter = CDoom::HU_MSGTIMEOUT
                if CDoom.gamemode == CDoom::GameMode::Commercial
                  CDoom.s_start_sound(Pointer(CDoom::Mobj).null, CDoom::Sfxenum::SFX_radio)
                else
                  CDoom.s_start_sound(Pointer(CDoom::Mobj).null, CDoom::Sfxenum::SFX_tink)
                end
              end
              CDoom.hulib_reset_i_text(CDoom.w_inputbuffer.to_unsafe + i)
            end
          end
          ((CDoom.players.to_unsafe + i).as(UInt8*) + offsetof(CDoom::Player, @cmd)).as(CDoom::Ticcmd*).value.chatchar = 0
        end
      end
    end
  end

  def self.hu_queue_chat_char(c : UInt8)
    if ((CDoom.head + 1) & (CDoom::QUEUESIZE - 1)) == CDoom.tail
      CDoom.plr.value.message = CDoom::HUSTR_MSGU
    else
      CDoom.chatchars[CDoom.head] = c
      CDoom.head = (CDoom.head + 1) & (CDoom::QUEUESIZE - 1)
    end
  end

  def self.hu_dequeue_chat_char : UInt8
    c = 0_u8
    if CDoom.head != CDoom.tail
      c = CDoom.chatchars[CDoom.tail]
      CDoom.tail = (CDoom.tail + 1) & (CDoom::QUEUESIZE - 1)
    end

    return c
  end

  LASTMESSAGE_SIZE = CDoom::HU_MAXLINELENGTH + 1
  @@lastmessage = uninitialized StaticArray(UInt8, LASTMESSAGE_SIZE)
  @@shiftdown = 0
  @@altdown = 0
  @@destination_keys : StaticArray(UInt8, CDoom::MAXPLAYERS) = StaticArray[
    CDoom::HUSTR_KEYGREEN.ord.to_u8,
    CDoom::HUSTR_KEYINDIGO.ord.to_u8,
    CDoom::HUSTR_KEYBROWN.ord.to_u8,
    CDoom::HUSTR_KEYRED.ord.to_u8,
  ]
  @@num_nobrainers = 0

  def self.hu_responder(ev : CDoom::Event*) : CDoom::DoomBool
    eatkey = 0
    numplayers = 0
    CDoom::MAXPLAYERS.times { |i| numplayers += CDoom.playeringame[i] }

    if ev.value.data1 == CDoom::KEY_RSHIFT
      @@shiftdown = (ev.value.type == CDoom::Evtype::Keydown).to_unsafe
      return 0
    elsif ev.value.data1 == CDoom::KEY_RALT || ev.value.data1 == CDoom::KEY_LALT
      @@altdown = (ev.value.type == CDoom::Evtype::Keydown).to_unsafe
      return 0
    end

    return 0 if ev.value.type != CDoom::Evtype::Keydown

    if CDoom.chat_on == 0
      if ev.value.data1 == CDoom::HU_MSGREFRESH
        CDoom.message_on = 1
        CDoom.message_counter = CDoom::HU_MSGTIMEOUT
        eatkey = 1
      elsif CDoom.netgame != 0 && ev.value.data1 == CDoom::HU_INPUTTOGGLE
        eatkey = 1
        CDoom.chat_on = 1
        CDoom.hulib_reset_i_text(pointerof(CDoom.w_chat))
        CDoom.hu_queue_chat_char(CDoom::HU_BROADCAST)
      elsif CDoom.netgame != 0 && numplayers > 2
        CDoom::MAXPLAYERS.times do |i|
          if ev.value.data1 == @@destination_keys[i]
            if CDoom.playeringame[i] != 0 && i != CDoom.consoleplayer
              eatkey = 1
              CDoom.chat_on = 1
              CDoom.hulib_reset_i_text(pointerof(CDoom.w_chat))
              CDoom.hu_queue_chat_char(i + 1)
              break
            elsif i == CDoom.consoleplayer
              @@num_nobrainers += 1
              if @@num_nobrainers < 3
                CDoom.plr.value.message = CDoom::HUSTR_TALKTOSELF1
              elsif @@num_nobrainers < 6
                CDoom.plr.value.message = CDoom::HUSTR_TALKTOSELF2
              elsif @@num_nobrainers < 9
                CDoom.plr.value.message = CDoom::HUSTR_TALKTOSELF3
              elsif @@num_nobrainers < 32
                CDoom.plr.value.message = CDoom::HUSTR_TALKTOSELF4
              else
                CDoom.plr.value.message = CDoom::HUSTR_TALKTOSELF5
              end
            end
          end
        end
      end
    else
      c = ev.value.data1
      # send a macro
      if @@altdown != 0
        return 0 if c < '0'.ord || c > '9'.ord
        c = c - '0'.ord
        macromessage = CDoom.chat_macros[c]

        # kill last message with a '\n'
        CDoom.hu_queue_chat_char(CDoom::KEY_ENTER) # DEBUG!!!

        # send the macro message
        while macromessage.value != 0
          CDoom.hu_queue_chat_char(macromessage.value)
          macromessage += 1
        end
        CDoom.hu_queue_chat_char(CDoom::KEY_ENTER)

        # leave chat mode and notify that it was sent
        CDoom.chat_on = 0
        CDoom.doom_strcpy(@@lastmessage, CDoom.chat_macros[c])
        CDoom.plr.value.message = @@lastmessage
        eatkey = 1
      else
        c = CDoom.foreign_translation(c) if CDoom.language == CDoom::Language::French
        c = CDoom.shiftxform[c] if @@shiftdown != 0 || (c >= 'a'.ord && c <= 'z'.ord)
        eatkey = CDoom.hulib_key_in_i_text(pointerof(CDoom.w_chat), c)
        CDoom.hu_queue_chat_char(c) if eatkey != 0
        if c == CDoom::KEY_ENTER
          CDoom.chat_on = 0
          if CDoom.w_chat.l.len != 0
            CDoom.doom_strcpy(@@lastmessage, CDoom.w_chat.l.l)
            CDoom.plr.value.message = @@lastmessage
          end
        elsif c == CDoom::KEY_ESCAPE
          CDoom.chat_on = 0
        end
      end
    end

    return eatkey
  end

  def self.i_init_network
    CDoom.doomcom = CDoom.doom_malloc.call(sizeof(typeof(CDoom.doomcom.value))).as(Pointer(CDoom::Doomcom))
    CDoom.doom_memset(CDoom.doomcom, 0, sizeof(typeof(CDoom.doomcom.value)))

    # set up for network
    i = CDoom.m_check_parm("-dup")
    if i != 0 && i < CDoom.myargc - 1
      CDoom.doomcom.value.ticdup = CDoom.myargv[i + 1][0] - '0'.ord
      CDoom.doomcom.value.ticdup = 1 if CDoom.doomcom.value.ticdup < 1
      CDoom.doomcom.value.ticdup = 9 if CDoom.doomcom.value.ticdup > 9
    else
      CDoom.doomcom.value.ticdup = 1
    end

    if CDoom.m_check_parm("-extratic")
      CDoom.doomcom.value.extratics = 1
    else
      CDoom.doomcom.value.extratics = 0
    end

    p = CDoom.m_check_parm("-port")
    if p != 0 && p < CDoom.myargc - 1
      @@doomport = CDoom.doom_atoi(CDoom.myargv[p + 1])
      CDoom.doom_print.call("using alternate port ".to_unsafe)
      CDoom.doom_print.call(CDoom.doom_itoa(@@doomport, 10))
      CDoom.doom_print.call("\n".to_unsafe)
    end

    p = CDoom.m_check_parm("-port")
    if p != 0 && p < CDoom.myargc - 1
      @@doomport_send = CDoom.doom_atoi(CDoom.myargv[p + 1])
      CDoom.doom_print.call("using alternate send port ".to_unsafe)
      CDoom.doom_print.call(CDoom.doom_itoa(@@doomport_send, 10))
      CDoom.doom_print.call("\n".to_unsafe)
    end

    # parse network game options,
    #  -net <consoleplayer> <host> <host> ...
    i = CDoom.m_check_parm("-net")
    if i == 0
      # single player game
      CDoom.netgame = 0
      CDoom.doomcom.value.id = CDoom::DOOMCOM_ID
      CDoom.doomcom.value.numplayers = 1
      CDoom.doomcom.value.numnodes = 1
      CDoom.deathmatch = 0
      CDoom.consoleplayer = 0
      return
    end
  end

  def self.i_net_cmd
  end

  #
  # This function loads the sound data from the WAD lump,
  #  for single sound.
  #
  def self.getsfx(sfxname : UInt8*, len : Int32*) : Void*
    name = uninitialized StaticArray(UInt8, 20)

    # Get the sound data from the WAD, allocate lump
    #  in zone memory.
    CDoom.doom_strcpy(name, "ds")
    CDoom.doom_concat(name, sfxname)

    # Now, there is a severe problem with the
    #  sound handling, in it is not (yet/anymore)
    #  gamemode aware. That means, sounds from
    #  DOOM II will be requested even with DOOM
    #  shareware.
    # The sound list is wired into sounds.c,
    #  which sets the external variable.
    # I do not do runtime patches to that
    #  variable. Instead, we will use a
    #  default sound for replacement.
    sfxlump = 0
    if CDoom.w_check_num_for_name(name) == -1
      sfxlump = CDoom.w_get_num_for_name("dspistol")
    else
      sfxlump = CDoom.w_get_num_for_name(name)
    end

    size = CDoom.w_lump_length(sfxlump)

    sfx = CDoom.w_cache_lump_num(sfxlump, CDoom::PU_STATIC).as(UInt8*)

    # Pads the sound effect out to the mixing buffer size.
    # The original realloc would interfere with zone memory.
    paddedsize = ((size - 8 + (CDoom::SAMPLECOUNT - 1)) // CDoom::SAMPLECOUNT) * CDoom::SAMPLECOUNT

    # Allocate from zone memory.
    paddedsfx = CDoom.z_malloc(paddedsize + 8, CDoom::PU_STATIC, Pointer(Void).null).as(UInt8*)
    # ddt: (unsigned char *) realloc(sfx, paddedsize+8);
    # This should interfere with zone memory handling,
    #  which does not kick in in the soundserver.

    # Now copy and pad.
    CDoom.doom_memcpy(paddedsfx, sfx, size)
    i = size
    while i < paddedsize + 8
      paddedsfx[i] = 128
      i += 1
    end

    # Remove the cached lump.
    CDoom.z_free(sfx)

    # Preserve padded length.
    len.value = paddedsize

    # Return allocated padded data
    return (paddedsfx + 8).as(Void*)
  end

  @@handlenums : UInt16 = 0

  #
  # This function adds a sound to the
  #  list of currently active sounds,
  #  which is maintained as a given number
  #  (eight, usually) of internal channels.
  # Returns a handle.
  #
  def self.addsfx(sfxid : Int32, volume : Int32, step : Int32, seperation : Int32) : Int32
    rc = -1
    oldest = CDoom.gametic
    oldestnum = 0

    # Chainsaw troubles.
    # Play these sound effects only one at a time.
    if sfxid == CDoom::Sfxenum::SFX_sawup.value ||
       sfxid == CDoom::Sfxenum::SFX_sawidl.value ||
       sfxid == CDoom::Sfxenum::SFX_sawful.value ||
       sfxid == CDoom::Sfxenum::SFX_sawhit.value ||
       sfxid == CDoom::Sfxenum::SFX_stnmov.value ||
       sfxid == CDoom::Sfxenum::SFX_pistol.value
      # Loop all channels, check.
      CDoom::NUM_CHANNELS.times do |i|
        # Active, and using the same SFX?
        if !CDoom.channels[i].null? && CDoom.channelids[i] == sfxid
          # Reset.
          CDoom.channels[i] = Pointer(UInt8).null
          # We are sure that iff,
          #  there will only be one
          break
        end
      end
    end

    i = 0
    # Loop all channels to find oldest SFX.
    while i < CDoom::NUM_CHANNELS && !CDoom.channels[i].null?
      if CDoom.channelstart[i] < oldest
        oldestnum = i
        oldest = CDoom.channelstart[i]
      end
      i += 1
    end

    # Tales from the cryptic.
    # If we found a channel, fine.
    # If not, we simply overwrite the first one, 0.
    # Probably only happens at startup.
    slot = i
    slot = oldestnum if i == CDoom::NUM_CHANNELS

    # Okay, in the less recent channel,
    #  we will handle the new SFX.
    # Set pointer to raw data.
    CDoom.channels[slot] = (CDoom.s_sfx.to_unsafe + sfxid).value.data.as(UInt8*)
    # Set pointer to end of raw data.
    CDoom.channelsend[slot] = CDoom.channels[slot] + CDoom.lengths[sfxid]

    # Reset current handle number, limited to 0..100.
    @@handlenums = 100 if @@handlenums == 0

    # Assign current handle number.
    # Preserved so sounds could be stopped (unused).
    CDoom.channelhandles[slot] = @@handlenums
    rc = @@handlenums
    @@handlenums += 1

    # Set stepping???
    # Kinda getting the impression this is never used.
    CDoom.channelstep[slot] = step.to_u32
    # ???
    CDoom.channelstepremainder[slot] = 0
    # Should be gametic, I presume.
    CDoom.channelstart[slot] = CDoom.gametic

    # Seperation, that is, orientation/stereo.
    #  range is: 1 - 256
    seperation += 1

    # Per left/right channel.
    #  x^2 seperation,
    #  adjust volume properly.
    leftvol = volume - ((volume * seperation * seperation) >> 16)
    seperation = seperation - 257
    rightvol = volume - ((volume * seperation * seperation) >> 16)

    # Sanity check, clamp volume.
    CDoom.i_error("Error: rightvol out of bounds") if rightvol < 0 || rightvol > 127
    CDoom.i_error("Error: leftvol out of bounds") if leftvol < 0 || leftvol > 127

    # Get the proper lookup table piece
    #  for this volume level???
    CDoom.channelleftvol_lookup[slot] = CDoom.vol_lookup.to_unsafe + leftvol*256
    CDoom.channelrightvol_lookup[slot] = CDoom.vol_lookup.to_unsafe + rightvol*256

    # Preserve sound SFX id,
    #  e.g. for avoiding duplicates of chainsaw.
    CDoom.channelids[slot] = sfxid

    # You tell me.
    return rc.to_i32
  end

  def self.i_set_channels
    # Init internal lookups (raw data, mixing buffer, channels).
    # This function sets up internal lookups used during
    #  the mixing process.
    steptablemid = CDoom.steptable.to_unsafe + 128

    # This table provides step widths for pitch parameters.
    # I fail to see that this is currently used.
    i = -128
    while i < 128
      steptablemid[i] = ((2**(i / 64.0)) * 65536).floor.to_i32!
      i += 1
    end

    # Generates volume lookup tables
    #  which also turn the unsigned samples
    #  into signed samples.
    128.times do |i|
      256.times do |j|
        CDoom.vol_lookup[i * 256 + j] = (i * (j - 128) * 256) // 127
      end
    end
  end

  def self.i_set_sfx_volume(volume : Int32)
    # Identical to DOS.
    # Basically, this should propagate
    #  the menu/config file setting
    #  to the state variable used in
    #  the mixing.
    CDoom.snd_sfx_volume = volume
  end

  # MUSIC API - dummy. Some code from DOS version.
  def self.i_set_music_volume(volume : Int32)
    CDoom.snd_music_volume = volume
    CDoom.mus_volume = CDoom.snd_music_volume * 8

    16.times do |i|
      CDoom.queued_midi_msgs[CDoom.queue_midi_tail % CDoom::MAX_QUEUED_MIDI_MSGS] = (0x000000B0_u32 | i | 0x0700_u32 | (((CDoom.mus_channel_volumes[i] * CDoom.mus_volume) // 127) << 16))
      CDoom.queue_midi_tail += 1
    end
  end

  def self.i_get_sfx_lump_num(sfx : CDoom::Sfxinfo*) : Int32
    namebuf = uninitialized StaticArray(UInt8, 9)

    CDoom.doom_strcpy(namebuf, "ds")
    CDoom.doom_concat(namebuf, sfx.value.name)
    return CDoom.w_get_num_for_name(namebuf)
  end

  #
  # Starting a sound means adding it
  #  to the current list of active sounds
  #  in the internal channels.
  # As the SFX info struct contains
  #  e.g. a pointer to the raw data,
  #  it is ignored.
  # As our sound handling does not handle
  #  priority, it is ignored.
  # Pitching (that is, increased speed of playback)
  #  is set, but currently not used by mixing.
  #
  def self.i_start_sound(id : Int32, vol : Int32, sep : Int32, pitch : Int32, priority : Int32) : Int32
    # Returns a handle (not used).
    id = CDoom.addsfx(id, vol, CDoom.steptable[pitch], sep)
    return id
  end

  def self.i_stop_sound(handle : Int32)
    CDoom::NUM_CHANNELS.times do |chan|
      if CDoom.channelhandles[chan] == handle && !CDoom.channels[chan].null?
        CDoom.channels[chan] = Pointer(UInt8).null
        break
      end
    end
  end

  def self.i_sound_is_playing(handle : Int32) : Int32
    CDoom::NUM_CHANNELS.times do |chan|
      return (!CDoom.channels[chan].null?).to_unsafe if CDoom.channelhandles[chan] == handle
    end

    return 0
  end

  #
  # This function loops all active (internal) sound
  #  channels, retrieves a given number of samples
  #  from the raw sound data, modifies it according
  #  to the current (internal) channel parameters,
  #  mixes the per channel samples into the global
  #  mixbuffer, clamping it to the allowed range,
  #  and sets up everything for transferring the
  #  contents of the mixbuffer to the (two)
  #  hardware channels (left and right, that is).
  #
  # This function currently supports only 16bit.
  #
  def self.i_update_sound
    # Left and right channel
    #  are in global mixbuffer, alternating.
    leftout = CDoom.mixbuffer.to_unsafe
    rightout = CDoom.mixbuffer.to_unsafe + 1
    step = 2

    # Determine end, for left channel only
    #  (right channel is implicit).
    leftend = CDoom.mixbuffer.to_unsafe + CDoom::SAMPLECOUNT * step

    # Mix sounds into the mixing buffer.
    # Loop over step*SAMPLECOUNT,
    #  that is 512 values for two channels.
    while leftout != leftend
      # Reset left/right value.

      dl = 0
      dr = 0

      # Love thy L2 chache - made this a loop.
      # Now more channels could be set at compile time
      #  as well. Thus loop those  channels.
      CDoom::NUM_CHANNELS.times do |chan|
        # Check channel, if active.
        if !CDoom.channels[chan].null?
          # Get the raw data from the channel.
          sample = CDoom.channels[chan].value
          # Add left and right part
          #  for this channel (sound)
          #  to the current data.
          # Adjust volume accordingly.
          dl += CDoom.channelleftvol_lookup[chan][sample]
          dr += CDoom.channelrightvol_lookup[chan][sample]
          # Increment index ???
          CDoom.channelstepremainder[chan] = CDoom.channelstepremainder[chan] + CDoom.channelstep[chan]
          # MSB is next sample???
          CDoom.channels[chan] = CDoom.channels[chan] + (CDoom.channelstepremainder[chan] >> 16)
          # Limit to LSB???
          CDoom.channelstepremainder[chan] = CDoom.channelstepremainder[chan] & (65536 - 1)
          # Check whether we are done.
          CDoom.channels[chan] = Pointer(UInt8).null if CDoom.channels[chan] >= CDoom.channelsend[chan]
        end
      end

      # Clamp to range. Left hardware channel.
      # Has been char instead of short.
      # if (dl > 127) *leftout = 127;
      # else if (dl < -128) *leftout = -128;
      # else *leftout = dl;

      if dl > 0x7fff
        leftout.value = 0x7fff
      elsif dl < -0x8000
        leftout.value = -0x8000
      else
        leftout.value = dl.to_i16!
      end

      # Same for right hardware channel.
      if dr > 0x7fff
        rightout.value = 0x7fff
      elsif dr < -0x8000
        rightout.value = -0x8000
      else
        rightout.value = dr.to_i16!
      end

      # Increment current pointers in mixbuffer.
      leftout += step
      rightout += step
    end
  end

  def self.i_submit_sound
  end

  def self.i_update_sound_params(handle : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int)
    # I fail too see that this is used.
    # Would be using the handle to identify
    #  on which channel the sound might be active,
    #  and resetting the channel parameters.
    CDoom::NUM_CHANNELS.times do |chan|
      # Found channel
      if CDoom.channelhandles[chan] == handle
        step = CDoom.steptable[pitch]
        CDoom.channelstep[chan] = step.to_u32
        CDoom.channelstart[chan] = CDoom.gametic

        sep += 1

        leftvol = vol - ((vol * sep * sep) >> 16)
        sep = sep - 257
        rightvol = vol - ((vol * sep * sep) >> 16)

        CDoom.i_error("Error: rightvol out of bounds") if rightvol < 0 || rightvol > 127
        CDoom.i_error("Error: leftvol out of bounds") if leftvol < 0 || leftvol > 127

        CDoom.channelleftvol_lookup[chan] = CDoom.vol_lookup.to_unsafe + leftvol*256
        CDoom.channelrightvol_lookup[chan] = CDoom.vol_lookup.to_unsafe + rightvol*256

        break
      end
    end
  end

  def self.i_shutdown_sound
    # Wait till all pending sounds are finished.
    done = 0

    # FIXME (below).
    CDoom.doom_print.call("i_shutdown_sound: NOT finishing pending sounds\n".to_unsafe)

    while done == 0
      8.times do |i|
        break unless !CDoom.channels[i].null?
      end

      done = 1
    end

    @@audio_stream.try { |a| RAudio.unload_audio_stream(a) }

    # Done.
    return
  end

  def self.update_audio
    1.times do |i|
      now = Raylib.get_time
      @@midi_tick_accumulator += now - @@last_time
      @@last_time = now

      while @@midi_tick_accumulator >= MIDI_TICK_TIME
        while (msg = CDoom.doom_tick_midi) != 0
          status = (msg & 0xFF).to_u8
          data1 = ((msg >> 8) & 0xFF).to_u8
          data2 = ((msg >> 16) & 0xFF).to_u8
          command = status & 0xF0
          channel = status & 0x0F

          break if @@closing
          @@adl_player.try do |ap|
            case command
            when 0x80
              ADLMIDI.adl_rt_noteOff(ap, channel, data1)
            when 0x90
              if data2 == 0
                ADLMIDI.adl_rt_noteOff(ap, channel, data1) # vel 0 == note off
              else
                ADLMIDI.adl_rt_noteOn(ap, channel, data1, data2)
              end
            when 0xA0
              ADLMIDI.adl_rt_noteAfterTouch(ap, channel, data1, data2)
            when 0xB0
              ADLMIDI.adl_rt_controllerChange(ap, channel, data1, data2)
            when 0xC0
              ADLMIDI.adl_rt_patchChange(ap, channel, data1)
            when 0xD0
              ADLMIDI.adl_rt_channelAfterTouch(ap, channel, data1)
            when 0xE0
              ADLMIDI.adl_rt_pitchBendML(ap, channel, data2, data1) # wire order: LSB, MSB
            end
          end
        end
        @@midi_tick_accumulator -= MIDI_TICK_TIME
      end

      break if @@closing
      @@music_stream.try do |m|
        @@adl_player.try do |ap|
          if RAudio.audio_stream_processed?(m)
            generated = ADLMIDI.adl_generate(ap, MIDI_BUFFER_SIZE, @@music_buffer)
            RAudio.update_audio_stream(m, @@music_buffer, MIDI_BUFFER_SIZE // 2)
          end
        end
      end

      break if @@closing
      @@audio_stream.try do |a|
        if RAudio.audio_stream_processed?(a)
          RAudio.update_audio_stream(a, CDoom.doom_get_sound_buffer, 512)
        end
      end
    end
  end

  def self.i_init_sound
    # Initialize external data (all sounds) at start, keep static.
    CDoom.doom_print.call("i_init_sound: ".to_unsafe)

    i = 1
    while i < CDoom::Sfxenum::NUMSFX.value
      # Alias? Example is the chaingun sound linked to pistol.
      if (CDoom.s_sfx.to_unsafe + i).value.link.null?
        # Load data from WAD file.
        (CDoom.s_sfx.to_unsafe + i).value.data = CDoom.getsfx((CDoom.s_sfx.to_unsafe + i).value.name, CDoom.lengths.to_unsafe + i)
      else
        # Previously loaded already?
        (CDoom.s_sfx.to_unsafe + i).value.data = (CDoom.s_sfx.to_unsafe + i).value.link.value.data
        CDoom.lengths[i] = CDoom.lengths[((CDoom.s_sfx.to_unsafe + i).value.link - CDoom.s_sfx.to_unsafe) // sizeof(CDoom::Sfxinfo)]
      end

      i += 1
    end

    CDoom.doom_print.call(" pre-cached all sound data\n".to_unsafe)

    # Now initialize mixbuffer with zero.
    CDoom::MIXBUFFERSIZE.times { |i| CDoom.mixbuffer[i] = 0 }

    RAudio.init_audio_device
    RAudio.set_master_volume(10.0)
    RAudio.set_audio_stream_buffer_size_default(512)
    @@audio_stream = RAudio.load_audio_stream(CDoom::DOOM_SAMPLERATE, 16, 2)
    RAudio.set_audio_stream_volume(@@audio_stream.not_nil!, 1.0)
    RAudio.play_audio_stream(@@audio_stream.not_nil!)

    # Finished initialization.
    CDoom.doom_print.call("i_init_sound: sound module ready\n".to_unsafe)
  end

  #
  # MUSIC API.
  #
  def self.i_init_music
    @@adl_player = ADLMIDI.adl_init(44100)
    ADLMIDI.adl_setNumChips(@@adl_player.not_nil!, 4)
    ADLMIDI.adl_setBank(@@adl_player.not_nil!, MIDI_BANK)
    RAudio.set_audio_stream_buffer_size_default(MIDI_BUFFER_SIZE // 2)
    @@music_stream = RAudio.load_audio_stream(MIDI_SAMPLE_RATE, 16, 2)
    RAudio.set_audio_stream_volume(@@music_stream.not_nil!, 1.0)
    RAudio.play_audio_stream(@@music_stream.not_nil!)
    @@music_buffer = Pointer(Int16).malloc(2048)
    @@midi_tick_accumulator = 0.0

    @@last_time = Raylib.get_time
  end

  def self.i_shutdown_music
    @@music_stream.try { |m| RAudio.unload_audio_stream(m) }
    @@adl_player.try { |ap| ADLMIDI.adl_close(ap) }
  end

  def self.i_play_song(handle : Int32, looping : Int32)
    CDoom.musicdies = CDoom.gametic + CDoom::TICRATE * 30

    CDoom.mus_loop = looping != 0 ? 1 : 0
    CDoom.mus_playing = 1
  end

  def self.i_pause_song(handle : Int32)
    CDoom.mus_playing = 0
  end

  def self.i_resume_song(handle : Int32)
    CDoom.mus_playing = 1 if !CDoom.mus_data.null?
  end

  def self.reset_all_channels
    16.times do |i|
      CDoom.queued_midi_msgs[CDoom.queue_midi_tail % CDoom::MAX_QUEUED_MIDI_MSGS] = 0b10110000_u32 | i | (123_u32 << 8)
      CDoom.queue_midi_tail += 1
    end
  end

  def self.i_stop_song(handle : LibC::Int)
    CDoom.mus_data = Pointer(UInt8).null
    CDoom.mus_delay = 0
    CDoom.mus_offset = 0
    CDoom.mus_playing = 0

    CDoom.reset_all_channels
  end

  def self.i_unregister_song(handle : LibC::Int)
    CDoom.i_stop_song(handle)
  end

  def self.i_register_song(data : Void*) : LibC::Int
    CDoom.doom_memcpy(pointerof(CDoom.mus_header), data, sizeof(CDoom::MusHeader))
    return 0 if (CDoom.doom_strncmp(CDoom.mus_header.id, "MUS", 3) != 0 || CDoom.mus_header.id[3] != 0x1A)

    CDoom.mus_data = data.as(UInt8*)
    CDoom.mus_delay = 0
    CDoom.mus_offset = CDoom.mus_header.score_start
    CDoom.mus_playing = 0

    return 1
  end

  # Is the song playing?
  def self.i_qry_song_playing(handle : LibC::Int) : LibC::Int
    return CDoom.mus_playing
  end

  # Is the song playing?
  def self.i_tick_song : LibC::ULong
    midi_event : UInt64 | UInt32 = 0

    # Dequeue MIDI events
    if CDoom.queue_midi_head != CDoom.queue_midi_tail
      CDoom.queue_midi_head += 1
      r = CDoom.queued_midi_msgs[(CDoom.queue_midi_head - 1).remainder(CDoom::MAX_QUEUED_MIDI_MSGS)]
      {% if sizeof(LibC::ULong) == 8 %}
        return r.to_u64!
      {% else %}
        return r.to_u32!
      {% end %}
    end

    if CDoom.mus_playing == 0 || CDoom.mus_data.null?
      r = 0
      {% if sizeof(LibC::ULong) == 8 %}
        return r.to_u64!
      {% else %}
        return r.to_u32!
      {% end %}
    end

    if CDoom.mus_delay <= 0
      event = CDoom.mus_data[CDoom.mus_offset].to_i32
      CDoom.mus_offset += 1
      type = (event & 0b01110000) >> 4
      channel = event & 0b00001111

      if channel == 15
        channel = 9 # Percussion is 9 on GM
      elsif channel == 9
        channel = 15
      end

      case type
      when CDoom::EVENT_RELEASE_NOTE
        note = CDoom.mus_data[CDoom.mus_offset].to_i32 & 0b01111111
        CDoom.mus_offset += 1
        midi_event = (0x00000080_u32 | channel | (note << 8))
      when CDoom::EVENT_PLAY_NOTE
        note_bytes = CDoom.mus_data[CDoom.mus_offset].to_i32
        CDoom.mus_offset += 1
        note = note_bytes & 0b01111111
        vol = 127
        if note_bytes & 0b10000000 != 0
          vol = CDoom.mus_data[CDoom.mus_offset].to_i32 & 0b01111111
          CDoom.mus_offset += 1
        end
        midi_event = (0x00000090_u32 | channel | (note << 8) | (vol << 16))
      when CDoom::EVENT_PITCH_BEND
        bend_amount = CDoom.mus_data[CDoom.mus_offset].to_i32 * 64
        CDoom.mus_offset += 1
        l = bend_amount & 0b01111111
        m = (bend_amount & 0b1111111110000000) >> 7
        midi_event = (0x000000E0_u32 | channel | (l << 8) | (m << 16))
      when CDoom::EVENT_SYSTEM_EVENT
        controller = CDoom.mus_data[CDoom.mus_offset].to_i32 & 0b01111111
        CDoom.mus_offset += 1
        case controller
        when CDoom::CONTROLLER_EVENT_ALL_SOUNDS_OFF
          midi_event = (0x000000B0_u32 | channel | (120 << 8))
        when CDoom::CONTROLLER_EVENT_ALL_NOTES_OFF
          midi_event = (0x000000B0_u32 | channel | (123 << 8))
        when CDoom::CONTROLLER_EVENT_MONO
          midi_event = (0x000000B0_u32 | channel | (126 << 8))
        when CDoom::CONTROLLER_EVENT_POLY
          midi_event = (0x000000B0_u32 | channel | (127 << 8))
        when CDoom::CONTROLLER_EVENT_RESET_ALL_CONTROLLERS
          midi_event = (0x000000B0_u32 | channel | (121 << 8))
        when CDoom::CONTROLLER_EVENT_EVENT # Doom never implemented
        end
      when CDoom::EVENT_CONTROLLER
        controller = CDoom.mus_data[CDoom.mus_offset].to_i32 & 0b01111111
        CDoom.mus_offset += 1
        value = CDoom.mus_data[CDoom.mus_offset].to_i32 & 0b01111111
        CDoom.mus_offset += 1
        case controller
        when CDoom::CONTROLLER_CHANGE_INSTRUMENT
          midi_event = (0x000000C0_u32 | channel | (value << 8))
        when CDoom::CONTROLLER_BANK_SELECT
          midi_event = (0x000000B0_u32 | channel | 0x2000 | (value << 16))
        when CDoom::CONTROLLER_MODULATION
          midi_event = (0x000000B0_u32 | channel | 0x0100 | (value << 16))
        when CDoom::CONTROLLER_VOLUME
          CDoom.mus_channel_volumes[channel] = value
          midi_event = (0x000000B0_u32 | channel | 0x0700 | (((CDoom.mus_channel_volumes[channel] * CDoom.mus_volume) // 127) << 16))
        when CDoom::CONTROLLER_PAN
          midi_event = (0x000000B0_u32 | channel | 0x0A00 | (value << 16))
        when CDoom::CONTROLLER_EXPRESSION
          midi_event = (0x000000B0_u32 | channel | 0x0B00 | (value << 16))
        when CDoom::CONTROLLER_REVERB
          midi_event = (0x000000B0_u32 | channel | 0x5B00 | (value << 16))
        when CDoom::CONTROLLER_CHORUS
          midi_event = (0x000000B0_u32 | channel | 0x5D00 | (value << 16))
        when CDoom::CONTROLLER_SUSTAIN
          midi_event = (0x000000B0_u32 | channel | 0x4000 | (value << 16))
        when CDoom::CONTROLLER_SOFT
          midi_event = (0x000000B0_u32 | channel | 0x4300 | (value << 16))
        end
      when CDoom::EVENT_END_OF_MEASURE
      when CDoom::EVENT_FINISH
        # Loop
        if CDoom.mus_loop != 0
          CDoom.mus_delay = 0
          CDoom.mus_offset = CDoom.mus_header.score_start
        else
          CDoom.mus_playing = 0
          r = 0
          {% if sizeof(LibC::ULong) == 8 %}
            return r.to_u64!
          {% else %}
            return r.to_u32!
          {% end %}
        end
      when CDoom::EVENT_UNUSED
        dummy = CDoom.mus_data[CDoom.mus_offset].to_i32
        CDoom.mus_offset += 1
      end

      if event & 0b10000000 != 0 # Followed by delay
        CDoom.mus_delay = 0
        delay_byte = 0
        loop do
          delay_byte = CDoom.mus_data[CDoom.mus_offset]
          CDoom.mus_offset += 1
          CDoom.mus_delay = CDoom.mus_delay * 128 + (delay_byte & 0b01111111)

          break unless delay_byte & 0b10000000 != 0
        end

        r = midi_event
        {% if sizeof(LibC::ULong) == 8 %}
          return r.to_u64!
        {% else %}
          return r.to_u32!
        {% end %}
      end
    end

    CDoom.mus_delay -= 1

    r = midi_event
    {% if sizeof(LibC::ULong) == 8 %}
      return r.to_u64!
    {% else %}
      return r.to_u32!
    {% end %}
  end

  def self.i_tactile(on : LibC::Int, off : LibC::Int, total : LibC::Int)
  end

  def self.i_base_ticcmd : CDoom::Ticcmd*
    return pointerof(CDoom.emptycmd)
  end

  def self.i_get_heap_size : LibC::Int
    return CDoom.mb_used * 1024 * 1024
  end

  def self.i_zone_base(size : LibC::Int*) : CDoom::Byte*
    size.value = CDoom.mb_used * 1024 * 1024
    return CDoom.doom_malloc.call(size.value).as(CDoom::Byte*)
  end

  @@basetime = 0

  #
  # i_get_time
  # returns time in 1/70th second tics
  #
  def self.i_get_time : LibC::Int
    sec = 0
    usec = 0
    CDoom.doom_gettime.call(pointerof(sec), pointerof(usec))
    @@basetime = sec if @@basetime == 0
    newtics = (sec - @@basetime) * CDoom::TICRATE + usec * CDoom::TICRATE // 1000000
    return newtics
  end

  #
  # i_init
  #
  def self.i_init
    CDoom.i_init_sound
    CDoom.i_init_music
  end

  #
  # i_quit
  #
  def self.i_quit
    @@closing = true
    CDoom.d_quit_net_game
    CDoom.i_shutdown_sound
    CDoom.i_shutdown_music
    RAudio.close_audio_device
    CDoom.m_save_defaults
    CDoom.i_shutdown_graphics
    CDoom.doom_exit.call(0)
  end

  def self.i_wait_vbl(count : LibC::Int)
    now = Time.instant
    till = now + Time::Span.new(nanoseconds: (count * (1000000 // 70)) * 1000)
    while now < till
      now = Time.instant
      update_audio
    end
  end

  def self.i_alloc_low(length : LibC::Int) : CDoom::Byte*
    mem = CDoom.doom_malloc.call(length).as(CDoom::Byte*)
    CDoom.doom_memset(mem, 0, length)
    return mem
  end

  #
  # i_error
  #
  def self.i_error(error : LibC::Char*)
    # Message first.
    CDoom.doom_print.call(error) if !error.null?
    CDoom.doom_print.call("\n".to_unsafe)

    # Shutdown. Here might be other errors.
    CDoom.g_check_demo_status if CDoom.demorecording != 0

    CDoom.d_quit_net_game
    CDoom.i_shutdown_graphics

    CDoom.doom_exit.call(-1)
  end

  def self.i_shutdown_graphics
    @@screen_texture.try { |st| Raylib.unload_texture(st) }
    Raylib.close_window
  end

  def self.i_start_frame
  end

  def self.i_start_tic
  end

  def self.i_update_no_blit
    # what is this?
  end

  @@lasttic = 0

  def self.i_finish_update
    # draws little dots on the bottom of the screen
    if CDoom.devparm != 0
      i = CDoom.i_get_time
      tics = i - @@lasttic
      @@lasttic = i
      tics = 20 if tics > 20

      i = 0
      while i < tics * 2
        CDoom.screens[0][(CDoom::SCREENHEIGHT - 1) * CDoom::SCREENWIDTH + i] = 0xff
        i += 2
      end
      while i < 20 * 2
        CDoom.screens[0][(CDoom::SCREENHEIGHT - 1) * CDoom::SCREENWIDTH + i] = 0x0
        i += 2
      end
    end
  end

  def self.i_read_screen(scr : CDoom::Byte*)
    CDoom.doom_memcpy(scr, CDoom.screens[0], CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT)
  end

  def self.i_set_palette(palette : CDoom::Byte*)
    256.times do |i|
      CDoom.screen_palette[i*3] = CDoom.gammatable[CDoom.usegamma][palette.value] & ~3
      palette += 1
      CDoom.screen_palette[i*3 + 1] = CDoom.gammatable[CDoom.usegamma][palette.value] & ~3
      palette += 1
      CDoom.screen_palette[i*3 + 2] = CDoom.gammatable[CDoom.usegamma][palette.value] & ~3
      palette += 1
    end
  end

  def self.i_init_graphics
    CDoom.screens[0] = CDoom.doom_malloc.call(CDoom::SCREENWIDTH * CDoom::SCREENHEIGHT).as(UInt8*)

    Raylib.set_config_flags(Raylib::ConfigFlags::WindowResizable | Raylib::ConfigFlags::VSyncHint)
    Raylib.init_window(1024, 768, "LibDoom")
    Raylib.set_exit_key(Raylib::KeyboardKey::Null)
    Raylib.disable_cursor
    # Raylib.toggle_fullscreen
    # Raylib.set_target_fps(60)

    image = Raylib.gen_image_color(320, 200, Raylib::BLACK)
    @@screen_texture = Raylib.load_texture_from_image(image)
    Raylib.unload_image(image)
    Raylib.set_texture_filter(@@screen_texture.not_nil!, Raylib::TextureFilter::Point)
  end

  #
  # m_check_parm
  # Checks for the given parameter
  # in the program's command line arguments.
  # Returns the argument number (1 to argc-1)
  # or 0 if not present
  def self.m_check_parm(check : UInt8*) : Int32
    i = 1
    while i < CDoom.myargc
      return i if CDoom.doom_strcasecmp(check, CDoom.myargv[i]) == 0
      i += 1
    end

    return 0
  end

  def self.m_clear_box(box : CDoom::Fixed*)
    (box + CDoom::BOXTOP).value = Int32::MIN
    (box + CDoom::BOXRIGHT).value = Int32::MIN
    (box + CDoom::BOXLEFT).value = Int32::MAX
    (box + CDoom::BOXBOTTOM).value = Int32::MAX
  end

  def self.m_add_to_box(box : CDoom::Fixed*, x : CDoom::Fixed, y : CDoom::Fixed)
    if x < box[CDoom::BOXLEFT]
      (box + CDoom::BOXLEFT).value = x
    elsif x > box[CDoom::BOXRIGHT]
      (box + CDoom::BOXRIGHT).value = x
    end
    if y < box[CDoom::BOXBOTTOM]
      (box + CDoom::BOXBOTTOM).value = y
    elsif y > box[CDoom::BOXTOP]
      (box + CDoom::BOXTOP).value = y
    end
  end

  @@firsttime = 1
  @@cheat_xlate_table = uninitialized StaticArray(UInt8, 256)

  def self.cht_check_cheat(cht : CDoom::Cheatseq*, key : LibC::Char) : LibC::Int
    rc = 0

    if @@firsttime != 0
      @@firsttime = 0
      256.times { |i| @@cheat_xlate_table[i] = (scramble(i)).to_u8 }
    end

    if cht.value.p.null?
      cht.value.p = cht.value.sequence # initialize if first time
    end

    if cht.value.p.value == 0
      cht.value.p.value = key
      cht.value.p = cht.value.p + 1
    elsif @@cheat_xlate_table[key.to_u8!] == cht.value.p.value
      cht.value.p = cht.value.p + 1
    else
      cht.value.p = cht.value.sequence
    end

    if cht.value.p.value == 1
      cht.value.p = cht.value.p + 1
    elsif cht.value.p.value == 0xff # end of sequence character
      cht.value.p = cht.value.sequence
      rc = 1
    end

    return rc
  end

  def self.cht_get_param(cht : CDoom::Cheatseq*, buffer : LibC::Char*)
    p = cht.value.sequence
    while p.value != 1
      p += 1
    end
    p += 1

    c = 0

    loop do
      c = p.value
      buffer.value = c
      buffer += 1
      p.value = 0
      p += 1

      break unless c != 0 && p.value != 0xff
    end

    buffer.value = 0 if p.value == 0xff
  end

  def self.fixed_mul(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
    return ((a.to_i64 * b.to_i64) >> CDoom::FRACBITS).to_i32!
  end

  def self.fixed_div(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
    return (a ^ b) < 0 ? Int32::MIN : Int32::MAX if (doom_abs(a) >> 14) >= doom_abs(b)
    return CDoom.fixed_div2(a, b)
  end

  def self.fixed_div2(a : CDoom::Fixed, b : CDoom::Fixed) : CDoom::Fixed
    c = (a.to_f64 / b.to_f64) * CDoom::FRACUNIT

    CDoom.i_error("Error: fixed_div: divide by zero") if c >= 2147483648.0 || c < -2147483648.0
    return c.to_i32!
  end

  #
  # m_draw_custom_menu_text
  #  Draw several segments of patches to make up new text
  #
  def self.m_draw_custom_menu_text(name : LibC::Char*, x : LibC::Int, y : LibC::Int)
    CDoom.custom_texts_count.times do |i|
      custom_text = CDoom.menu_custom_texts.to_unsafe + i
      if CDoom.doom_strcmp(custom_text.value.name, name) == 0
        seg = custom_text.value.segs.to_unsafe
        while !seg.value.lump.null?
          lump = CDoom.w_cache_lump_name(seg.value.lump, CDoom::PU_CACHE).as(CDoom::Patch*)
          CDoom.v_draw_patch_rect_direct(x + seg.value.offx, y, 0, lump, seg.value.x, seg.value.w)
          seg += 1
        end
        break
      end
    end
  end

  #
  # m_read_save_strings
  # read the strings from the savegame files
  #
  def self.m_read_save_strings
    name = uninitialized StaticArray(UInt8, 256)

    CDoom::Loadenum::LoadEnd.value.times do |i|
      # if CDoom.m_check_parm("-cdrom") != 0
      #  doom_sprintf(name, "c:\\doomdata\\" + CDoom::SAVEGAMENAME + i + ".dsg")
      # else
      CDoom.doom_strcpy(name, CDoom::SAVEGAMENAME)
      CDoom.doom_concat(name, CDoom.doom_itoa(i, 10))
      CDoom.doom_concat(name, ".dsg")

      handle = CDoom.doom_open.call(name.to_unsafe, "r".to_unsafe)
      if handle.null?
        CDoom.doom_strcpy((CDoom.savegamestrings.to_unsafe + i).value.to_unsafe, CDoom::EMPTYSTRING)
        (CDoom.loadmenu.to_unsafe + i).value.status = 0
        next
      end
      count = CDoom.doom_read.call(handle, (CDoom.savegamestrings.to_unsafe + i).as(Void*), CDoom::SAVESTRINGSIZE)
      CDoom.doom_close.call(handle)
      (CDoom.loadmenu.to_unsafe + i).value.status = 1
    end
  end


  # m_draw_load & Cie
  def self.m_draw_load
    CDoom.v_draw_patch_direct(72, 28, 0, CDoom.w_cache_lump_name("M_LOADG", CDoom::PU_CACHE).as(CDoom::Patch*))
    CDoom::Loadenum::LoadEnd.value.times do |i|
      CDoom.m_draw_save_load_border(CDoom.loaddef.x, CDoom.loaddef.y + CDoom::LINEHEIGHT * i)
      CDoom.m_write_text(CDoom.loaddef.x, CDoom.loaddef.y + CDoom::LINEHEIGHT * i, CDoom.savegamestrings[i])
    end
  end

  #
  # Draw border for the savegame description
  #
  def self.m_draw_save_load_border(x : Int32, y : Int32)
    CDoom.v_draw_patch_direct(x - 8, y + 7, 0, CDoom.w_cache_lump_name("M_LSLEFT", CDoom::PU_CACHE).as(CDoom::Patch*))

    24.times do |i|
      CDoom.v_draw_patch_direct(x, y + 7, 0, CDoom.w_cache_lump_name("M_LSCNTR", CDoom::PU_CACHE).as(CDoom::Patch*))
      x += 8
    end

    CDoom.v_draw_patch_direct(x, y + 7, 0, CDoom.w_cache_lump_name("M_LSRGHT", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # User wants to load this game
  #
  def self.m_load_select(choice : Int32)
    name = uninitialized StaticArray(UInt8, 256)

    # if CDoom.m_check_parm("-cdrom")
    #  CDoom.doom_sprintf(name, "c:\\doomdata\\#{CDoom::SAVEGAMENAME}#{choice}.dsg")
    # else
    CDoom.doom_strcpy(name, CDoom::SAVEGAMENAME)
    CDoom.doom_concat(name, CDoom.doom_itoa(choice, 10))
    CDoom.doom_concat(name, ".dsg")

    CDoom.g_load_game(name)
    CDoom.m_clear_menus
  end

  #
  # Selected from DOOM menu
  #
  def self.m_load_game(choice : Int32)
    if CDoom.netgame != 0
      CDoom.m_start_message(CDoom::LOADNET, NULL_PROC, 0)
      return
    end

    CDoom.m_setup_next_menu(pointerof(CDoom.loaddef))
    CDoom.m_read_save_strings
  end

  #
  #  m_save_game & Cie.
  #
  def self.m_draw_save
    CDoom.v_draw_patch_direct(72, 28, 0, CDoom.w_cache_lump_name("M_SAVEG", CDoom::PU_CACHE).as(CDoom::Patch*))
    CDoom::Loadenum::LoadEnd.value.times do |i|
      CDoom.m_draw_save_load_border(CDoom.loaddef.x, CDoom.loaddef.y + CDoom::LINEHEIGHT * i)
      CDoom.m_write_text(CDoom.loaddef.x, CDoom.loaddef.y + CDoom::LINEHEIGHT * i, CDoom.savegamestrings[i])
    end

    if CDoom.save_string_enter != 0
      i = CDoom.m_string_width(CDoom.savegamestrings[CDoom.save_slot])
      CDoom.m_write_text(CDoom.loaddef.x + i, CDoom.loaddef.y + CDoom::LINEHEIGHT * CDoom.save_slot, "_")
    end
  end

  #
  # m_responder calls this when user is finished
  #
  def self.m_do_save(slot : Int32)
    CDoom.g_save_game(slot, CDoom.savegamestrings[slot])
    CDoom.m_clear_menus

    # PICK QUICKSAVE SLOT YET?
    CDoom.quick_save_slot = slot if CDoom.quick_save_slot == -2
  end

  #
  # User wants to save. Start string input for m_responder
  #
  def self.m_save_select(choice : Int32)
    # we are going to be intercepting all chars
    CDoom.save_string_enter = 1

    CDoom.save_slot = choice
    CDoom.doom_strcpy(CDoom.save_old_string, CDoom.savegamestrings[choice])
    if CDoom.doom_strcmp(CDoom.savegamestrings[choice], CDoom::EMPTYSTRING) == 0
      (CDoom.savegamestrings.to_unsafe + choice).value.to_unsafe.value = 0
    end
    CDoom.save_char_index = CDoom.doom_strlen(CDoom.savegamestrings[choice]).to_i32!
  end

  #
  # Selected from DOOM menu
  #
  def self.m_save_game(choice : Int32)
    if CDoom.usergame == 0
      CDoom.m_start_message(CDoom::SAVEDEAD, NULL_PROC, 0)
      return
    end

    return if CDoom.gamestate != CDoom::Gamestate::Level

    CDoom.m_setup_next_menu(pointerof(CDoom.savedef))
    CDoom.m_read_save_strings    
  end

  #
  # m_quicksave
  #
  def self.m_quicksave_response(ch : Int32)
    if ch == 'y'.ord
      CDoom.m_do_save(CDoom.quick_save_slot)
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
    end
  end

  def self.m_quicksave
    if CDoom.usergame == 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
      return
    end

    return if CDoom.gamestate != CDoom::Gamestate::Level

    if CDoom.quick_save_slot < 0
      CDoom.m_start_control_panel
      CDoom.m_read_save_strings
      CDoom.m_setup_next_menu(pointerof(CDoom.savedef))
      CDoom.quick_save_slot = -2 # means to pick a slot now
      return
    end
    CDoom.doom_strcpy(CDoom.tempstring, CDoom::QSPROMPT_1)
    CDoom.doom_concat(CDoom.tempstring, CDoom.savegamestrings[CDoom.quick_save_slot])
    CDoom.doom_concat(CDoom.tempstring, CDoom::QSPROMPT_2)
    CDoom.m_start_message(CDoom.tempstring, ->CDoom.m_quicksave_response(Int32), 1)
  end

  #
  # m_quickload
  #
  def self.m_quickload_response(ch : Int32)
    if ch == 'y'.ord
      CDoom.m_load_select(CDoom.quick_save_slot)
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
    end
  end

  def self.m_quickload
    if CDoom.netgame != 0
      CDoom.m_start_message(CDoom::QLOADNET, NULL_PROC, 0)
      return
    end

    if CDoom.quick_save_slot < 0
      CDoom.m_start_message(CDoom::QSAVESPOT, NULL_PROC, 0)
      return
    end
    CDoom.doom_strcpy(CDoom.tempstring, CDoom::QLPROMPT_1)
    CDoom.doom_concat(CDoom.tempstring, CDoom.savegamestrings[CDoom.quick_save_slot])
    CDoom.doom_concat(CDoom.tempstring, CDoom::QLPROMPT_2)
    CDoom.m_start_message(CDoom.tempstring, ->CDoom.m_quickload_response(Int32), 1)
  end

  #
  # Read This Menus
  # Had a "quick hack to fix romero bug"
  #
  def self.m_draw_readthis1
    CDoom.inhelpscreens = 1
    case CDoom.gamemode
    when CDoom::GameMode::Commercial
      CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP", CDoom::PU_CACHE).as(CDoom::Patch*))
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered, CDoom::GameMode::Retail
      CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP1", CDoom::PU_CACHE).as(CDoom::Patch*))
    end
  end

  #
  # Read This Menus - optional second page.
  #
  def self.m_draw_readthis2
    CDoom.inhelpscreens = 1
    case CDoom.gamemode
    when CDoom::GameMode::Retail, CDoom::GameMode::Commercial
      # This hack keeps us from having to change menus.
      CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("CREDIT", CDoom::PU_CACHE).as(CDoom::Patch*))
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered
      CDoom.v_draw_patch_direct(0, 0, 0, CDoom.w_cache_lump_name("HELP2", CDoom::PU_CACHE).as(CDoom::Patch*))
    end
  end

  #
  # Change Sfx & Music volumes
  #
  def self.m_draw_sound
    CDoom.v_draw_patch_direct(60, 38, 0, CDoom.w_cache_lump_name("M_SVOL", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.m_draw_thermo(CDoom.sounddef.x, CDoom.sounddef.y + CDoom::LINEHEIGHT * (CDoom::Soundenum::Sfxvol.value + 1),
    16, CDoom.snd_sfx_volume)

    CDoom.m_draw_thermo(CDoom.sounddef.x, CDoom.sounddef.y + CDoom::LINEHEIGHT * (CDoom::Soundenum::Musicvol.value + 1),
    16, CDoom.snd_music_volume)
  end

  def self.m_sound(choice : Int32)
    CDoom.m_setup_next_menu(pointerof(CDoom.sounddef))
  end

  def self.m_mouse_options(choice : Int32)
    CDoom.m_setup_next_menu(pointerof(CDoom.mouseoptionsdef))
  end

  def self.m_sfxvol(choice : Int32)
    case choice
    when 0
      CDoom.snd_sfx_volume -= 1 if CDoom.snd_sfx_volume > 0
    when 1
      CDoom.snd_sfx_volume += 1 if CDoom.snd_sfx_volume < 15
    end

    CDoom.s_set_sfx_volume(CDoom.snd_sfx_volume)
  end

  def self.m_musicvol(choice : Int32)
    case choice
    when 0
      CDoom.snd_music_volume -= 1 if CDoom.snd_music_volume > 0
    when 1
      CDoom.snd_music_volume += 1 if CDoom.snd_music_volume < 15
    end

    CDoom.s_set_sfx_volume(CDoom.snd_music_volume)
  end


  #
  # m_draw_mainmenu
  #
  def self.m_draw_mainmenu
    CDoom.v_draw_patch_direct(94, 2, 0, CDoom.w_cache_lump_name("M_DOOM", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  #
  # m_newgame
  #
  def self.m_draw_newgame
    CDoom.v_draw_patch_direct(96, 14, 0, CDoom.w_cache_lump_name("M_NEWG", CDoom::PU_CACHE).as(CDoom::Patch*))
    CDoom.v_draw_patch_direct(54, 38, 0, CDoom.w_cache_lump_name("M_SKILL", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_new_game(choice : Int32)
    if CDoom.netgame != 0 && CDoom.demoplayback == 0
      CDoom.m_start_message(CDoom::NEWGAME, NULL_PROC, 0)
      return
    end

    if CDoom.gamemode == CDoom::GameMode::Commercial
      CDoom.m_setup_next_menu(pointerof(CDoom.newdef))
    else
      CDoom.m_setup_next_menu(pointerof(CDoom.epidef))
    end
  end

  #
  # m_episode
  #
  def self.m_draw_episode
    CDoom.v_draw_patch_direct(54, 38, 0, CDoom.w_cache_lump_name("M_EPISOD", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_verify_nightmare(ch : Int32)
    return if ch != 'y'.ord

    CDoom.g_defered_init_new(CDoom::Skill::Nightmare, CDoom.epi + 1, 1)
    CDoom.m_clear_menus
  end

  def self.m_choose_skill(choice : Int32)
    if choice == CDoom::Skill::Nightmare.value
      CDoom.m_start_message(CDoom::NIGHTMARE, ->CDoom.m_verify_nightmare(Int32), 1)
      return
    end

    CDoom.g_defered_init_new(CDoom::Skill.new(choice), CDoom.epi + 1, 1)
    CDoom.m_clear_menus
  end

  def self.m_episode(choice : Int32)
    if CDoom.gamemode == CDoom::GameMode::Shareware && choice != 0
      CDoom.m_start_message(CDoom::SWSTRING, NULL_PROC, 0)
      CDoom.m_setup_next_menu(pointerof(CDoom.readdef1))
      return
    end

    # Yet another hack...
    if CDoom.gamemode == CDoom::GameMode::Registered && choice > 2
      CDoom.doom_print.call("m_episode: 4th episode requires Ultimate DOOM\n".to_unsafe)
      choice = 0
    end

    CDoom.epi = choice
    CDoom.m_setup_next_menu(pointerof(CDoom.newdef))
  end

  #
  # m_options
  #
  def self.m_draw_options
    CDoom.v_draw_patch_direct(108, 15, 0, CDoom.w_cache_lump_name("M_OPTTTL", CDoom::PU_CACHE).as(CDoom::Patch*))
    
    CDoom.v_draw_patch_direct(CDoom.optionsdef.x + 120, CDoom.optionsdef.y + CDoom::LINEHEIGHT * CDoom::OptionsEnum::Messages.value, 0, CDoom.w_cache_lump_name(CDoom.msg_names[CDoom.show_messages], CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch_direct(CDoom.optionsdef.x + 131, CDoom.optionsdef.y + CDoom::LINEHEIGHT * CDoom::OptionsEnum::Crosshairopt.value, 0, CDoom.w_cache_lump_name(CDoom.msg_names[CDoom.crosshair], CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch_direct(CDoom.optionsdef.x + 147, CDoom.optionsdef.y + CDoom::LINEHEIGHT * CDoom::OptionsEnum::Alwaysrunopt.value, 0, CDoom.w_cache_lump_name(CDoom.msg_names[CDoom.always_run], CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.m_draw_thermo(CDoom.optionsdef.x, CDoom.optionsdef.y + CDoom::LINEHEIGHT * (CDoom::OptionsEnum::Scrnsize.value + 1),
    9, CDoom.screen_size)
  end

  def self.m_draw_mouse_options
    CDoom.m_draw_custom_menu_text("TXT_MOPT", 74, 45)

    CDoom.v_draw_patch_direct(CDoom.mouseoptionsdef.x + 149, CDoom.mouseoptionsdef.y + CDoom::LINEHEIGHT * CDoom::MouseoptionsEnum::Mousemov.value, 0, CDoom.w_cache_lump_name(CDoom.msg_names[CDoom.mousemove], CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.m_draw_thermo(CDoom.mouseoptionsdef.x, CDoom.mouseoptionsdef.y + CDoom::LINEHEIGHT * (CDoom::MouseoptionsEnum::Mousesens.value + 1),
    10, CDoom.mouse_sensitivity)
  end

  def self.m_options(choice : Int32)
    CDoom.m_setup_next_menu(pointerof(CDoom.optionsdef))
  end

  #
  # Toggle messages on/off
  #
  def self.m_change_messages(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    CDoom.show_messages = 1 - CDoom.show_messages

    if CDoom.show_messages == 0
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom::MSGOFF
    else
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom::MSGON
    end

    CDoom.message_dontfuckwithme = 1
  end


  #
  # Toggle crosshair on/off
  #
  def self.m_change_crosshair(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    CDoom.crosshair = 1 - CDoom.crosshair

    if CDoom.crosshair == 0
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom::CROSSOFF
    else
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom::CROSSON
    end

    CDoom.message_dontfuckwithme = 1
  end


  #
  # Toggle always-run on/off
  #
  def self.m_change_alwaysrun(choice : Int32)
    # warning: unused parameter `choice : Int32'
    choice = 0
    CDoom.always_run = 1 - CDoom.always_run

    if CDoom.always_run == 0
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom::ALWAYSRUNOFF
    else
      (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom::ALWAYSRUNON
    end

    CDoom.message_dontfuckwithme = 1
  end


  #
  # m_endgame
  #
  def self.m_endgame_response(ch : Int32)
    return if ch != 'y'.ord

    CDoom.current_menu.value.last_on = CDoom.item_on
    CDoom.m_clear_menus
    CDoom.d_start_title
  end

  def self.m_endgame(choice : Int32)
    choice = 0
    if CDoom.usergame == 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_oof)
      return
    end

    if CDoom.netgame != 0
      CDoom.m_start_message(CDoom::NETEND, NULL_PROC, 0)
      return
    end

    CDoom.m_start_message(CDoom::ENDGAME, ->CDoom.m_endgame_response(Int32), 1)
  end


  #
  # m_readthis
  #
  def self.m_readthis(choice : Int32)
    choice = 0
    CDoom.m_setup_next_menu(pointerof(CDoom.readdef1))
  end

  def self.m_readthis2(choice : Int32)
    choice = 0
    CDoom.m_setup_next_menu(pointerof(CDoom.readdef2))
  end

  def self.m_finish_readthis(choice : Int32)
    choice = 0
    CDoom.m_setup_next_menu(pointerof(CDoom.maindef))
  end


  #
  # m_quitdoom
  #
  def self.m_quit_response(ch : Int32)
    return if ch != 'y'.ord
    if CDoom.netgame == 0
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.s_start_sound(Pointer(Void).null, CDoom.quitsounds2[(CDoom.gametic >> 2) & 7])
      else
        CDoom.s_start_sound(Pointer(Void).null, CDoom.quitsounds[(CDoom.gametic >> 2) & 7])
      end
      CDoom.i_wait_vbl(105)
    end
    CDoom.i_quit
  end

  def self.m_quitdoom(choice : Int32)
    # We pick index 0 which is language sensitive,
    #  or one at random, between 1 and maximum number.
    if CDoom.language != CDoom::Language::English
      CDoom.doom_strcpy(CDoom.endstring, CDoom.doom1_endmsg[0])
    else
      if CDoom.gamemode == CDoom::GameMode::Commercial
        CDoom.doom_strcpy(CDoom.endstring, CDoom.doom2_endmsg[CDoom.gametic % (sizeof(typeof(CDoom.doom2_endmsg)) // sizeof(UInt8*) - 1) + 1])
      else
        CDoom.doom_strcpy(CDoom.endstring, CDoom.doom1_endmsg[CDoom.gametic % (sizeof(typeof(CDoom.doom1_endmsg)) // sizeof(UInt8*) - 1) + 1])
      end
    end
    CDoom.doom_concat(CDoom.endstring, "\n\n" + CDoom::DOSY)

    CDoom.m_start_message(CDoom.endstring, ->CDoom.m_quit_response(Int32), 1)
  end


  def self.m_change_sensitivity(choice : Int32)
    case choice
    when 0
      CDoom.mouse_sensitivity -= 1 if CDoom.mouse_sensitivity > 0
    when 1
      CDoom.mouse_sensitivity += 1 if CDoom.mouse_sensitivity < 9
    end
  end

  def self.m_mouse_move(choice : Int32)
    choice = 0
    CDoom.mousemove = 1 - CDoom.mousemove
  end

  def self.m_size_display(choice : Int32)
    case choice
    when 0
      if CDoom.screen_size > 0
        CDoom.screenblocks -= 1
        CDoom.screen_size -= 1
      end
    when 1
      if CDoom.screen_size < 8
        CDoom.screenblocks += 1
        CDoom.screen_size += 1
      end
    end

    CDoom.r_set_view_size(CDoom.screenblocks, CDoom.detail_level)
  end


  #
  # Menu Methods
  #
  def self.m_draw_thermo(x : LibC::Int, y : LibC::Int, therm_width : LibC::Int, therm_dot : LibC::Int)
    xx = x
    CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERML", CDoom::PU_CACHE).as(CDoom::Patch*))
    xx += 8
    therm_width.times do |i|
    CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERMM", CDoom::PU_CACHE).as(CDoom::Patch*))
      xx += 8
    end
    CDoom.v_draw_patch_direct(xx, y, 0, CDoom.w_cache_lump_name("M_THERMR", CDoom::PU_CACHE).as(CDoom::Patch*))

    CDoom.v_draw_patch_direct((x + 8) + therm_dot * 8, y, 0, CDoom.w_cache_lump_name("M_THERMO", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_empty_cell(menu : CDoom::Menu*, item : Int32)
    CDoom.v_draw_patch_direct(menu.value.x - 10, menu.value.y + item * CDoom::LINEHEIGHT - 1, 0, 
    CDoom.w_cache_lump_name("M_CELL1", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_draw_selcell(menu : CDoom::Menu*, item : Int32)
    CDoom.v_draw_patch_direct(menu.value.x - 10, menu.value.y + item * CDoom::LINEHEIGHT - 1, 0, 
    CDoom.w_cache_lump_name("M_CELL2", CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_start_message(string : LibC::Char*, routine : Proc(Int32, Nil), input : CDoom::DoomBool)
    CDoom.message_last_menu_active = CDoom.menuactive
    CDoom.message_to_print = 1
    CDoom.message_string = string
    CDoom.message_routine = routine
    CDoom.message_needs_input = input
    CDoom.menuactive = 1
  end

  def self.m_stop_message
    CDoom.menuactive = CDoom.message_last_menu_active
    CDoom.message_to_print = 0
  end


  #
  # Find string width from hu_font chars
  #
  def self.m_string_width(string : UInt8*) : Int32
    w = 0

    CDoom.doom_strlen(string).times do |i|
      c = CDoom.doom_toupper(string[i]) - CDoom::HU_FONTSTART
      if c < 0 || c >= CDoom::HU_FONTSIZE
        w += 4
      else
        w += CDoom.hu_font[c].value.width.to_i16!
      end
    end

    return w
  end

  #
  # Find string height from hu_font chars
  #
  def self.m_string_height(string : UInt8*) : Int32
    height = CDoom.hu_font[0].value.height.to_i16!.to_i32

    h = height
    CDoom.doom_strlen(string).times do |i|
      h += height if string[i] == '\n'.ord
    end

    return h
  end

  #
  # Write a string using the hu_font
  #
  def self.m_write_text(x : Int32, y : Int32, string : UInt8*)
    ch = string
    cx = x
    cy = y

    while true
      c = ch.value
      ch += 1
      break if c == 0
      if c == '\n'.ord
        cx = x
        cy += 12
        next
      end

      c = doom_toupper(c) - CDoom::HU_FONTSTART
      if c < 0 || c >= CDoom::HU_FONTSIZE
        cx += 4
        next
      end

      w = CDoom.hu_font[c].value.width.to_i16!
      break if cx + w > CDoom::SCREENWIDTH
      CDoom.v_draw_patch_direct(cx, cy, 0, CDoom.hu_font[c])
      cx += w
    end
  end

  @@joywait = 0
  @@mousewait = 0
  @@mousey = 0
  @@lasty = 0
  @@mousex = 0
  @@lastx = 0
  #
  # m_responder
  #
  def self.m_responder(ev : CDoom::Event*) : CDoom::DoomBool
    ch = -1

    if ev.value.type == CDoom::Evtype::Joystick && @@joywait < CDoom.i_get_time
      if ev.value.data3 == -1
        ch = CDoom::KEY_UPARROW
        @@joywait = CDoom.i_get_time + 5
      elsif ev.value.data3 == 1
        ch = CDoom::KEY_DOWNARROW
        @@joywait = CDoom.i_get_time + 5
      end

      if ev.value.data2 == -1
        ch = CDoom::KEY_LEFTARROW
        @@joywait = CDoom.i_get_time + 2
      elsif ev.value.data2 == 1
        ch = CDoom::KEY_RIGHTARROW
        @@joywait = CDoom.i_get_time + 2
      end

      if ev.value.data1 & 1 != 0
        ch = CDoom::KEY_ENTER
                @@joywait = CDoom.i_get_time + 5
      end
      if ev.value.data1 & 2 != 0
        ch = CDoom::KEY_BACKSPACE
        @@joywait = CDoom.i_get_time + 5
      end
    else
      if ev.value.type == CDoom::Evtype::Mouse && @@mousewait < CDoom.i_get_time
        @@mousey += ev.value.data3
        if @@mousey < @@lasty - 30
          ch = CDoom::KEY_DOWNARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lasty -= 30
          @@mousey = @@lasty
        elsif @@mousey > @@lasty + 30
          ch = CDoom::KEY_UPARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lasty += 30
          @@mousey = @@lasty
        end

        @@mousex += ev.value.data2
        if @@mousex < @@lastx - 30
          ch = CDoom::KEY_LEFTARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lastx -= 30
          @@mousex = @@lastx
        elsif @@mousex > @@lastx + 30
          ch = CDoom::KEY_RIGHTARROW
          @@mousewait = CDoom.i_get_time + 5
          @@lastx += 30
          @@mousex = @@lastx
        end

        if ev.value.data1 & 1 != 0
          ch = CDoom::KEY_ENTER
          @@mousewait = CDoom.i_get_time + 15
        end

        if ev.value.data1 & 2 != 0
          ch = CDoom::KEY_BACKSPACE
          @@mousewait = CDoom.i_get_time + 15
        end
      else
        ch = ev.value.data1 if ev.value.type == CDoom::Evtype::Keydown
      end
    end

    return 0 if ch == -1

    # Save Game string input
    if CDoom.save_string_enter != 0
      case ch
      when CDoom::KEY_BACKSPACE
        if CDoom.save_char_index > 0
          CDoom.save_char_index -= 1
          ((CDoom.savegamestrings.to_unsafe + CDoom.save_slot).value.to_unsafe + CDoom.save_char_index).value = 0
        end
      when CDoom::KEY_ESCAPE
        CDoom.save_string_enter = 0
        CDoom.doom_strcpy(CDoom.savegamestrings[CDoom.save_slot].to_unsafe, CDoom.save_old_string)
      when CDoom::KEY_ENTER
        CDoom.save_string_enter = 0
        CDoom.m_do_save(CDoom.save_slot) if CDoom.savegamestrings[CDoom.save_slot][0] != 0
      else
        ch = CDoom.doom_toupper(ch)
        unless ch != 32 && (ch - CDoom::HU_FONTSTART < 0 || ch - CDoom::HU_FONTSTART >= CDoom::HU_FONTSIZE)
            if ch >= 32 && ch <= 127 && 
              CDoom.save_char_index < CDoom::SAVESTRINGSIZE - 1 &&
              CDoom.m_string_width(CDoom.savegamestrings[CDoom.save_slot]) <
              (CDoom::SAVESTRINGSIZE - 2) * 8
              ((CDoom.savegamestrings.to_unsafe + CDoom.save_slot).value.to_unsafe + CDoom.save_char_index).value = ch.to_u8!
              CDoom.save_char_index += 1
              ((CDoom.savegamestrings.to_unsafe + CDoom.save_slot).value.to_unsafe + CDoom.save_char_index).value = 0
            end
        end
      end

      return 1
    end

    # Take care of any messages that need input
    if CDoom.message_to_print != 0
      return 0 if CDoom.message_needs_input != 0 &&
      !(ch == ' '.ord || ch == 'n'.ord || ch =='y'.ord || ch == CDoom::KEY_ESCAPE)

      CDoom.menuactive = CDoom.message_last_menu_active
      CDoom.message_to_print = 0
      CDoom.message_routine.call(ch) unless CDoom.message_routine.pointer.null?

      CDoom.menuactive = 0
      CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
      return 1
    end

    if CDoom.devparm != 0 && ch == CDoom::KEY_F1
      CDoom.g_screenshot
      return 1
    end


    # F-Keys
    if CDoom.menuactive == 0
      case ch
      when CDoom::KEY_MINUS # Screen size down
        return 0 if CDoom.automapactive != 0 || CDoom.chat_on != 0
        CDoom.m_size_display(0)
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        return 1
      when CDoom::KEY_EQUALS # Screen size up
        return 0 if CDoom.automapactive != 0 || CDoom.chat_on != 0
        CDoom.m_size_display(1)
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        return 1
      when CDoom::KEY_F1 # Help key
        CDoom.m_start_control_panel

        if CDoom.gamemode == CDoom::GameMode::Retail
          CDoom.current_menu = pointerof(CDoom.readdef2)
        else
          CDoom.current_menu = pointerof(CDoom.readdef1)
        end

        CDoom.item_on = 0
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      when CDoom::KEY_F2 # Save
        CDoom.m_start_control_panel
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        CDoom.m_save_game(0)
        return 1
      when CDoom::KEY_F3 # Load
        CDoom.m_start_control_panel
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        CDoom.m_load_game(0)
        return 1
      when CDoom::KEY_F4 # Sound Volume
        CDoom.m_start_control_panel
        CDoom.current_menu = pointerof(CDoom.sounddef)
        CDoom.item_on = CDoom::Soundenum::Sfxvol
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      when CDoom::KEY_F5
        CDoom.m_change_crosshair(0)
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      when CDoom::KEY_F6 # Quicksave
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        CDoom.m_quicksave
        return 1
      when CDoom::KEY_F7 # End game
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        CDoom.m_endgame(0)
        return 1
      when CDoom::KEY_F8 # Toggle messages
        CDoom.m_change_messages(0)
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        return 1
      when CDoom::KEY_F9 # Quickload
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        CDoom.m_quickload
        return 1
      when CDoom::KEY_F10 # Quit DOOM
        CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
        CDoom.m_quitdoom(0)
        return 1
      when CDoom::KEY_F11 # gamma toggle
        CDoom.usegamma += 1
        CDoom.usegamma = 0 if CDoom.usegamma > 4
        (CDoom.players.to_unsafe + CDoom.consoleplayer).value.message = CDoom.gammamsg[CDoom.usegamma]
        CDoom.i_set_palette(CDoom.w_cache_lump_name("PLAYPAL", CDoom::PU_CACHE).as(UInt8*))
        return 1
      end
    end

    # Pop-up menu?
    if CDoom.menuactive == 0
      if ch == CDoom::KEY_ESCAPE
      CDoom.m_start_control_panel
              CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
      return 1
      end
      return 0
    end

    # Keys usable within menu
    case ch
    when CDoom::KEY_DOWNARROW
      loop do
        CDoom.item_on = CDoom.item_on + 1 > CDoom.current_menu.value.numitems - 1 ? 0 : CDoom.item_on + 1
              CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
        break unless CDoom.current_menu.value.menuitems[CDoom.item_on].status == -1
      end
      return 1
    when CDoom::KEY_UPARROW
      loop do
        CDoom.item_on = CDoom.item_on == 0 ? CDoom.current_menu.value.numitems - 1 : CDoom.item_on - 1
              CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
        break unless CDoom.current_menu.value.menuitems[CDoom.item_on].status == -1
      end
      return 1
    when CDoom::KEY_LEFTARROW
      if !CDoom.current_menu.value.menuitems[CDoom.item_on].routine.pointer.null? &&
        CDoom.current_menu.value.menuitems[CDoom.item_on].status == 2
              CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
              CDoom.current_menu.value.menuitems[CDoom.item_on].routine.call(0)
      end
      return 1
    when CDoom::KEY_RIGHTARROW
      if !CDoom.current_menu.value.menuitems[CDoom.item_on].routine.pointer.null? &&
        CDoom.current_menu.value.menuitems[CDoom.item_on].status == 2
              CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
              CDoom.current_menu.value.menuitems[CDoom.item_on].routine.call(1)
      end
      return 1
    when CDoom::KEY_ENTER
      if !CDoom.current_menu.value.menuitems[CDoom.item_on].routine.pointer.null? &&
        CDoom.current_menu.value.menuitems[CDoom.item_on].status != 0
        CDoom.current_menu.value.last_on = CDoom.item_on
        if CDoom.current_menu.value.menuitems[CDoom.item_on].status == 2
          CDoom.current_menu.value.menuitems[CDoom.item_on].routine.call(1)
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_stnmov)
        else
          CDoom.current_menu.value.menuitems[CDoom.item_on].routine.call(CDoom.item_on.to_i32)
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pistol)
        end
      end
      return 1
    when CDoom::KEY_ESCAPE
      CDoom.current_menu.value.last_on = CDoom.item_on
      CDoom.m_clear_menus
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchx)
      return 1
    when CDoom::KEY_BACKSPACE
      CDoom.current_menu.value.last_on = CDoom.item_on
      if !CDoom.current_menu.value.prev_menu.null?
        CDoom.current_menu = CDoom.current_menu.value.prev_menu
        CDoom.item_on = CDoom.current_menu.value.last_on
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_swtchn)
      end
      return 1
    else
      i = CDoom.item_on + 1
      while i < CDoom.current_menu.value.numitems
        if CDoom.current_menu.value.menuitems[i].alpha_key == ch
          CDoom.item_on = i
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
          return 1
        end
        i += 1
      end
      (CDoom.item_on + 1).times do |i|
        if CDoom.current_menu.value.menuitems[i].alpha_key == ch
          CDoom.item_on = i
          CDoom.s_start_sound(Pointer(Void).null, CDoom::Sfxenum::SFX_pstop)
          return 1
        end
      end
    end
    
    return 0
  end


  def self.m_start_control_panel
     # intro might call this repeatedly
     return if CDoom.menuactive != 0

     CDoom.menuactive = 1
     CDoom.current_menu = pointerof(CDoom.maindef) # JDC
     CDoom.item_on = CDoom.current_menu.value.last_on # JDC
  end

  @@x = 0
  @@y = 0
  #
  # m_drawer
  # Called after the view has been rendered,
  # but before it has been blitted.
  #
  def self.m_drawer
    string = uninitialized StaticArray(UInt8, 40)
    i = 0
    CDoom.inhelpscreens = 0

    # Horiz. & Vertically center string and print it.
    if CDoom.message_to_print != 0
      start = 0
      @@y = 100 - CDoom.m_string_height(CDoom.message_string) // 2
      while (CDoom.message_string + start).value != 0
        i = 0
        while i < CDoom.doom_strlen(CDoom.message_string + start)
          if (CDoom.message_string + start + i).value == '\n'.ord
            CDoom.doom_memset(string, 0, 40)
            CDoom.doom_strncpy(string, CDoom.message_string + start, i)
            start += i + 1
            break
          end
          i += 1
        end

        if i == CDoom.doom_strlen(CDoom.message_string + start)
          CDoom.doom_strcpy(string, CDoom.message_string + start)
          start += i
        end

        @@x = 160 - CDoom.m_string_width(string) // 2
        CDoom.m_write_text(@@x, @@y, string)
        @@y += CDoom.hu_font[0].value.height.to_i16!
      end
      return
    end

    return if CDoom.menuactive == 0

    # Darken background so the menu is more readable.
    CDoom.current_menu.value.routine.call unless CDoom.current_menu.value.routine.pointer.null?

    # DRAW MENU
    @@x = CDoom.current_menu.value.x.to_i32
    @@y = CDoom.current_menu.value.y.to_i32
    max = CDoom.current_menu.value.numitems

    max.times do |i|
      menuitem = (CDoom.current_menu.value.menuitems + i)
      if menuitem.value.name[0] != 0
        if CDoom.doom_strncmp(menuitem.value.name, "TXT_", 4) == 0
          CDoom.m_draw_custom_menu_text(menuitem.value.name, @@x, @@y)
        else
          CDoom.v_draw_patch_direct(@@x, @@y, 0, CDoom.w_cache_lump_name(menuitem.value.name, CDoom::PU_CACHE).as(CDoom::Patch*))
        end
      end
      @@y += CDoom::LINEHEIGHT
    end

    # DRAW SKULL
    CDoom.v_draw_patch_direct(@@x + CDoom::SKULLXOFF, CDoom.current_menu.value.y - 5 + CDoom.item_on * CDoom::LINEHEIGHT, 0, 
    CDoom.w_cache_lump_name(CDoom.skull_name[CDoom.which_skull], CDoom::PU_CACHE).as(CDoom::Patch*))
  end

  def self.m_clear_menus
    CDoom.menuactive = 0
  end

  def self.m_setup_next_menu(menudef : CDoom::Menu*)
    CDoom.current_menu = menudef
    CDoom.item_on = CDoom.current_menu.value.last_on
  end

  def self.m_ticker
    CDoom.skull_anim_counter &-= 1
    if CDoom.skull_anim_counter <= 0
      CDoom.which_skull ^= 1
      CDoom.skull_anim_counter = 8
    end
  end

  def self.m_init
    CDoom.current_menu = pointerof(CDoom.maindef)
    CDoom.menuactive = 0
    CDoom.item_on = CDoom.current_menu.value.last_on
    CDoom.which_skull = 0
    CDoom.skull_anim_counter = 10
    CDoom.screen_size = CDoom.screenblocks - 3
    CDoom.message_to_print = 0
    CDoom.message_string = Pointer(UInt8).null
    CDoom.message_last_menu_active = CDoom.menuactive
    CDoom.quick_save_slot = -1

    # Here we could catch other version dependencies,
    #  like HELP1/2, and four episodes.

    case CDoom.gamemode
    when CDoom::GameMode::Commercial
      # This is used because DOOM 2 had only one HELP
            #  page. I use CREDIT as second page now, but
            #  kept this hack for educational purposes.
            (CDoom.mainmenu.to_unsafe + CDoom::Mainenum::Readthis.value).value = CDoom.mainmenu[CDoom::Mainenum::Quitdoom.value]
            CDoom.maindef.numitems = CDoom.maindef.numitems - 1
            CDoom.maindef.y = CDoom.maindef.y + 8
            CDoom.newdef.prev_menu = pointerof(CDoom.maindef)
            CDoom.readdef1.routine = ->CDoom.m_draw_readthis1
            CDoom.readdef1.x = 330
            CDoom.readdef1.y = 165
            CDoom.readmenu1.to_unsafe.value.routine = ->CDoom.m_finish_readthis(Int32)
    when CDoom::GameMode::Shareware, CDoom::GameMode::Registered
      # Episode 2 and 3 are handled,
      #  branching to an ad screen.
      #
      # We need to remove the fourth episode.
      CDoom.epidef.numitems = CDoom.epidef.numitems - 1
    when CDoom::GameMode::Retail
      # We are fine.
    end
  end

  
end
