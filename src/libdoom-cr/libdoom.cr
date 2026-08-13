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
  CDoom.endmsg[0] = CDoom::QUITMSG.to_unsafe
  CDoom.endmsg[1] = "please don't leave, there's more\ndemons to toast!".to_unsafe
  CDoom.endmsg[2] = "let's beat it -- this is turning\ninto a bloodbath!".to_unsafe
  CDoom.endmsg[3] = "i wouldn't leave if i were you.\ndos is much worse.".to_unsafe
  CDoom.endmsg[4] = "you're trying to say you like dos\nbetter than me, right?".to_unsafe
  CDoom.endmsg[5] = "don't leave yet -- there's a\ndemon around that corner!".to_unsafe
  CDoom.endmsg[6] = "ya know, next time you come in here\ni'm gonna toast ya.".to_unsafe
  CDoom.endmsg[7] = "go ahead and leave. see if i care.".to_unsafe

  # QuitDOOM II messages
  CDoom.endmsg[8] = "you want to quit?\nthen, thou hast lost an eighth!".to_unsafe
  CDoom.endmsg[9] = "don't go now, there's a \ndimensional shambler waiting\nat the dos prompt!".to_unsafe
  CDoom.endmsg[10] = "get outta here and go back\nto your boring programs.".to_unsafe
  CDoom.endmsg[11] = "if i were your boss, i'd \n deathmatch ya in a minute!".to_unsafe
  CDoom.endmsg[12] = "look, bud. you leave now\nand you forfeit your body count!".to_unsafe
  CDoom.endmsg[13] = "just leave. when you come\nback, i'll be waiting with a bat.".to_unsafe
  CDoom.endmsg[14] = "you're lucky i don't smack\nyou for thinking about leaving.".to_unsafe

  # FinalDOOM?
  CDoom.endmsg[15] = "fuck you, pussy!\nget the fuck out!".to_unsafe
  CDoom.endmsg[16] = "you quit and i'll jizz\nin your cystholes!".to_unsafe
  CDoom.endmsg[17] = "if you leave, i'll make\nthe lord drink my jizz.".to_unsafe
  CDoom.endmsg[18] = "hey, ron! can we say\n'fuck' in the game?".to_unsafe
  CDoom.endmsg[19] = "i'd leave: this is just\nmore monsters and levels.\nwhat a load.".to_unsafe
  CDoom.endmsg[20] = "suck it down, asshole!\nyou're a fucking wimp!".to_unsafe
  CDoom.endmsg[21] = "don't quit now! we're \nstill spending your money!".to_unsafe

  # Internal debug. Different style, too.
  CDoom.endmsg[22] = "THIS IS NO MESSAGE!\nPage intentionally left blank.".to_unsafe

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

  def self.am_draw_line_character(lineguy : CDoom::Mline*,
                                  lineguylines : LibC::Int,
                                  scale : CDoom::Fixed,
                                  angle : CDoom::Angle,
                                  color : LibC::Int,
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

  def self.am_draw_things(colors : LibC::Int, colorrange : LibC::Int)
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
    CDoom.players[CDoom.consoleplayer].playerstate = CDoom::Playerstate::PST_LIVE # not reborn
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
      CDoom.devparm = 1
      CDoom.d_add_file(CDoom::DEVDATA + "doom1.wad")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/texture1.lmp")
      CDoom.d_add_file(CDoom::DEVMAPS + "data_se/pnames.lmp")
      CDoom.doom_strcpy(CDoom.basedefault, CDoom::DEVDATA + "default.cfg")
      return
    end

    if CDoom.m_check_parm("-regdev") != 0
      CDoom.gamemode = CDoom::GameMode::Registered
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
      CDoom.d_add_file(doom2wad)
      return
    end

    if !(f = CDoom.doom_open.call(plutoniawad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.d_add_file(plutoniawad)
      return
    end

    if !(f = CDoom.doom_open.call(tntwad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Commercial
      CDoom.d_add_file(tntwad)
      return
    end

    if !(f = CDoom.doom_open.call(doomuwad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Retail
      CDoom.d_add_file(doomuwad)
      return
    end

    if !(f = CDoom.doom_open.call(doomwad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Registered
      CDoom.d_add_file(doomwad)
      return
    end

    if !(f = CDoom.doom_open.call(doom1wad, "rb".to_unsafe)).null?
      CDoom.doom_close.call(f)
      CDoom.gamemode = CDoom::GameMode::Shareware
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
        moreargs = Pointer(UInt8*).malloc(20)

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
    file = Pointer(UInt8).malloc(256)

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
      CDoom.doom_strcpy(CDoom.title, "                         " + "DOOM 2: Hell on Earth v")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION // 100, 10))
      CDoom.doom_concat(CDoom.title, ".")
      CDoom.doom_concat(CDoom.title, CDoom.doom_itoa(CDoom::VERSION % 100, 10))
      CDoom.doom_concat(CDoom.title, "                           ")
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
      filename = Pointer(UInt8).malloc(20)
      CDoom.doom_strcpy(filename, "debug")
      CDoom.doom_concat(filename, CDoom.doom_itoa(CDoom.consoleplayer, 10))
      CDoom.doom_concat(filename, ".txt")

      CDoom.doom_print.call("debug output to: ".to_unsafe)
      CDoom.doom_print.call(filename)
      CDoom.doom_print.call("\n".to_unsafe)
      CDoom.debugfile = CDoom.doom_open.call(filename, "w".to_unsafe)
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
        CDoom.players[CDoom.consoleplayer].message = CDoom.exitmsg
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

      return if CDoom.singletics != 0 # singletic update is syncronous

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
    CDoom.doom_memset(gotinfo, 0, gotinfo.size * sizeof(CDoom::DoomBool))

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

    if CDoom.finalestage == 0 # && CDoom.finalecount > CDoom.doom_strlen(CDoom.finaletext) * CDoom::TEXTSPEED + CDoom::TEXTWAIT
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

    name = Pointer(UInt8).malloc(10)

    CDoom.doom_strcpy(name, "END")
    CDoom.doom_concat(name, CDoom.doom_itoa(stage, 10))
    CDoom.v_draw_patch((CDoom::SCREENWIDTH - 13 * 8) // 2, (CDoom::SCREENHEIGHT - 8 * 8) // 2, 0, CDoom.w_cache_lump_name(name, CDoom::PU_CACHE).as(CDoom::Patch*))
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
    CDoom.doom_memcpy(cmd, base, sizeof(CDoom::Ticcmd))

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
    if  bstrafe != CDoom.dclickstate2 && CDoom.dclicktime2 > 1
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

    forward += CDoom.mousey if CDoom.mousemove != 0
    if strafe != 0
    side += CDoom.mousex * 2
    else
      cmd.value.angleturn = cmd.value.angleturn - CDoom.mousex * 0x8
    end

    CDoom.mousex = 0
    CDoom.mousey = 0

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
end
