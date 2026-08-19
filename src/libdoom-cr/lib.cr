macro doom_abs(x)
  (({{x}}) < 0 ? -({{x}}) : ({{x}}))
end

macro scramble(a)
  (((({{a}})&1)<<7) + ((({{a}})&2)<<5) + (({{a}})&4) + ((({{a}})&8)<<1) \
 + ((({{a}})&16)>>1) + (({{a}})&32) + ((({{a}})&64)>>5) + ((({{a}})&128)>>7))
end

#
# This is used to get the local FILE:LINE info from CPP
# prior to really call the function in question.
#
macro z_change_tag(p, t)
  if (({{p}}.as(CDoom::Byte*)) - sizeof(CDoom::Memblock)).as(CDoom::Memblock*).value.id != 0x1d4a11
    buf = Pointer(UInt8).malloc(260)
    CDoom.doom_strcpy(buf, "Error: Z_CT at #{__FILE__} :")
    CDoom.doom_concat(buf, doom_itoa(__LINE__, 10))
    CDoom.i_error(buf)
  end
  CDoom.z_change_tag2({{p}}, {{t}})
end

# translates between frame-buffer and map distances
macro ftom(x)
  (CDoom.fixed_mul(({{x}}<<16), CDoom.scale_ftom))
end

# define MTOF(x) (FixedMul((x),scale_mtof)>>16)
macro mtof(x)
  (CDoom.fixed_mul({{x}}, CDoom.scale_mtof)>>16)
end

# translates between frame-buffer and map coordinates
# define CXMTOF(x)  (f_x + MTOF((x)-m_x))
# define CYMTOF(y)  (f_y + (f_h - MTOF((y)-m_y)))
macro cxmtof(x)
  (CDoom.f_x + mtof({{x}}-CDoom.m_x))
end

macro cymtof(y)
  (CDoom.f_y + (CDoom.f_h - mtof({{y}}-CDoom.m_y)))
end

macro c_array(array, *objs)
  {% for elm, i in objs %}
    {{array}}[{{i}}] = {{elm}}
  {% end %}
end

macro c_array_strings(array, *objs)
  {% for elm, i in objs %}
    {{array}}[{{i}}] = {{elm}}.to_unsafe
  {% end %}
end

@[Link(ldflags: "-L#{__DIR__}/../.. -lpuredoom")]
lib CDoom
  # Sample rate of sound samples from doom
  DOOM_SAMPLERATE = 11025

  # MIDI tick needs to be called 140 times per seconds
  DOOM_MIDI_RATE = 140

  # Hide menu options. If for say your platform doesn't support mouse or
  # MIDI playback, you can hide these settings from the menu.
  DOOM_FLAG_HIDE_MOUSE_OPTIONS = 1 # Remove mouse options from menu
  DOOM_FLAG_HIDE_SOUND_OPTIONS = 2 # Remove sound options from menu
  DOOM_FLAG_HIDE_MUSIC_OPTIONS = 4 # Remove music options from menu

  # Darken background when menu is open, making it more readable. This
  # uses a bit more CPU and redraws the HUD every frame
  DOOM_FLAG_MENU_DARKEN_BG = 8

  alias DoomBool = LibC::Int

  enum DoomSeek
    DOOM_SEEK_CUR = 1
    DOOM_SEEK_END = 2
    DOOM_SEEK_SET = 0
  end

  alias DoomPrintFn = Proc(LibC::Char*, Nil)
  alias DoomMallocFn = Proc(LibC::Int, Void*)
  alias DoomFreeFn = Proc(Void*, Nil)
  alias DoomOpenFn = Proc(LibC::Char*, LibC::Char*, Void*)
  alias DoomCloseFn = Proc(Void*, Nil)
  alias DoomReadFn = Proc(Void*, Void*, LibC::Int, LibC::Int)
  alias DoomWriteFn = Proc(Void*, Void*, LibC::Int, LibC::Int)
  alias DoomSeekFn = Proc(Void*, LibC::Int, DoomSeek, LibC::Int)
  alias DoomTellFn = Proc(Void*, LibC::Int)
  alias DoomEofFn = Proc(Void*, LibC::Int)
  alias DoomGettimeFn = Proc(LibC::Int*, LibC::Int*, Nil)
  alias DoomExitFn = Proc(LibC::Int, Nil)
  alias DoomGetenvFn = Proc(LibC::Char*, LibC::Char*)

  # Doom key mapping
  enum DoomKey
    UNKNOWN       =   -1
    TAB           =    9
    ENTER         =   13
    ESCAPE        =   27
    SPACE         =   32
    APOSTROPHE    =   39
    MULTIPLY      =   42
    COMMA         =   44
    MINUS         = 0x2d
    PERIOD        =   46
    SLASH         =   47
    ZERO          =   48
    ONE           =   49
    TWO           =   50
    THREE         =   51
    FOUR          =   52
    FIVE          =   53
    SIX           =   54
    SEVEN         =   55
    EIGHT         =   56
    NINE          =   57
    SEMICOLON     =   58
    EQUALS        = 0x3d
    LEFT_BRACKET  =   91
    RIGHT_BRACKET =   93
    A             =   97
    B             =   98
    C             =   99
    D             =  100
    E             =  101
    F             =  102
    G             =  103
    H             =  104
    I             =  105
    J             =  106
    K             =  107
    L             =  108
    M             =  109
    N             =  110
    O             =  111
    P             =  112
    Q             =  113
    R             =  114
    S             =  115
    T             =  116
    U             =  117
    V             =  118
    W             =  119
    X             =  120
    Y             =  121
    Z             =  122
    BACKSPACE     =  127
    CTRL          = (0x80 + 0x1d) # Both left and right
    LEFT_ARROW    = 0xac
    UP_ARROW      = 0xad
    RIGHT_ARROW   = 0xae
    DOWN_ARROW    = 0xaf
    SHIFT         = (0x80 + 0x36) # Both left and right
    ALT           = (0x80 + 0x38) # Both left and right
    F1            = (0x80 + 0x3b)
    F2            = (0x80 + 0x3c)
    F3            = (0x80 + 0x3d)
    F4            = (0x80 + 0x3e)
    F5            = (0x80 + 0x3f)
    F6            = (0x80 + 0x40)
    F7            = (0x80 + 0x41)
    F8            = (0x80 + 0x42)
    F9            = (0x80 + 0x43)
    F10           = (0x80 + 0x44)
    F11           = (0x80 + 0x57)
    F12           = (0x80 + 0x58)
    PAUSE         = 0xff
  end

  # Mouse button mapping
  enum DoomButton
    LEFT   = 0
    RIGHT  = 1
    MIDDLE = 2
  end

  # For the software renderer. Default is 320x200
  fun doom_set_resolution(width : LibC::Int, height : LibC::Int)

  # Set default configurations. Lets say, changing arrows to WASD as default controls
  fun doom_set_default_int(name : LibC::Char*, value : LibC::Int)
  fun doom_set_default_string(name : LibC::Char*, value : LibC::Char*)

  # set callbacks
  fun doom_set_print(print_fn : DoomPrintFn)
  fun doom_set_malloc(malloc_fn : DoomMallocFn, free_fn : DoomFreeFn)
  fun doom_set_file_io(open_fn : DoomOpenFn,
                       close_fn : DoomCloseFn,
                       read_fn : DoomReadFn,
                       write_fn : DoomWriteFn,
                       seek_fn : DoomSeekFn,
                       tell_fn : DoomTellFn,
                       eof_fn : DoomEofFn)
  fun doom_set_gettime(gettime_fn : DoomGettimeFn)
  fun doom_set_exit(exit_fn : DoomExitFn)
  fun doom_set_getenv(getenv_fn : DoomGetenvFn)

  # Initializes DOOM and start things up. Call only call one
  fun doom_init(argc : LibC::Int, argv : LibC::Char**, flags : LibC::Int)

  # Call this every frame
  fun doom_update       # This will update at 35 FPS
  fun doom_force_update # This will run a frame everytime it's called, regardless of FPS.

  # Channels : 1 = indexed, 3 = RGB, 4 = RGBA
  fun doom_get_framebuffer(channels : LibC::Int) : LibC::UChar*

  # It is always 2048 bytes in size
  fun doom_get_sound_buffer : LibC::Short*

  # Call this 140 times per second. Or about every 7ms.
  # Returns midi message. Keep calling it until it returns 0.
  fun doom_tick_midi : LibC::ULong

  # Events
  fun doom_key_down(key : DoomKey)
  fun doom_key_up(key : DoomKey)
  fun doom_button_down(button : DoomButton)
  fun doom_button_up(button : DoomButton)
  fun doom_mouse_move(delta_x : LibC::Int, delta_y : LibC::Int)

  # __D__ENGLSH__

  #
  # Printed strings for translation
  #

  #
  # D_Main.C
  #
  D_DEVSTR = "Development mode ON.\n"
  D_CDROM  = "CD-ROM Version: default.cfg from c:\\doomdata\n"

  #
  #        M_Menu.C
  #
  PRESSKEY  = "press a key."
  PRESSYN   = "press y or n."
  QUITMSG   = "are you sure you want to\nquit this great game?"
  LOADNET   = "you can't do load while in a net game!\n\n" + PRESSKEY
  QLOADNET  = "you can't quickload during a netgame!\n\n" + PRESSKEY
  QSAVESPOT = "you haven't picked a quicksave slot yet!\n\n" + PRESSKEY
  SAVEDEAD  = "you can't save if you aren't playing!\n\n" + PRESSKEY
  QSPROMPT  = "quicksave over your game named\n\n'%s'?\n\n" + PRESSYN
  QLPROMPT  = "do you want to quickload the game named\n\n'%s'?\n\n" + PRESSYN

  QSPROMPT_1 = "quicksave over your game named\n\n'"
  QSPROMPT_2 = "'?\n\n" + PRESSYN
  QLPROMPT_1 = "do you want to quickload the game named\n\n'"
  QLPROMPT_2 = "'?\n\n" + PRESSYN

  NEWGAME = \
     "you can't start a new game\n" \
     "while in a network game.\n\n" + PRESSKEY

  NIGHTMARE = \
     "are you sure? this skill level\n" \
     "isn't even remotely fair.\n\n" + PRESSYN

  SWSTRING = \
     "this is the shareware version of doom.\n\n" \
     "you need to order the entire trilogy.\n\n" + PRESSKEY

  MSGOFF       = "Messages OFF"
  MSGON        = "Messages ON"
  CROSSOFF     = "Crosshair OFF"
  CROSSON      = "Crosshair ON"
  ALWAYSRUNOFF = "Always run OFF"
  ALWAYSRUNON  = "Always run ON"
  NETEND       = "you can't end a netgame!\n\n" + PRESSKEY
  ENDGAME      = "are you sure you want to end the game?\n\n" + PRESSYN

  DOSY = "(press y to quit)"

  DETAILHI    = "High detail"
  DETAILLO    = "Low detail"
  GAMMALVL0   = "Gamma correction OFF"
  GAMMALVL1   = "Gamma correction level 1"
  GAMMALVL2   = "Gamma correction level 2"
  GAMMALVL3   = "Gamma correction level 3"
  GAMMALVL4   = "Gamma correction level 4"
  EMPTYSTRING = "empty slot"

  #
  # P_inter.C
  #
  GOTARMOR    = "Picked up the armor."
  GOTMEGA     = "Picked up the MegaArmor!"
  GOTHTHBONUS = "Picked up a health bonus."
  GOTARMBONUS = "Picked up an armor bonus."
  GOTSTIM     = "Picked up a stimpack."
  GOTMEDINEED = "Picked up a medikit that you REALLY need!"
  GOTMEDIKIT  = "Picked up a medikit."
  GOTSUPER    = "Supercharge!"

  GOTBLUECARD = "Picked up a blue keycard."
  GOTYELWCARD = "Picked up a yellow keycard."
  GOTREDCARD  = "Picked up a red keycard."
  GOTBLUESKUL = "Picked up a blue skull key."
  GOTYELWSKUL = "Picked up a yellow skull key."
  GOTREDSKULL = "Picked up a red skull key."

  GOTINVUL   = "Invulnerability!"
  GOTBERSERK = "Berserk!"
  GOTINVIS   = "Partial Invisibility"
  GOTSUIT    = "Radiation Shielding Suit"
  GOTMAP     = "Computer Area Map"
  GOTVISOR   = "Light Amplification Visor"
  GOTMSPHERE = "MegaSphere!"

  GOTCLIP     = "Picked up a clip."
  GOTCLIPBOX  = "Picked up a box of bullets."
  GOTROCKET   = "Picked up a rocket."
  GOTROCKBOX  = "Picked up a box of rockets."
  GOTCELL     = "Picked up an energy cell."
  GOTCELLBOX  = "Picked up an energy cell pack."
  GOTSHELLS   = "Picked up 4 shotgun shells."
  GOTSHELLBOX = "Picked up a box of shotgun shells."
  GOTBACKPACK = "Picked up a backpack full of ammo!"

  GOTBFG9000  = "You got the BFG9000!  Oh, yes."
  GOTCHAINGUN = "You got the chaingun!"
  GOTCHAINSAW = "A chainsaw!  Find some meat!"
  GOTLAUNCHER = "You got the rocket launcher!"
  GOTPLASMA   = "You got the plasma gun!"
  GOTSHOTGUN  = "You got the shotgun!"
  GOTSHOTGUN2 = "You got the super shotgun!"

  #
  # P_Doors.C
  #
  PD_BLUEO   = "You need a blue key to activate this object"
  PD_REDO    = "You need a red key to activate this object"
  PD_YELLOWO = "You need a yellow key to activate this object"
  PD_BLUEK   = "You need a blue key to open this door"
  PD_REDK    = "You need a red key to open this door"
  PD_YELLOWK = "You need a yellow key to open this door"

  #
  # G_game.C
  #
  GGSAVED = "game saved."

  #
  # HU_stuff.C
  #
  HUSTR_MSGU = "[Message unsent]"

  HUSTR_E1M1 = "E1M1: Hangar"
  HUSTR_E1M2 = "E1M2: Nuclear Plant"
  HUSTR_E1M3 = "E1M3: Toxin Refinery"
  HUSTR_E1M4 = "E1M4: Command Control"
  HUSTR_E1M5 = "E1M5: Phobos Lab"
  HUSTR_E1M6 = "E1M6: Central Processing"
  HUSTR_E1M7 = "E1M7: Computer Station"
  HUSTR_E1M8 = "E1M8: Phobos Anomaly"
  HUSTR_E1M9 = "E1M9: Military Base"

  HUSTR_E2M1 = "E2M1: Deimos Anomaly"
  HUSTR_E2M2 = "E2M2: Containment Area"
  HUSTR_E2M3 = "E2M3: Refinery"
  HUSTR_E2M4 = "E2M4: Deimos Lab"
  HUSTR_E2M5 = "E2M5: Command Center"
  HUSTR_E2M6 = "E2M6: Halls of the Damned"
  HUSTR_E2M7 = "E2M7: Spawning Vats"
  HUSTR_E2M8 = "E2M8: Tower of Babel"
  HUSTR_E2M9 = "E2M9: Fortress of Mystery"

  HUSTR_E3M1 = "E3M1: Hell Keep"
  HUSTR_E3M2 = "E3M2: Slough of Despair"
  HUSTR_E3M3 = "E3M3: Pandemonium"
  HUSTR_E3M4 = "E3M4: House of Pain"
  HUSTR_E3M5 = "E3M5: Unholy Cathedral"
  HUSTR_E3M6 = "E3M6: Mt. Erebus"
  HUSTR_E3M7 = "E3M7: Limbo"
  HUSTR_E3M8 = "E3M8: Dis"
  HUSTR_E3M9 = "E3M9: Warrens"

  HUSTR_E4M1 = "E4M1: Hell Beneath"
  HUSTR_E4M2 = "E4M2: Perfect Hatred"
  HUSTR_E4M3 = "E4M3: Sever The Wicked"
  HUSTR_E4M4 = "E4M4: Unruly Evil"
  HUSTR_E4M5 = "E4M5: They Will Repent"
  HUSTR_E4M6 = "E4M6: Against Thee Wickedly"
  HUSTR_E4M7 = "E4M7: And Hell Followed"
  HUSTR_E4M8 = "E4M8: Unto The Cruel"
  HUSTR_E4M9 = "E4M9: Fear"

  HUSTR_1  = "level 1: entryway"
  HUSTR_2  = "level 2: underhalls"
  HUSTR_3  = "level 3: the gantlet"
  HUSTR_4  = "level 4: the focus"
  HUSTR_5  = "level 5: the waste tunnels"
  HUSTR_6  = "level 6: the crusher"
  HUSTR_7  = "level 7: dead simple"
  HUSTR_8  = "level 8: tricks and traps"
  HUSTR_9  = "level 9: the pit"
  HUSTR_10 = "level 10: refueling base"
  HUSTR_11 = "level 11: 'o' of destruction!"

  HUSTR_12 = "level 12: the factory"
  HUSTR_13 = "level 13: downtown"
  HUSTR_14 = "level 14: the inmost dens"
  HUSTR_15 = "level 15: industrial zone"
  HUSTR_16 = "level 16: suburbs"
  HUSTR_17 = "level 17: tenements"
  HUSTR_18 = "level 18: the courtyard"
  HUSTR_19 = "level 19: the citadel"
  HUSTR_20 = "level 20: gotcha!"

  HUSTR_21 = "level 21: nirvana"
  HUSTR_22 = "level 22: the catacombs"
  HUSTR_23 = "level 23: barrels o' fun"
  HUSTR_24 = "level 24: the chasm"
  HUSTR_25 = "level 25: bloodfalls"
  HUSTR_26 = "level 26: the abandoned mines"
  HUSTR_27 = "level 27: monster condo"
  HUSTR_28 = "level 28: the spirit world"
  HUSTR_29 = "level 29: the living end"
  HUSTR_30 = "level 30: icon of sin"

  HUSTR_31 = "level 31: wolfenstein"
  HUSTR_32 = "level 32: grosse"

  PHUSTR_1  = "level 1: congo"
  PHUSTR_2  = "level 2: well of souls"
  PHUSTR_3  = "level 3: aztec"
  PHUSTR_4  = "level 4: caged"
  PHUSTR_5  = "level 5: ghost town"
  PHUSTR_6  = "level 6: baron's lair"
  PHUSTR_7  = "level 7: caughtyard"
  PHUSTR_8  = "level 8: realm"
  PHUSTR_9  = "level 9: abattoire"
  PHUSTR_10 = "level 10: onslaught"
  PHUSTR_11 = "level 11: hunted"

  PHUSTR_12 = "level 12: speed"
  PHUSTR_13 = "level 13: the crypt"
  PHUSTR_14 = "level 14: genesis"
  PHUSTR_15 = "level 15: the twilight"
  PHUSTR_16 = "level 16: the omen"
  PHUSTR_17 = "level 17: compound"
  PHUSTR_18 = "level 18: neurosphere"
  PHUSTR_19 = "level 19: nme"
  PHUSTR_20 = "level 20: the death domain"

  PHUSTR_21 = "level 21: slayer"
  PHUSTR_22 = "level 22: impossible mission"
  PHUSTR_23 = "level 23: tombstone"
  PHUSTR_24 = "level 24: the final frontier"
  PHUSTR_25 = "level 25: the temple of darkness"
  PHUSTR_26 = "level 26: bunker"
  PHUSTR_27 = "level 27: anti-christ"
  PHUSTR_28 = "level 28: the sewers"
  PHUSTR_29 = "level 29: odyssey of noises"
  PHUSTR_30 = "level 30: the gateway of hell"

  PHUSTR_31 = "level 31: cyberden"
  PHUSTR_32 = "level 32: go 2 it"

  THUSTR_1  = "level 1: system control"
  THUSTR_2  = "level 2: human bbq"
  THUSTR_3  = "level 3: power control"
  THUSTR_4  = "level 4: wormhole"
  THUSTR_5  = "level 5: hanger"
  THUSTR_6  = "level 6: open season"
  THUSTR_7  = "level 7: prison"
  THUSTR_8  = "level 8: metal"
  THUSTR_9  = "level 9: stronghold"
  THUSTR_10 = "level 10: redemption"
  THUSTR_11 = "level 11: storage facility"

  THUSTR_12 = "level 12: crater"
  THUSTR_13 = "level 13: nukage processing"
  THUSTR_14 = "level 14: steel works"
  THUSTR_15 = "level 15: dead zone"
  THUSTR_16 = "level 16: deepest reaches"
  THUSTR_17 = "level 17: processing area"
  THUSTR_18 = "level 18: mill"
  THUSTR_19 = "level 19: shipping/respawning"
  THUSTR_20 = "level 20: central processing"

  THUSTR_21 = "level 21: administration center"
  THUSTR_22 = "level 22: habitat"
  THUSTR_23 = "level 23: lunar mining project"
  THUSTR_24 = "level 24: quarry"
  THUSTR_25 = "level 25: baron's den"
  THUSTR_26 = "level 26: ballistyx"
  THUSTR_27 = "level 27: mount pain"
  THUSTR_28 = "level 28: heck"
  THUSTR_29 = "level 29: river styx"
  THUSTR_30 = "level 30: last call"

  THUSTR_31 = "level 31: pharaoh"
  THUSTR_32 = "level 32: caribbean"

  HUSTR_CHATMACRO1 = "I'm ready to kick butt!"
  HUSTR_CHATMACRO2 = "I'm OK."
  HUSTR_CHATMACRO3 = "I'm not looking too good!"
  HUSTR_CHATMACRO4 = "Help!"
  HUSTR_CHATMACRO5 = "You suck!"
  HUSTR_CHATMACRO6 = "Next time, scumbag..."
  HUSTR_CHATMACRO7 = "Come here!"
  HUSTR_CHATMACRO8 = "I'll take care of it."
  HUSTR_CHATMACRO9 = "Yes"
  HUSTR_CHATMACRO0 = "No"

  HUSTR_TALKTOSELF1 = "You mumble to yourself"
  HUSTR_TALKTOSELF2 = "Who's there?"
  HUSTR_TALKTOSELF3 = "You scare yourself"
  HUSTR_TALKTOSELF4 = "You start to rave"
  HUSTR_TALKTOSELF5 = "You've lost it..."

  HUSTR_MESSAGESENT = "[Message Sent]"

  # The following should NOT be changed unless it seems
  # just AWFULLY necessary

  HUSTR_PLRGREEN  = "Green: "
  HUSTR_PLRINDIGO = "Indigo: "
  HUSTR_PLRBROWN  = "Brown: "
  HUSTR_PLRRED    = "Red: "

  HUSTR_KEYGREEN  = 'g'
  HUSTR_KEYINDIGO = 'i'
  HUSTR_KEYBROWN  = 'b'
  HUSTR_KEYRED    = 'r'

  #
  # AM_map.C
  #

  AMSTR_FOLLOWON  = "Follow Mode ON"
  AMSTR_FOLLOWOFF = "Follow Mode OFF"

  AMSTR_GRIDON  = "Grid ON"
  AMSTR_GRIDOFF = "Grid OFF"

  AMSTR_MARKEDSPOT   = "Marked Spot"
  AMSTR_MARKSCLEARED = "All Marks Cleared"

  #
  # ST_stuff.C
  #

  STSTR_MUS    = "Music Change"
  STSTR_NOMUS  = "IMPOSSIBLE SELECTION"
  STSTR_DQDON  = "Degreelessness Mode On"
  STSTR_DQDOFF = "Degreelessness Mode Off"

  STSTR_KFAADDED = "Very Happy Ammo Added"
  STSTR_FAADDED  = "Ammo (no keys) Added"

  STSTR_NCON  = "No Clipping Mode ON"
  STSTR_NCOFF = "No Clipping Mode OFF"

  STSTR_BEHOLD  = "inVuln, Str, Inviso, Rad, Allmap, or Lite-amp"
  STSTR_BEHOLDX = "Power-up Toggled"

  STSTR_CHOPPERS = "... doesn't suck - GM"
  STSTR_CLEV     = "Changing Level..."

  #
  # F_Finale.C
  #
  E1TEXT = \
     "Once you beat the big badasses and\n" \
     "clean out the moon base you're supposed\n" \
     "to win, aren't you? Aren't you? Where's\n" \
     "your fat reward and ticket home? What\n" \
     "the hell is this? It's not supposed to\n" \
     "end this way!\n" \
     "\n" \
     "It stinks like rotten meat, but looks\n" \
     "like the lost Deimos base.  Looks like\n" \
     "you're stuck on The Shores of Hell.\n" \
     "The only way out is through.\n" \
     "\n" \
     "To continue the DOOM experience, play\n" \
     "The Shores of Hell and its amazing\n" \
     "sequel, Inferno!\n"

  E2TEXT = \
     "You've done it! The hideous cyber-\n" \
     "demon lord that ruled the lost Deimos\n" \
     "moon base has been slain and you\n" \
     "are triumphant! But ... where are\n" \
     "you? You clamber to the edge of the\n" \
     "moon and look down to see the awful\n" \
     "truth.\n" \
     "\n" \
     "Deimos floats above Hell itself!\n" \
     "You've never heard of anyone escaping\n" \
     "from Hell, but you'll make the bastards\n" \
     "sorry they ever heard of you! Quickly,\n" \
     "you rappel down to  the surface of\n" \
     "Hell.\n" \
     "\n" \
     "Now, it's on to the final chapter of\n" \
     "DOOM! -- Inferno."

  E3TEXT = \
     "The loathsome spiderdemon that\n" \
     "masterminded the invasion of the moon\n" \
     "bases and caused so much death has had\n" \
     "its ass kicked for all time.\n" \
     "\n" \
     "A hidden doorway opens and you enter.\n" \
     "You've proven too tough for Hell to\n" \
     "contain, and now Hell at last plays\n" \
     "fair -- for you emerge from the door\n" \
     "to see the green fields of Earth!\n" \
     "Home at last.\n" \
     "\n" \
     "You wonder what's been happening on\n" \
     "Earth while you were battling evil\n" \
     "unleashed. It's good that no Hell-\n" \
     "spawn could have come through that\n" \
     "door with you ..."

  E4TEXT = \
     "the spider mastermind must have sent forth\n" \
     "its legions of hellspawn before your\n" \
     "final confrontation with that terrible\n" \
     "beast from hell.  but you stepped forward\n" \
     "and brought forth eternal damnation and\n" \
     "suffering upon the horde as a true hero\n" \
     "would in the face of something so evil.\n" \
     "\n" \
     "besides, someone was gonna pay for what\n" \
     "happened to daisy, your pet rabbit.\n" \
     "\n" \
     "but now, you see spread before you more\n" \
     "potential pain and gibbitude as a nation\n" \
     "of demons run amok among our cities.\n" \
     "\n" \
     "next stop, hell on earth!"

  # after level 6, put this:
  C1TEXT = \
     "YOU HAVE ENTERED DEEPLY INTO THE INFESTED\n" \
     "STARPORT. BUT SOMETHING IS WRONG. THE\n" \
     "MONSTERS HAVE BROUGHT THEIR OWN REALITY\n" \
     "WITH THEM, AND THE STARPORT'S TECHNOLOGY\n" \
     "IS BEING SUBVERTED BY THEIR PRESENCE.\n" \
     "\n" \
     "AHEAD, YOU SEE AN OUTPOST OF HELL, A\n" \
     "FORTIFIED ZONE. IF YOU CAN GET PAST IT,\n" \
     "YOU CAN PENETRATE INTO THE HAUNTED HEART\n" \
     "OF THE STARBASE AND FIND THE CONTROLLING\n" \
     "SWITCH WHICH HOLDS EARTH'S POPULATION\n" \
     "HOSTAGE."

  # After level 11, put this:
  C2TEXT = \
     "YOU HAVE WON! YOUR VICTORY HAS ENABLED\n" \
     "HUMANKIND TO EVACUATE EARTH AND ESCAPE\n" \
     "THE NIGHTMARE.  NOW YOU ARE THE ONLY\n" \
     "HUMAN LEFT ON THE FACE OF THE PLANET.\n" \
     "CANNIBAL MUTATIONS, CARNIVOROUS ALIENS,\n" \
     "AND EVIL SPIRITS ARE YOUR ONLY NEIGHBORS.\n" \
     "YOU SIT BACK AND WAIT FOR DEATH, CONTENT\n" \
     "THAT YOU HAVE SAVED YOUR SPECIES.\n" \
     "\n" \
     "BUT THEN, EARTH CONTROL BEAMS DOWN A\n" \
     "MESSAGE FROM SPACE: \"SENSORS HAVE LOCATED\n" \
     "THE SOURCE OF THE ALIEN INVASION. IF YOU\n" \
     "GO THERE, YOU MAY BE ABLE TO BLOCK THEIR\n" \
     "ENTRY.  THE ALIEN BASE IS IN THE HEART OF\n" \
     "YOUR OWN HOME CITY, NOT FAR FROM THE\n" \
     "STARPORT.\" SLOWLY AND PAINFULLY YOU GET\n" \
     "UP AND RETURN TO THE FRAY."

  # After level 20, put this:
  C3TEXT = \
     "YOU ARE AT THE CORRUPT HEART OF THE CITY,\n" \
     "SURROUNDED BY THE CORPSES OF YOUR ENEMIES.\n" \
     "YOU SEE NO WAY TO DESTROY THE CREATURES'\n" \
     "ENTRYWAY ON THIS SIDE, SO YOU CLENCH YOUR\n" \
     "TEETH AND PLUNGE THROUGH IT.\n" \
     "\n" \
     "THERE MUST BE A WAY TO CLOSE IT ON THE\n" \
     "OTHER SIDE. WHAT DO YOU CARE IF YOU'VE\n" \
     "GOT TO GO THROUGH HELL TO GET TO IT?"

  # After level 29, put this:
  C4TEXT = \
     "THE HORRENDOUS VISAGE OF THE BIGGEST\n" \
     "DEMON YOU'VE EVER SEEN CRUMBLES BEFORE\n" \
     "YOU, AFTER YOU PUMP YOUR ROCKETS INTO\n" \
     "HIS EXPOSED BRAIN. THE MONSTER SHRIVELS\n" \
     "UP AND DIES, ITS THRASHING LIMBS\n" \
     "DEVASTATING UNTOLD MILES OF HELL'S\n" \
     "SURFACE.\n" \
     "\n" \
     "YOU'VE DONE IT. THE INVASION IS OVER.\n" \
     "EARTH IS SAVED. HELL IS A WRECK. YOU\n" \
     "WONDER WHERE BAD FOLKS WILL GO WHEN THEY\n" \
     "DIE, NOW. WIPING THE SWEAT FROM YOUR\n" \
     "FOREHEAD YOU BEGIN THE LONG TREK BACK\n" \
     "HOME. REBUILDING EARTH OUGHT TO BE A\n" \
     "LOT MORE FUN THAN RUINING IT WAS.\n"

  # Before level 31, put this:
  C5TEXT = \
     "CONGRATULATIONS, YOU'VE FOUND THE SECRET\n" \
     "LEVEL! LOOKS LIKE IT'S BEEN BUILT BY\n" \
     "HUMANS, RATHER THAN DEMONS. YOU WONDER\n" \
     "WHO THE INMATES OF THIS CORNER OF HELL\n" \
     "WILL BE."

  # Before level 32, put this:
  C6TEXT = \
     "CONGRATULATIONS, YOU'VE FOUND THE\n" \
     "SUPER SECRET LEVEL!  YOU'D BETTER\n" \
     "BLAZE THROUGH THIS ONE!\n"

  # after map 06
  P1TEXT = \
     "You gloat over the steaming carcass of the\n" \
     "Guardian.  With its death, you've wrested\n" \
     "the Accelerator from the stinking claws\n" \
     "of Hell.  You relax and glance around the\n" \
     "room.  Damn!  There was supposed to be at\n" \
     "least one working prototype, but you can't\n" \
     "see it. The demons must have taken it.\n" \
     "\n" \
     "You must find the prototype, or all your\n" \
     "struggles will have been wasted. Keep\n" \
     "moving, keep fighting, keep killing.\n" \
     "Oh yes, keep living, too."

  # after map 11
  P2TEXT = \
     "Even the deadly Arch-Vile labyrinth could\n" \
     "not stop you, and you've gotten to the\n" \
     "prototype Accelerator which is soon\n" \
     "efficiently and permanently deactivated.\n" \
     "\n" \
     "You're good at that kind of thing."

  # after map 20
  P3TEXT = \
     "You've bashed and battered your way into\n" \
     "the heart of the devil-hive.  Time for a\n" \
     "Search-and-Destroy mission, aimed at the\n" \
     "Gatekeeper, whose foul offspring is\n" \
     "cascading to Earth.  Yeah, he's bad. But\n" \
     "you know who's worse!\n" \
     "\n" \
     "Grinning evilly, you check your gear, and\n" \
     "get ready to give the bastard a little Hell\n" \
     "of your own making!"

  # after map 30
  P4TEXT = \
     "The Gatekeeper's evil face is splattered\n" \
     "all over the place.  As its tattered corpse\n" \
     "collapses, an inverted Gate forms and\n" \
     "sucks down the shards of the last\n" \
     "prototype Accelerator, not to mention the\n" \
     "few remaining demons.  You're done. Hell\n" \
     "has gone back to pounding bad dead folks \n" \
     "instead of good live ones.  Remember to\n" \
     "tell your grandkids to put a rocket\n" \
     "launcher in your coffin. If you go to Hell\n" \
     "when you die, you'll need it for some\n" \
     "final cleaning-up ..."

  # before map 31
  P5TEXT = \
     "You've found the second-hardest level we\n" \
     "got. Hope you have a saved game a level or\n" \
     "two previous.  If not, be prepared to die\n" \
     "aplenty. For master marines only."

  # before map 32
  P6TEXT = \
     "Betcha wondered just what WAS the hardest\n" \
     "level we had ready for ya?  Now you know.\n" \
     "No one gets out alive."

  T1TEXT = \
     "You've fought your way out of the infested\n" \
     "experimental labs.   It seems that UAC has\n" \
     "once again gulped it down.  With their\n" \
     "high turnover, it must be hard for poor\n" \
     "old UAC to buy corporate health insurance\n" \
     "nowadays..\n" \
     "\n" \
     "Ahead lies the military complex, now\n" \
     "swarming with diseased horrors hot to get\n" \
     "their teeth into you. With luck, the\n" \
     "complex still has some warlike ordnance\n" \
     "laying around."

  T2TEXT = \
     "You hear the grinding of heavy machinery\n" \
     "ahead.  You sure hope they're not stamping\n" \
     "out new hellspawn, but you're ready to\n" \
     "ream out a whole herd if you have to.\n" \
     "They might be planning a blood feast, but\n" \
     "you feel about as mean as two thousand\n" \
     "maniacs packed into one mad killer.\n" \
     "\n" \
     "You don't plan to go down easy."

  T3TEXT = \
     "The vista opening ahead looks real damn\n" \
     "familiar. Smells familiar, too -- like\n" \
     "fried excrement. You didn't like this\n" \
     "place before, and you sure as hell ain't\n" \
     "planning to like it now. The more you\n" \
     "brood on it, the madder you get.\n" \
     "Hefting your gun, an evil grin trickles\n" \
     "onto your face. Time to take some names."

  T4TEXT = \
     "Suddenly, all is silent, from one horizon\n" \
     "to the other. The agonizing echo of Hell\n" \
     "fades away, the nightmare sky turns to\n" \
     "blue, the heaps of monster corpses start \n" \
     "to evaporate along with the evil stench \n" \
     "that filled the air. Jeeze, maybe you've\n" \
     "done it. Have you really won?\n" \
     "\n" \
     "Something rumbles in the distance.\n" \
     "A blue light begins to glow inside the\n" \
     "ruined skull of the demon-spitter."

  T5TEXT = \
     "What now? Looks totally different. Kind\n" \
     "of like King Tut's condo. Well,\n" \
     "whatever's here can't be any worse\n" \
     "than usual. Can it?  Or maybe it's best\n" \
     "to let sleeping gods lie.."

  T6TEXT = \
     "Time for a vacation. You've burst the\n" \
     "bowels of hell and by golly you're ready\n" \
     "for a break. You mutter to yourself,\n" \
     "Maybe someone else can kick Hell's ass\n" \
     "next time around. Ahead lies a quiet town,\n" \
     "with peaceful flowing water, quaint\n" \
     "buildings, and presumably no Hellspawn.\n" \
     "\n" \
     "As you step off the transport, you hear\n" \
     "the stomp of a cyberdemon's iron shoe."

  #
  # Character cast strings F_FINALE.C
  #
  CC_ZOMBIE  = "ZOMBIEMAN"
  CC_SHOTGUN = "SHOTGUN GUY"
  CC_HEAVY   = "HEAVY WEAPON DUDE"
  CC_IMP     = "IMP"
  CC_DEMON   = "DEMON"
  CC_LOST    = "LOST SOUL"
  CC_CACO    = "CACODEMON"
  CC_HELL    = "HELL KNIGHT"
  CC_BARON   = "BARON OF HELL"
  CC_ARACH   = "ARACHNOTRON"
  CC_PAIN    = "PAIN ELEMENTAL"
  CC_REVEN   = "REVENANT"
  CC_MANCU   = "MANCUBUS"
  CC_ARCH    = "ARCH-VILE"
  CC_SPIDER  = "THE SPIDER MASTERMIND"
  CC_CYBER   = "THE CYBERDEMON"
  CC_HERO    = "OUR HERO"

  # __D_THINK__

  #
  # Experimental stuff.
  # To compile this as "ANSI C with classes"
  #  we will need to handle the various
  #  action functions cleanly.
  #
  alias ActionfV = Proc(Nil)
  alias ActionfP1 = Proc(Void*, Nil)
  alias ActionfP2 = Proc(Void*, Void*, Nil)

  union Actionf
    acp1 : ActionfP1
    acv : ActionfV
    acp2 : ActionfP2
  end

  # Historically, "think_t" is yet another
  #  function pointer to a routine to handle
  #  an actor.
  alias Think = Actionf

  # Doubly linked list of actors.
  struct Thinker
    prev : Thinker*
    next : Thinker*
    function : Think
  end

  # __DOOM_CONFIG_H__

  {% if flag?(:windows) %}
    DOOM_WIN32 = true
  {% elsif flag?(:macosx) %}
    DOOM_APPLE = true
  {% else %}
    DOOM_LINUX = true
  {% end %}

  $error_buf : LibC::Char[260]
  $doom_flags : LibC::Int
  $doom_print : DoomPrintFn
  $doom_malloc : DoomMallocFn
  $doom_free : DoomFreeFn
  $doom_open : DoomOpenFn
  $doom_close : DoomCloseFn
  $doom_read : DoomReadFn
  $doom_write : DoomWriteFn
  $doom_seek : DoomSeekFn
  $doom_tell : DoomTellFn
  $doom_eof : DoomEofFn
  $doom_gettime_fn : DoomGettimeFn
  $doom_exit : DoomExitFn
  $doom_getenv : DoomGetenvFn

  fun doom_itoa(i : LibC::Int, radix : LibC::Int) : LibC::Char*
  fun doom_ctoa(c : LibC::Char) : LibC::Char*
  fun doom_ptoa(p : Void*) : LibC::Char*
  fun doom_memset(ptr : Void*, value : LibC::Int, num : LibC::Int)
  fun doom_memcpy(destination : Void*, source : Void*, num : LibC::Int) : Void*
  fun doom_fprint(handle : Void*, str : LibC::Char*) : LibC::Int
  fun doom_strlen(str : LibC::Char*) : LibC::Int
  fun doom_concat(dst : LibC::Char*, src : LibC::Char*) : LibC::Char*
  fun doom_strcpy(destination : LibC::Char*, source : LibC::Char*) : LibC::Char*
  fun doom_strncpy(destination : LibC::Char*, source : LibC::Char*, num : LibC::Int) : LibC::Char*
  fun doom_strcmp(str1 : LibC::Char*, str2 : LibC::Char*) : LibC::Int
  fun doom_strncmp(str1 : LibC::Char*, str2 : LibC::Char*, n : LibC::Int) : LibC::Int
  fun doom_strcasecmp(str1 : LibC::Char*, str2 : LibC::Char*) : LibC::Int
  fun doom_strncasecmp(str1 : LibC::Char*, str2 : LibC::Char*, n : LibC::Int) : LibC::Int
  fun doom_atoi(str : LibC::Char*) : LibC::Int
  fun doom_atox(str : LibC::Char*) : LibC::Int
  fun doom_toupper(c : LibC::Int) : LibC::Int

  # __DOOMDEF__

  #
  # Global parameters/defines.
  #
  # DOOM version
  VERSION = 110

  # Game mode handling - identify IWAD version
  #  to handle IWAD dependend animations etc.
  enum GameMode
    Shareware  # DOOM 1 shareware, E1, M9
    Registered # DOOM 1 registered, E3, M27
    Commercial # DOOM 2 retail, E1 M34
    # DOOM 2 german edition not handled
    Retail       # DOOM 1 retail, E4, M36
    Indetermined # Well, no IWAD found.
  end

  # Mission packs - might be useful for TC stuff?
  enum GameMission
    Doom     # DOOM 1
    Doom2    # DOOM 2
    PackTnt  # TNT mission pack
    PackPlut # Plutonia pack
    None
  end

  # Identify language to use, software localization.
  enum Language
    English
    French
    German
    Unknown
  end

  # If rangecheck is undefined,
  # most parameter validation debugging code will not be compiled
  RANGECHECK = true

  #
  # For resize of screen, at start of game.
  # It will not work dynamically, see visplanes.
  #
  BASE_WIDTH = 320

  # It is educational but futile to change this
  #  scaling e.g. to 2. Drawing of status bar,
  #  menues etc. is tied to the scale implied
  #  by the graphics.
  SCREEN_MUL       =     1
  INV_ASPECT_RATIO = 0.625 # 0.75, ideally

  # Constants suck. Crystal sucks.
  # Ruby might sucks for OOP, but it sure is a better Crystal.
  # So there.
  SCREENWIDTH  = 320
  SCREENHEIGHT = 200

  # The maximum number of players, multiplayer/networking.
  MAXPLAYERS = 4

  # State updates, number of tics / second.
  {% if @top_level.has_constant?("DOOM_FAST_TICK") %}
    TICKMUL = 2
  {% else %}
    TICKMUL = 1
  {% end %}
  TICRATE = (35 * TICKMUL)

  # The current state of the game: whether we are
  # playing, gazing at the intermission screen,
  # the game final animation, or a demo.
  enum Gamestate
    Needwipe     = -1
    Level
    Intermission
    Finale
    Demoscreen
  end

  #
  # Difficulty/skill settings/filters.
  #

  # Skill flags.
  MTF_EASY   = 1
  MTF_NORMAL = 2
  MTF_HARD   = 4

  # Deaf monsters/do not react to sound.
  MTF_AMBUSH = 8

  enum Skill
    Baby
    Easy
    Medium
    Hard
    Nightmare
  end

  #
  # Key card.
  #
  enum Card
    Bluecard
    Yellowcard
    Redcard
    Blueskull
    Yellowskull
    Redskull
    NUMCARDS
  end

  # The defined weapons,
  # including a marker indicating
  # user has not changed weapon.
  enum Weapontype
    Fist
    Pistol
    Shotgun
    Chaingun
    Missile
    Plasma
    Bfg
    Chainsaw
    Supershotgun
    NUMWEAPONS
    # No pending weapon change.
    Nochange
  end

  # Ammunition types defined.
  enum Ammotype
    Clip  # Pistol / chaingun ammo.
    Shell # Shotgun / double barreled shotgun.
    Cell  # Plasma rifle, BFG.
    Misl  # Missile launcher.
    NUMAMMO
    Noammo # Unlimited for chainsaw / fist.
  end

  # Power up artifacts.
  enum Powertype
    Invulnerability
    Strength
    Invisibility
    Ironfeet
    Allmap
    Infrared
    NUMPOWERS
  end

  #
  # Power up durations,
  #  how many seconds till expiration,
  #  assuming TICRATE is 35 ticks/second.
  #
  enum Powerduration
    INVULNTICS = (30 * TICRATE)
    INVISTICS  = (60 * TICRATE)
    INFRATICS  = (120 * TICRATE)
    IRONTICS   = (60 * TICRATE)
  end

  #
  # DOOM keyboard definition.
  # This is the stuff configured by Setup.Exe.
  # Most key data are simple ascii (uppercased).
  #
  KEY_RIGHTARROW = 0xae
  KEY_LEFTARROW  = 0xac
  KEY_UPARROW    = 0xad
  KEY_DOWNARROW  = 0xaf
  KEY_ESCAPE     =   27
  KEY_ENTER      =   13
  KEY_TAB        =    9
  KEY_F1         = (0x80 + 0x3b)
  KEY_F2         = (0x80 + 0x3c)
  KEY_F3         = (0x80 + 0x3d)
  KEY_F4         = (0x80 + 0x3e)
  KEY_F5         = (0x80 + 0x3f)
  KEY_F6         = (0x80 + 0x40)
  KEY_F7         = (0x80 + 0x41)
  KEY_F8         = (0x80 + 0x42)
  KEY_F9         = (0x80 + 0x43)
  KEY_F10        = (0x80 + 0x44)
  KEY_F11        = (0x80 + 0x57)
  KEY_F12        = (0x80 + 0x58)

  KEY_BACKSPACE =  127
  KEY_PAUSE     = 0xff

  KEY_EQUALS = 0x3d
  KEY_MINUS  = 0x2d

  KEY_RSHIFT = (0x80 + 0x36)
  KEY_RCTRL  = (0x80 + 0x1d)
  KEY_RALT   = (0x80 + 0x38)

  KEY_LALT = KEY_RALT

  # __D_ITEMS__

  # Weapon info: sprite frames, ammunition use.
  struct Weaponinfo
    ammo : Ammotype
    upstate : LibC::Int
    downstate : LibC::Int
    readystate : LibC::Int
    atkstate : LibC::Int
    flashstate : LibC::Int
  end

  $weaponinfo : Weaponinfo[Weapontype::NUMWEAPONS]

  # __DOOMTYPE__

  alias Byte = LibC::UChar
  # Types are already defined in the Crystal int classes

  # __D_EVENT__

  #
  # Event handling.
  #

  # Input event types.
  enum Evtype
    Keydown
    Keyup
    Mouse
    Joystick
  end

  # Event structure.
  struct Event
    type : Evtype
    data1 : LibC::Int # keys / mouse/joystick buttons
    data2 : LibC::Int # mouse/joystick x move
    data3 : LibC::Int # mouse/joystick y move
  end

  enum Gameaction
    Nothing
    Loadlevel
    Newgame
    Loadgame
    Savegame
    Playdemo
    Completed
    Victory
    Worlddone
    Screenshot
  end

  #
  # Button/action code definitions.
  #
  enum Buttoncode
    # Press "Fire".
    BT_ATTACK = 1
    # Use button, to open doors, activate switches.
    BT_USE = 2

    # Flag: game events, not really buttons.
    BT_SPECIAL     = 128
    BT_SPECIALMASK =   3

    # Flag, weapon change pending.
    # If true, the next 3 bits hold weapon num.
    BT_CHANGE = 4
    # The 3bit weapon mask and shift, convenience.
    BT_WEAPONMASK  = (8 + 16 + 32)
    BT_WEAPONSHIFT = 3

    # Pause the game.
    BTS_PAUSE = 1
    # Save the game at each console.
    BTS_SAVEGAME = 2

    # Savegame slot numbers
    #  occupy the second byte of buttons.
    BTS_SAVEMASK  = (4 + 8 + 16)
    BTS_SAVESHIFT = 2
  end

  #
  # GLOBAL VARIABLES
  MAXEVENTS = (64 * 64) # [pd] Crank up the number because we pump them faster

  $events : Event[MAXEVENTS]
  $eventhead : LibC::Int
  $eventtail : LibC::Int

  $gameaction : Gameaction

  # __AMMAP_H__

  # Used by ST StatusBar stuff.
  AM_MSGHEADER  = (('a'.ord << 24) + ('m'.ord << 16))
  AM_MSGENTERED = (AM_MSGHEADER | ('e'.ord << 8))
  AM_MSGEXITED  = (AM_MSGHEADER | ('x'.ord << 8))

  # Called by main loop.
  fun am_responder = AM_Responder(ev : Event*) : DoomBool

  # Called by main loop.
  fun am_ticker = AM_Ticker

  # Called by main loop,
  # called instead of view drawer if automap active.
  fun am_drawer = AM_Drawer

  # Called to force the automap to quit
  # if the level is completed while it is up.
  fun am_stop = AM_Stop

  # __D_MAIN__

  MAXWADFILES = 20

  $wadfiles : LibC::Char*[MAXWADFILES]

  fun d_add_file = D_AddFile(file : LibC::Char*)

  #
  # D_DoomMain()
  # Not a globally visible function, just included for source reference,
  # calls all startup code, parses command line options.
  # If not overrided by user input, calls N_AdvanceDemo.
  #
  fun d_doom_main = D_DoomMain

  # Called by IO functions when input is detected.
  fun d_post_event = D_PostEvent(ev : Event*)

  #
  # BASE LEVEL
  #
  fun d_page_ticker = D_PageTicker
  fun d_page_drawer = D_PageDrawer
  fun d_advance_demo = D_AdvanceDemo
  fun d_start_title = D_StartTitle

  # __D_TEXTUR__

  #
  # Flats?
  #
  # a pic is an unmasked block of pixels
  struct Pic
    width : Byte
    height : Byte
    data : Byte
  end

  # __D_TICCMD__

  # The data sampled per tick (single player)
  # and transmitted to other peers (multiplayer).
  # Mainly movements/button commands per game tick,
  # plus a checksum for internal state consistency.
  struct Ticcmd
    forwardmove : LibC::SChar # *2048 for move
    sidemove : LibC::SChar    # *2048 for move
    angleturn : LibC::Short   # <<16 for angle delta
    consistancy : LibC::Short # checks for net game
    chatchar : Byte
    buttons : Byte
  end

  # __DOOMDATA__

  #
  # Map level types.
  # The following data structures define the persistent format
  # used in the lumps of the WAD files.
  #

  # Lump order in a map WAD: each map needs a couple of lumps
  # to provide a complete scene geometry description.
  ML_LABEL    =  0 # A separator, name, ExMx or MAPxx
  ML_THINGS   =  1 # Monsters, items..
  ML_LINEDEFS =  2 # LineDefs, from editing
  ML_SIDEDEFS =  3 # SideDefs, from editing
  ML_VERTEXES =  4 # Vertices, edited and BSP splits generated
  ML_SEGS     =  5 # LineSegs, from LineDefs split by BSP
  ML_SSECTORS =  6 # SubSectors, list of LineSegs
  ML_NODES    =  7 # BSP nodes
  ML_SECTORS  =  8 # Sectors, from editing
  ML_REJECT   =  9 # LUT, sector-sector visibility
  ML_BLOCKMAP = 10 # LUT, motion clipping, walls/grid element

  # A single Vertex.
  struct Mapvertex
    x : LibC::Short
    y : LibC::Short
  end

  # A SideDef, defining the visual appearance of a wall,
  # by setting textures and offsets.
  struct Mapsidedef
    textureoffset : LibC::Short
    rowoffset : LibC::Short
    toptexture : LibC::Char[8]
    bottomtexture : LibC::Char[8]
    midtexture : LibC::Char[8]
    # Front sector, towards viewer.
    sector : LibC::Short
  end

  # A LineDef, as used for editing, and as input
  # to the BSP builder.
  struct Maplinedef
    v1 : LibC::Short
    v2 : LibC::Short
    flags : LibC::Short
    special : LibC::Short
    tag : LibC::Short
    # sidenum[1] will be -1 if one sided
    sidenum : LibC::Short[2]
  end

  #
  # LineDef attributes.
  #

  # Solid, is an obstacle.
  ML_BLOCKING = 1

  # Blocks monsters only.
  ML_BLOCKMONSTERS = 2

  # Backside will not be present at all
  #  if not two sided.
  ML_TWOSIDED = 4

  # If a texture is pegged, the texture will have
  # the end exposed to air held constant at the
  # top or bottom of the texture (stairs or pulled
  # down things) and will move with a height change
  # of one of the neighbor sectors.
  # Unpegged textures allways have the first row of
  # the texture at the top pixel of the line for both
  # top and bottom textures (use next to windows).

  # upper texture unpegged
  ML_DONTPEGTOP = 8

  # lower texture unpegged
  ML_DONTPEGBOTTOM = 16

  # In AutoMap: don't map as two sided: IT'S A SECRET!
  ML_SECRET = 32

  # Sound rendering: don't let sound cross two of these.
  ML_SOUNDBLOCK = 64

  # Don't draw on the automap at all.
  ML_DONTDRAW = 128

  # Set if already seen, thus drawn in automap.
  ML_MAPPED = 256

  # Sector definition, from editing.
  struct Mapsector
    floorheight : LibC::Short
    ceilingheight : LibC::Short
    floorpic : LibC::Char[8]
    ceilingpic : LibC::Char[8]
    lightlevel : LibC::Short
    special : LibC::Short
    tag : LibC::Short
  end

  # SubSector, as generated by BSP.
  struct Mapsubsector
    numsegs : LibC::Short
    # Index of first one, segs are stored sequentially.
    firstseg : LibC::Short
  end

  # LineSeg, generated by splitting LineDefs
  # using partition lines selected by BSP builder.
  struct Mapseg
    v1 : LibC::Short
    v2 : LibC::Short
    angle : LibC::Short
    linedef : LibC::Short
    side : LibC::Short
    offset : LibC::Short
  end

  #
  # BSP node structure.
  #

  # Indicate a leaf.
  NF_SUBSECTOR = 0x8000

  struct Mapnode
    # Partition line from (x,y) to x+dx,y+dy)
    x : LibC::Short
    y : LibC::Short
    dx : LibC::Short
    dy : LibC::Short

    # Bounding box for each child,
    # clip against view frustum.
    bbox : LibC::Short[4][2]

    # If NF_SUBSECTOR its a subsector,
    # else it's a node of another subtree.
    children : LibC::UShort[2]
  end

  # Thing definition, position, orientation and type,
  # plus skill/visibility flags and attributes.
  struct Mapthing
    x : LibC::Short
    y : LibC::Short
    angle : LibC::Short
    type : LibC::Short
    options : LibC::Short
  end

  # __DSTRINGS__

  # All important printed strings.
  # Language selection (message strings).
  # Use -DFRENCH etc.

  {% if @top_level.has_constant?("FRENCH") %}
    # require "./d_french.cr" # Leave the extra space there, to throw off regex in PureDOOM.h creation
  {% else %}
    # require "./d_englsh.cr"
  {% end %}

  # Misc. other strings.
  SAVEGAMENAME = "doomsav"

  #
  # File locations,
  #  relative to current position.
  # Path names are OS-sensitive.
  #
  DEVMAPS = "devmaps"
  DEVDATA = "devdata"

  # Not done in french?

  # QuitDOOM messages
  NUM_QUITMESSAGES = 22

  $doom1_endmsg : LibC::Char*[8]
  $doom2_endmsg : LibC::Char*[8]

  # __F_FINALE__

  #
  # FINALE
  #

  # Called by main loop.
  fun f_responder = F_Responder(ev : Event*) : DoomBool

  # Called by main loop.
  fun f_ticker = F_Ticker

  # Called by main loop.
  fun f_drawer = F_Drawer

  fun f_start_finale = F_StartFinale

  # __F_WIPE_H__

  #
  # SCREEN WIPE PACKAGE
  #

  # simple gradual pixel change for 8-bit only
  WIPE_COLORXFORM = 0
  # weird screen melt
  WIPE_MELT     = 1
  WIPE_NUMWIPES = 2

  fun wipe_start_screen = wipe_StartScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  fun wipe_end_screen = wipe_EndScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int
  fun wipe_screen_wipe = wipe_ScreenWipe(wipeno : LibC::Int, x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  # __G_GAME__

  #
  # GAME
  #
  fun g_deathmatch_spawn_player = G_DeathMatchSpawnPlayer(playernum : LibC::Int)

  fun g_init_new = G_InitNew(skill : Skill, episode : LibC::Int, map : LibC::Int)

  # Can be called by the startup code or M_Responder.
  # A normal game starts at map 1,
  # but a warp test can start elsewhere
  fun g_defered_init_new = G_DeferedInitNew(skill : Skill, episode : LibC::Int, map : LibC::Int)

  fun g_defered_play_demo = G_DeferedPlayDemo(demo : LibC::Char*)

  # Can be called by the startup code or M_Responder,
  # calls P_SetupLevel or W_EnterWorld.
  fun g_load_game = G_LoadGame(name : LibC::Char*)

  fun g_do_load_game = G_DoLoadGame

  # Called by M_Responder.
  fun g_save_game = G_SaveGame(slot : LibC::Int, description : LibC::Char*)

  # Only called by startup code.
  fun g_record_demo = G_RecordDemo(name : LibC::Char*)

  fun g_begin_recording = G_BeginRecording

  fun g_time_demo = G_TimeDemo(name : LibC::Char*)
  fun g_check_demo_status = G_CheckDemoStatus : DoomBool

  fun g_exit_level = G_ExitLevel
  fun g_secret_exit_level = G_SecretExitLevel

  fun g_world_done = G_WorldDone

  fun g_ticker = G_Ticker
  fun g_responder = G_Responder(ev : Event*) : DoomBool

  fun g_screenshot = G_ScreenShot

  # __HU_STUFF_H__

  #
  # Globally visible constants.
  HU_FONTSTART = 33 # the first font characters
  HU_FONTEND   = 95 # the last font characters

  # Calculate # of glyphs in font.
  HU_FONTSIZE = (HU_FONTEND - HU_FONTSTART + 1)

  HU_BROADCAST = 5

  HU_MSGREFRESH = KEY_ENTER
  HU_MSGX       =  0
  HU_MSGY       =  0
  HU_MSGWIDTH   = 64 # in characters
  HU_MSGHEIGHT  =  1 # in lines

  HU_MSGTIMEOUT = (4*TICRATE)

  #
  # HEADS UP TEXT
  #

  fun hu_init = HU_Init
  fun hu_start = HU_Start
  fun hu_responder = HU_Responder(ev : Event*) : DoomBool
  fun hu_ticker = HU_Ticker
  fun hu_drawer = HU_Drawer
  fun hu_dequeue_chat_char = HU_dequeueChatChar : LibC::Char
  fun hu_erase = HU_Erase

  # __I_NET__

  # Called by D_DoomMain

  fun i_init_network = I_InitNetwork
  fun i_net_cmd = I_NetCmd

  # __I_SYSTEM__

  # Called by DoomMain.
  fun i_init = I_Init

  # Called by startup code
  # to get the ammount of memory to malloc
  # for the zone management.
  fun i_zone_base = I_ZoneBase(size : LibC::Int*) : Byte*

  # Called by D_DoomLoop,
  # returns current time in tics.
  fun i_get_time = I_GetTime : LibC::Int

  # Called by D_DoomLoop,
  # called before processing any tics in a frame
  # (just after displaying a frame).
  # Time consuming syncronous operations
  # are performed here (joystick reading).
  # Can call D_PostEvent.
  fun i_start_frame = I_StartFrame

  # Called by D_DoomLoop,
  # called before processing each tic in a frame.
  # Quick syncronous operations are performed here.
  # Can call D_PostEvent.
  fun i_start_tic = I_StartTic

  # Asynchronous interrupt functions should maintain private queues
  # that are read by the synchronous functions
  # to be converted into events.

  # Either returns a null ticcmd,
  # or calls a loadable driver to build it.
  # This ticcmd will then be modified by the gameloop
  # for normal input.
  fun i_base_ticcmd = I_BaseTiccmd : Ticcmd*

  # Called by M_Responder when quit is selected.
  # Clean exit, displays sell blurb.
  fun i_quit = I_Quit

  # Allocates from low memory under dos,
  # just mallocs under unix
  fun i_alloc_low = I_AllocLow(length : LibC::Int) : Byte*

  fun i_tactile = I_Tactile(on : LibC::Int, off : LibC::Int, total : LibC::Int)

  fun i_error = I_Error(error : LibC::Char*)

  # __I_VIDEO__

  # Called by D_DoomMain,
  # determines the hardware configuration
  # and sets up the video mode
  fun i_init_graphics = I_InitGraphics

  fun i_shutdown_graphics = I_ShutdownGraphics

  # Takes full 8 bit values.
  fun i_set_palette = I_SetPalette(palette : Byte*)

  fun i_update_no_blit = I_UpdateNoBlit
  fun i_finish_update = I_FinishUpdate

  # Wait for vertical retrace or pause a bit.
  fun i_wait_vbl = I_WaitVBL(count : LibC::Int)

  fun i_read_screen = I_ReadScreen(scr : Byte*)

  fun i_begin_read = I_BeginRead
  fun i_end_read = I_EndRead

  # __INFO__

  enum Spritenum
    SPR_TROO
    SPR_SHTG
    SPR_PUNG
    SPR_PISG
    SPR_PISF
    SPR_SHTF
    SPR_SHT2
    SPR_CHGG
    SPR_CHGF
    SPR_MISG
    SPR_MISF
    SPR_SAWG
    SPR_PLSG
    SPR_PLSF
    SPR_BFGG
    SPR_BFGF
    SPR_BLUD
    SPR_PUFF
    SPR_BAL1
    SPR_BAL2
    SPR_PLSS
    SPR_PLSE
    SPR_MISL
    SPR_BFS1
    SPR_BFE1
    SPR_BFE2
    SPR_TFOG
    SPR_IFOG
    SPR_PLAY
    SPR_POSS
    SPR_SPOS
    SPR_VILE
    SPR_FIRE
    SPR_FATB
    SPR_FBXP
    SPR_SKEL
    SPR_MANF
    SPR_FATT
    SPR_CPOS
    SPR_SARG
    SPR_HEAD
    SPR_BAL7
    SPR_BOSS
    SPR_BOS2
    SPR_SKUL
    SPR_SPID
    SPR_BSPI
    SPR_APLS
    SPR_APBX
    SPR_CYBR
    SPR_PAIN
    SPR_SSWV
    SPR_KEEN
    SPR_BBRN
    SPR_BOSF
    SPR_ARM1
    SPR_ARM2
    SPR_BAR1
    SPR_BEXP
    SPR_FCAN
    SPR_BON1
    SPR_BON2
    SPR_BKEY
    SPR_RKEY
    SPR_YKEY
    SPR_BSKU
    SPR_RSKU
    SPR_YSKU
    SPR_STIM
    SPR_MEDI
    SPR_SOUL
    SPR_PINV
    SPR_PSTR
    SPR_PINS
    SPR_MEGA
    SPR_SUIT
    SPR_PMAP
    SPR_PVIS
    SPR_CLIP
    SPR_AMMO
    SPR_ROCK
    SPR_BROK
    SPR_CELL
    SPR_CELP
    SPR_SHEL
    SPR_SBOX
    SPR_BPAK
    SPR_BFUG
    SPR_MGUN
    SPR_CSAW
    SPR_LAUN
    SPR_PLAS
    SPR_SHOT
    SPR_SGN2
    SPR_COLU
    SPR_SMT2
    SPR_GOR1
    SPR_POL2
    SPR_POL5
    SPR_POL4
    SPR_POL3
    SPR_POL1
    SPR_POL6
    SPR_GOR2
    SPR_GOR3
    SPR_GOR4
    SPR_GOR5
    SPR_SMIT
    SPR_COL1
    SPR_COL2
    SPR_COL3
    SPR_COL4
    SPR_CAND
    SPR_CBRA
    SPR_COL6
    SPR_TRE1
    SPR_TRE2
    SPR_ELEC
    SPR_CEYE
    SPR_FSKU
    SPR_COL5
    SPR_TBLU
    SPR_TGRN
    SPR_TRED
    SPR_SMBT
    SPR_SMGT
    SPR_SMRT
    SPR_HDB1
    SPR_HDB2
    SPR_HDB3
    SPR_HDB4
    SPR_HDB5
    SPR_HDB6
    SPR_POB1
    SPR_POB2
    SPR_BRS1
    SPR_TLMP
    SPR_TLP2
    NUMSPRITES
  end

  enum Statenum
    S_NULL
    S_LIGHTDONE
    S_PUNCH
    S_PUNCHDOWN
    S_PUNCHUP
    S_PUNCH1
    S_PUNCH2
    S_PUNCH3
    S_PUNCH4
    S_PUNCH5
    S_PISTOL
    S_PISTOLDOWN
    S_PISTOLUP
    S_PISTOL1
    S_PISTOL2
    S_PISTOL3
    S_PISTOL4
    S_PISTOLFLASH
    S_SGUN
    S_SGUNDOWN
    S_SGUNUP
    S_SGUN1
    S_SGUN2
    S_SGUN3
    S_SGUN4
    S_SGUN5
    S_SGUN6
    S_SGUN7
    S_SGUN8
    S_SGUN9
    S_SGUNFLASH1
    S_SGUNFLASH2
    S_DSGUN
    S_DSGUNDOWN
    S_DSGUNUP
    S_DSGUN1
    S_DSGUN2
    S_DSGUN3
    S_DSGUN4
    S_DSGUN5
    S_DSGUN6
    S_DSGUN7
    S_DSGUN8
    S_DSGUN9
    S_DSGUN10
    S_DSNR1
    S_DSNR2
    S_DSGUNFLASH1
    S_DSGUNFLASH2
    S_CHAIN
    S_CHAINDOWN
    S_CHAINUP
    S_CHAIN1
    S_CHAIN2
    S_CHAIN3
    S_CHAINFLASH1
    S_CHAINFLASH2
    S_MISSILE
    S_MISSILEDOWN
    S_MISSILEUP
    S_MISSILE1
    S_MISSILE2
    S_MISSILE3
    S_MISSILEFLASH1
    S_MISSILEFLASH2
    S_MISSILEFLASH3
    S_MISSILEFLASH4
    S_SAW
    S_SAWB
    S_SAWDOWN
    S_SAWUP
    S_SAW1
    S_SAW2
    S_SAW3
    S_PLASMA
    S_PLASMADOWN
    S_PLASMAUP
    S_PLASMA1
    S_PLASMA2
    S_PLASMAFLASH1
    S_PLASMAFLASH2
    S_BFG
    S_BFGDOWN
    S_BFGUP
    S_BFG1
    S_BFG2
    S_BFG3
    S_BFG4
    S_BFGFLASH1
    S_BFGFLASH2
    S_BLOOD1
    S_BLOOD2
    S_BLOOD3
    S_PUFF1
    S_PUFF2
    S_PUFF3
    S_PUFF4
    S_TBALL1
    S_TBALL2
    S_TBALLX1
    S_TBALLX2
    S_TBALLX3
    S_RBALL1
    S_RBALL2
    S_RBALLX1
    S_RBALLX2
    S_RBALLX3
    S_PLASBALL
    S_PLASBALL2
    S_PLASEXP
    S_PLASEXP2
    S_PLASEXP3
    S_PLASEXP4
    S_PLASEXP5
    S_ROCKET
    S_BFGSHOT
    S_BFGSHOT2
    S_BFGLAND
    S_BFGLAND2
    S_BFGLAND3
    S_BFGLAND4
    S_BFGLAND5
    S_BFGLAND6
    S_BFGEXP
    S_BFGEXP2
    S_BFGEXP3
    S_BFGEXP4
    S_EXPLODE1
    S_EXPLODE2
    S_EXPLODE3
    S_TFOG
    S_TFOG01
    S_TFOG02
    S_TFOG2
    S_TFOG3
    S_TFOG4
    S_TFOG5
    S_TFOG6
    S_TFOG7
    S_TFOG8
    S_TFOG9
    S_TFOG10
    S_IFOG
    S_IFOG01
    S_IFOG02
    S_IFOG2
    S_IFOG3
    S_IFOG4
    S_IFOG5
    S_PLAY
    S_PLAY_RUN1
    S_PLAY_RUN2
    S_PLAY_RUN3
    S_PLAY_RUN4
    S_PLAY_ATK1
    S_PLAY_ATK2
    S_PLAY_PAIN
    S_PLAY_PAIN2
    S_PLAY_DIE1
    S_PLAY_DIE2
    S_PLAY_DIE3
    S_PLAY_DIE4
    S_PLAY_DIE5
    S_PLAY_DIE6
    S_PLAY_DIE7
    S_PLAY_XDIE1
    S_PLAY_XDIE2
    S_PLAY_XDIE3
    S_PLAY_XDIE4
    S_PLAY_XDIE5
    S_PLAY_XDIE6
    S_PLAY_XDIE7
    S_PLAY_XDIE8
    S_PLAY_XDIE9
    S_POSS_STND
    S_POSS_STND2
    S_POSS_RUN1
    S_POSS_RUN2
    S_POSS_RUN3
    S_POSS_RUN4
    S_POSS_RUN5
    S_POSS_RUN6
    S_POSS_RUN7
    S_POSS_RUN8
    S_POSS_ATK1
    S_POSS_ATK2
    S_POSS_ATK3
    S_POSS_PAIN
    S_POSS_PAIN2
    S_POSS_DIE1
    S_POSS_DIE2
    S_POSS_DIE3
    S_POSS_DIE4
    S_POSS_DIE5
    S_POSS_XDIE1
    S_POSS_XDIE2
    S_POSS_XDIE3
    S_POSS_XDIE4
    S_POSS_XDIE5
    S_POSS_XDIE6
    S_POSS_XDIE7
    S_POSS_XDIE8
    S_POSS_XDIE9
    S_POSS_RAISE1
    S_POSS_RAISE2
    S_POSS_RAISE3
    S_POSS_RAISE4
    S_SPOS_STND
    S_SPOS_STND2
    S_SPOS_RUN1
    S_SPOS_RUN2
    S_SPOS_RUN3
    S_SPOS_RUN4
    S_SPOS_RUN5
    S_SPOS_RUN6
    S_SPOS_RUN7
    S_SPOS_RUN8
    S_SPOS_ATK1
    S_SPOS_ATK2
    S_SPOS_ATK3
    S_SPOS_PAIN
    S_SPOS_PAIN2
    S_SPOS_DIE1
    S_SPOS_DIE2
    S_SPOS_DIE3
    S_SPOS_DIE4
    S_SPOS_DIE5
    S_SPOS_XDIE1
    S_SPOS_XDIE2
    S_SPOS_XDIE3
    S_SPOS_XDIE4
    S_SPOS_XDIE5
    S_SPOS_XDIE6
    S_SPOS_XDIE7
    S_SPOS_XDIE8
    S_SPOS_XDIE9
    S_SPOS_RAISE1
    S_SPOS_RAISE2
    S_SPOS_RAISE3
    S_SPOS_RAISE4
    S_SPOS_RAISE5
    S_VILE_STND
    S_VILE_STND2
    S_VILE_RUN1
    S_VILE_RUN2
    S_VILE_RUN3
    S_VILE_RUN4
    S_VILE_RUN5
    S_VILE_RUN6
    S_VILE_RUN7
    S_VILE_RUN8
    S_VILE_RUN9
    S_VILE_RUN10
    S_VILE_RUN11
    S_VILE_RUN12
    S_VILE_ATK1
    S_VILE_ATK2
    S_VILE_ATK3
    S_VILE_ATK4
    S_VILE_ATK5
    S_VILE_ATK6
    S_VILE_ATK7
    S_VILE_ATK8
    S_VILE_ATK9
    S_VILE_ATK10
    S_VILE_ATK11
    S_VILE_HEAL1
    S_VILE_HEAL2
    S_VILE_HEAL3
    S_VILE_PAIN
    S_VILE_PAIN2
    S_VILE_DIE1
    S_VILE_DIE2
    S_VILE_DIE3
    S_VILE_DIE4
    S_VILE_DIE5
    S_VILE_DIE6
    S_VILE_DIE7
    S_VILE_DIE8
    S_VILE_DIE9
    S_VILE_DIE10
    S_FIRE1
    S_FIRE2
    S_FIRE3
    S_FIRE4
    S_FIRE5
    S_FIRE6
    S_FIRE7
    S_FIRE8
    S_FIRE9
    S_FIRE10
    S_FIRE11
    S_FIRE12
    S_FIRE13
    S_FIRE14
    S_FIRE15
    S_FIRE16
    S_FIRE17
    S_FIRE18
    S_FIRE19
    S_FIRE20
    S_FIRE21
    S_FIRE22
    S_FIRE23
    S_FIRE24
    S_FIRE25
    S_FIRE26
    S_FIRE27
    S_FIRE28
    S_FIRE29
    S_FIRE30
    S_SMOKE1
    S_SMOKE2
    S_SMOKE3
    S_SMOKE4
    S_SMOKE5
    S_TRACER
    S_TRACER2
    S_TRACEEXP1
    S_TRACEEXP2
    S_TRACEEXP3
    S_SKEL_STND
    S_SKEL_STND2
    S_SKEL_RUN1
    S_SKEL_RUN2
    S_SKEL_RUN3
    S_SKEL_RUN4
    S_SKEL_RUN5
    S_SKEL_RUN6
    S_SKEL_RUN7
    S_SKEL_RUN8
    S_SKEL_RUN9
    S_SKEL_RUN10
    S_SKEL_RUN11
    S_SKEL_RUN12
    S_SKEL_FIST1
    S_SKEL_FIST2
    S_SKEL_FIST3
    S_SKEL_FIST4
    S_SKEL_MISS1
    S_SKEL_MISS2
    S_SKEL_MISS3
    S_SKEL_MISS4
    S_SKEL_PAIN
    S_SKEL_PAIN2
    S_SKEL_DIE1
    S_SKEL_DIE2
    S_SKEL_DIE3
    S_SKEL_DIE4
    S_SKEL_DIE5
    S_SKEL_DIE6
    S_SKEL_RAISE1
    S_SKEL_RAISE2
    S_SKEL_RAISE3
    S_SKEL_RAISE4
    S_SKEL_RAISE5
    S_SKEL_RAISE6
    S_FATSHOT1
    S_FATSHOT2
    S_FATSHOTX1
    S_FATSHOTX2
    S_FATSHOTX3
    S_FATT_STND
    S_FATT_STND2
    S_FATT_RUN1
    S_FATT_RUN2
    S_FATT_RUN3
    S_FATT_RUN4
    S_FATT_RUN5
    S_FATT_RUN6
    S_FATT_RUN7
    S_FATT_RUN8
    S_FATT_RUN9
    S_FATT_RUN10
    S_FATT_RUN11
    S_FATT_RUN12
    S_FATT_ATK1
    S_FATT_ATK2
    S_FATT_ATK3
    S_FATT_ATK4
    S_FATT_ATK5
    S_FATT_ATK6
    S_FATT_ATK7
    S_FATT_ATK8
    S_FATT_ATK9
    S_FATT_ATK10
    S_FATT_PAIN
    S_FATT_PAIN2
    S_FATT_DIE1
    S_FATT_DIE2
    S_FATT_DIE3
    S_FATT_DIE4
    S_FATT_DIE5
    S_FATT_DIE6
    S_FATT_DIE7
    S_FATT_DIE8
    S_FATT_DIE9
    S_FATT_DIE10
    S_FATT_RAISE1
    S_FATT_RAISE2
    S_FATT_RAISE3
    S_FATT_RAISE4
    S_FATT_RAISE5
    S_FATT_RAISE6
    S_FATT_RAISE7
    S_FATT_RAISE8
    S_CPOS_STND
    S_CPOS_STND2
    S_CPOS_RUN1
    S_CPOS_RUN2
    S_CPOS_RUN3
    S_CPOS_RUN4
    S_CPOS_RUN5
    S_CPOS_RUN6
    S_CPOS_RUN7
    S_CPOS_RUN8
    S_CPOS_ATK1
    S_CPOS_ATK2
    S_CPOS_ATK3
    S_CPOS_ATK4
    S_CPOS_PAIN
    S_CPOS_PAIN2
    S_CPOS_DIE1
    S_CPOS_DIE2
    S_CPOS_DIE3
    S_CPOS_DIE4
    S_CPOS_DIE5
    S_CPOS_DIE6
    S_CPOS_DIE7
    S_CPOS_XDIE1
    S_CPOS_XDIE2
    S_CPOS_XDIE3
    S_CPOS_XDIE4
    S_CPOS_XDIE5
    S_CPOS_XDIE6
    S_CPOS_RAISE1
    S_CPOS_RAISE2
    S_CPOS_RAISE3
    S_CPOS_RAISE4
    S_CPOS_RAISE5
    S_CPOS_RAISE6
    S_CPOS_RAISE7
    S_TROO_STND
    S_TROO_STND2
    S_TROO_RUN1
    S_TROO_RUN2
    S_TROO_RUN3
    S_TROO_RUN4
    S_TROO_RUN5
    S_TROO_RUN6
    S_TROO_RUN7
    S_TROO_RUN8
    S_TROO_ATK1
    S_TROO_ATK2
    S_TROO_ATK3
    S_TROO_PAIN
    S_TROO_PAIN2
    S_TROO_DIE1
    S_TROO_DIE2
    S_TROO_DIE3
    S_TROO_DIE4
    S_TROO_DIE5
    S_TROO_XDIE1
    S_TROO_XDIE2
    S_TROO_XDIE3
    S_TROO_XDIE4
    S_TROO_XDIE5
    S_TROO_XDIE6
    S_TROO_XDIE7
    S_TROO_XDIE8
    S_TROO_RAISE1
    S_TROO_RAISE2
    S_TROO_RAISE3
    S_TROO_RAISE4
    S_TROO_RAISE5
    S_SARG_STND
    S_SARG_STND2
    S_SARG_RUN1
    S_SARG_RUN2
    S_SARG_RUN3
    S_SARG_RUN4
    S_SARG_RUN5
    S_SARG_RUN6
    S_SARG_RUN7
    S_SARG_RUN8
    S_SARG_ATK1
    S_SARG_ATK2
    S_SARG_ATK3
    S_SARG_PAIN
    S_SARG_PAIN2
    S_SARG_DIE1
    S_SARG_DIE2
    S_SARG_DIE3
    S_SARG_DIE4
    S_SARG_DIE5
    S_SARG_DIE6
    S_SARG_RAISE1
    S_SARG_RAISE2
    S_SARG_RAISE3
    S_SARG_RAISE4
    S_SARG_RAISE5
    S_SARG_RAISE6
    S_HEAD_STND
    S_HEAD_RUN1
    S_HEAD_ATK1
    S_HEAD_ATK2
    S_HEAD_ATK3
    S_HEAD_PAIN
    S_HEAD_PAIN2
    S_HEAD_PAIN3
    S_HEAD_DIE1
    S_HEAD_DIE2
    S_HEAD_DIE3
    S_HEAD_DIE4
    S_HEAD_DIE5
    S_HEAD_DIE6
    S_HEAD_RAISE1
    S_HEAD_RAISE2
    S_HEAD_RAISE3
    S_HEAD_RAISE4
    S_HEAD_RAISE5
    S_HEAD_RAISE6
    S_BRBALL1
    S_BRBALL2
    S_BRBALLX1
    S_BRBALLX2
    S_BRBALLX3
    S_BOSS_STND
    S_BOSS_STND2
    S_BOSS_RUN1
    S_BOSS_RUN2
    S_BOSS_RUN3
    S_BOSS_RUN4
    S_BOSS_RUN5
    S_BOSS_RUN6
    S_BOSS_RUN7
    S_BOSS_RUN8
    S_BOSS_ATK1
    S_BOSS_ATK2
    S_BOSS_ATK3
    S_BOSS_PAIN
    S_BOSS_PAIN2
    S_BOSS_DIE1
    S_BOSS_DIE2
    S_BOSS_DIE3
    S_BOSS_DIE4
    S_BOSS_DIE5
    S_BOSS_DIE6
    S_BOSS_DIE7
    S_BOSS_RAISE1
    S_BOSS_RAISE2
    S_BOSS_RAISE3
    S_BOSS_RAISE4
    S_BOSS_RAISE5
    S_BOSS_RAISE6
    S_BOSS_RAISE7
    S_BOS2_STND
    S_BOS2_STND2
    S_BOS2_RUN1
    S_BOS2_RUN2
    S_BOS2_RUN3
    S_BOS2_RUN4
    S_BOS2_RUN5
    S_BOS2_RUN6
    S_BOS2_RUN7
    S_BOS2_RUN8
    S_BOS2_ATK1
    S_BOS2_ATK2
    S_BOS2_ATK3
    S_BOS2_PAIN
    S_BOS2_PAIN2
    S_BOS2_DIE1
    S_BOS2_DIE2
    S_BOS2_DIE3
    S_BOS2_DIE4
    S_BOS2_DIE5
    S_BOS2_DIE6
    S_BOS2_DIE7
    S_BOS2_RAISE1
    S_BOS2_RAISE2
    S_BOS2_RAISE3
    S_BOS2_RAISE4
    S_BOS2_RAISE5
    S_BOS2_RAISE6
    S_BOS2_RAISE7
    S_SKULL_STND
    S_SKULL_STND2
    S_SKULL_RUN1
    S_SKULL_RUN2
    S_SKULL_ATK1
    S_SKULL_ATK2
    S_SKULL_ATK3
    S_SKULL_ATK4
    S_SKULL_PAIN
    S_SKULL_PAIN2
    S_SKULL_DIE1
    S_SKULL_DIE2
    S_SKULL_DIE3
    S_SKULL_DIE4
    S_SKULL_DIE5
    S_SKULL_DIE6
    S_SPID_STND
    S_SPID_STND2
    S_SPID_RUN1
    S_SPID_RUN2
    S_SPID_RUN3
    S_SPID_RUN4
    S_SPID_RUN5
    S_SPID_RUN6
    S_SPID_RUN7
    S_SPID_RUN8
    S_SPID_RUN9
    S_SPID_RUN10
    S_SPID_RUN11
    S_SPID_RUN12
    S_SPID_ATK1
    S_SPID_ATK2
    S_SPID_ATK3
    S_SPID_ATK4
    S_SPID_PAIN
    S_SPID_PAIN2
    S_SPID_DIE1
    S_SPID_DIE2
    S_SPID_DIE3
    S_SPID_DIE4
    S_SPID_DIE5
    S_SPID_DIE6
    S_SPID_DIE7
    S_SPID_DIE8
    S_SPID_DIE9
    S_SPID_DIE10
    S_SPID_DIE11
    S_BSPI_STND
    S_BSPI_STND2
    S_BSPI_SIGHT
    S_BSPI_RUN1
    S_BSPI_RUN2
    S_BSPI_RUN3
    S_BSPI_RUN4
    S_BSPI_RUN5
    S_BSPI_RUN6
    S_BSPI_RUN7
    S_BSPI_RUN8
    S_BSPI_RUN9
    S_BSPI_RUN10
    S_BSPI_RUN11
    S_BSPI_RUN12
    S_BSPI_ATK1
    S_BSPI_ATK2
    S_BSPI_ATK3
    S_BSPI_ATK4
    S_BSPI_PAIN
    S_BSPI_PAIN2
    S_BSPI_DIE1
    S_BSPI_DIE2
    S_BSPI_DIE3
    S_BSPI_DIE4
    S_BSPI_DIE5
    S_BSPI_DIE6
    S_BSPI_DIE7
    S_BSPI_RAISE1
    S_BSPI_RAISE2
    S_BSPI_RAISE3
    S_BSPI_RAISE4
    S_BSPI_RAISE5
    S_BSPI_RAISE6
    S_BSPI_RAISE7
    S_ARACH_PLAZ
    S_ARACH_PLAZ2
    S_ARACH_PLEX
    S_ARACH_PLEX2
    S_ARACH_PLEX3
    S_ARACH_PLEX4
    S_ARACH_PLEX5
    S_CYBER_STND
    S_CYBER_STND2
    S_CYBER_RUN1
    S_CYBER_RUN2
    S_CYBER_RUN3
    S_CYBER_RUN4
    S_CYBER_RUN5
    S_CYBER_RUN6
    S_CYBER_RUN7
    S_CYBER_RUN8
    S_CYBER_ATK1
    S_CYBER_ATK2
    S_CYBER_ATK3
    S_CYBER_ATK4
    S_CYBER_ATK5
    S_CYBER_ATK6
    S_CYBER_PAIN
    S_CYBER_DIE1
    S_CYBER_DIE2
    S_CYBER_DIE3
    S_CYBER_DIE4
    S_CYBER_DIE5
    S_CYBER_DIE6
    S_CYBER_DIE7
    S_CYBER_DIE8
    S_CYBER_DIE9
    S_CYBER_DIE10
    S_PAIN_STND
    S_PAIN_RUN1
    S_PAIN_RUN2
    S_PAIN_RUN3
    S_PAIN_RUN4
    S_PAIN_RUN5
    S_PAIN_RUN6
    S_PAIN_ATK1
    S_PAIN_ATK2
    S_PAIN_ATK3
    S_PAIN_ATK4
    S_PAIN_PAIN
    S_PAIN_PAIN2
    S_PAIN_DIE1
    S_PAIN_DIE2
    S_PAIN_DIE3
    S_PAIN_DIE4
    S_PAIN_DIE5
    S_PAIN_DIE6
    S_PAIN_RAISE1
    S_PAIN_RAISE2
    S_PAIN_RAISE3
    S_PAIN_RAISE4
    S_PAIN_RAISE5
    S_PAIN_RAISE6
    S_SSWV_STND
    S_SSWV_STND2
    S_SSWV_RUN1
    S_SSWV_RUN2
    S_SSWV_RUN3
    S_SSWV_RUN4
    S_SSWV_RUN5
    S_SSWV_RUN6
    S_SSWV_RUN7
    S_SSWV_RUN8
    S_SSWV_ATK1
    S_SSWV_ATK2
    S_SSWV_ATK3
    S_SSWV_ATK4
    S_SSWV_ATK5
    S_SSWV_ATK6
    S_SSWV_PAIN
    S_SSWV_PAIN2
    S_SSWV_DIE1
    S_SSWV_DIE2
    S_SSWV_DIE3
    S_SSWV_DIE4
    S_SSWV_DIE5
    S_SSWV_XDIE1
    S_SSWV_XDIE2
    S_SSWV_XDIE3
    S_SSWV_XDIE4
    S_SSWV_XDIE5
    S_SSWV_XDIE6
    S_SSWV_XDIE7
    S_SSWV_XDIE8
    S_SSWV_XDIE9
    S_SSWV_RAISE1
    S_SSWV_RAISE2
    S_SSWV_RAISE3
    S_SSWV_RAISE4
    S_SSWV_RAISE5
    S_KEENSTND
    S_COMMKEEN
    S_COMMKEEN2
    S_COMMKEEN3
    S_COMMKEEN4
    S_COMMKEEN5
    S_COMMKEEN6
    S_COMMKEEN7
    S_COMMKEEN8
    S_COMMKEEN9
    S_COMMKEEN10
    S_COMMKEEN11
    S_COMMKEEN12
    S_KEENPAIN
    S_KEENPAIN2
    S_BRAIN
    S_BRAIN_PAIN
    S_BRAIN_DIE1
    S_BRAIN_DIE2
    S_BRAIN_DIE3
    S_BRAIN_DIE4
    S_BRAINEYE
    S_BRAINEYESEE
    S_BRAINEYE1
    S_SPAWN1
    S_SPAWN2
    S_SPAWN3
    S_SPAWN4
    S_SPAWNFIRE1
    S_SPAWNFIRE2
    S_SPAWNFIRE3
    S_SPAWNFIRE4
    S_SPAWNFIRE5
    S_SPAWNFIRE6
    S_SPAWNFIRE7
    S_SPAWNFIRE8
    S_BRAINEXPLODE1
    S_BRAINEXPLODE2
    S_BRAINEXPLODE3
    S_ARM1
    S_ARM1A
    S_ARM2
    S_ARM2A
    S_BAR1
    S_BAR2
    S_BEXP
    S_BEXP2
    S_BEXP3
    S_BEXP4
    S_BEXP5
    S_BBAR1
    S_BBAR2
    S_BBAR3
    S_BON1
    S_BON1A
    S_BON1B
    S_BON1C
    S_BON1D
    S_BON1E
    S_BON2
    S_BON2A
    S_BON2B
    S_BON2C
    S_BON2D
    S_BON2E
    S_BKEY
    S_BKEY2
    S_RKEY
    S_RKEY2
    S_YKEY
    S_YKEY2
    S_BSKULL
    S_BSKULL2
    S_RSKULL
    S_RSKULL2
    S_YSKULL
    S_YSKULL2
    S_STIM
    S_MEDI
    S_SOUL
    S_SOUL2
    S_SOUL3
    S_SOUL4
    S_SOUL5
    S_SOUL6
    S_PINV
    S_PINV2
    S_PINV3
    S_PINV4
    S_PSTR
    S_PINS
    S_PINS2
    S_PINS3
    S_PINS4
    S_MEGA
    S_MEGA2
    S_MEGA3
    S_MEGA4
    S_SUIT
    S_PMAP
    S_PMAP2
    S_PMAP3
    S_PMAP4
    S_PMAP5
    S_PMAP6
    S_PVIS
    S_PVIS2
    S_CLIP
    S_AMMO
    S_ROCK
    S_BROK
    S_CELL
    S_CELP
    S_SHEL
    S_SBOX
    S_BPAK
    S_BFUG
    S_MGUN
    S_CSAW
    S_LAUN
    S_PLAS
    S_SHOT
    S_SHOT2
    S_COLU
    S_STALAG
    S_BLOODYTWITCH
    S_BLOODYTWITCH2
    S_BLOODYTWITCH3
    S_BLOODYTWITCH4
    S_DEADTORSO
    S_DEADBOTTOM
    S_HEADSONSTICK
    S_GIBS
    S_HEADONASTICK
    S_HEADCANDLES
    S_HEADCANDLES2
    S_DEADSTICK
    S_LIVESTICK
    S_LIVESTICK2
    S_MEAT2
    S_MEAT3
    S_MEAT4
    S_MEAT5
    S_STALAGTITE
    S_TALLGRNCOL
    S_SHRTGRNCOL
    S_TALLREDCOL
    S_SHRTREDCOL
    S_CANDLESTIK
    S_CANDELABRA
    S_SKULLCOL
    S_TORCHTREE
    S_BIGTREE
    S_TECHPILLAR
    S_EVILEYE
    S_EVILEYE2
    S_EVILEYE3
    S_EVILEYE4
    S_FLOATSKULL
    S_FLOATSKULL2
    S_FLOATSKULL3
    S_HEARTCOL
    S_HEARTCOL2
    S_BLUETORCH
    S_BLUETORCH2
    S_BLUETORCH3
    S_BLUETORCH4
    S_GREENTORCH
    S_GREENTORCH2
    S_GREENTORCH3
    S_GREENTORCH4
    S_REDTORCH
    S_REDTORCH2
    S_REDTORCH3
    S_REDTORCH4
    S_BTORCHSHRT
    S_BTORCHSHRT2
    S_BTORCHSHRT3
    S_BTORCHSHRT4
    S_GTORCHSHRT
    S_GTORCHSHRT2
    S_GTORCHSHRT3
    S_GTORCHSHRT4
    S_RTORCHSHRT
    S_RTORCHSHRT2
    S_RTORCHSHRT3
    S_RTORCHSHRT4
    S_HANGNOGUTS
    S_HANGBNOBRAIN
    S_HANGTLOOKDN
    S_HANGTSKULL
    S_HANGTLOOKUP
    S_HANGTNOBRAIN
    S_COLONGIBS
    S_SMALLPOOL
    S_BRAINSTEM
    S_TECHLAMP
    S_TECHLAMP2
    S_TECHLAMP3
    S_TECHLAMP4
    S_TECH2LAMP
    S_TECH2LAMP2
    S_TECH2LAMP3
    S_TECH2LAMP4
    NUMSTATES
  end

  struct State
    sprite : Spritenum
    frame : LibC::Long
    tics : LibC::Long
    action : Void*
    nextstate : Statenum
    misc1 : LibC::Long
    misc2 : LibC::Long
  end

  $states : State*
  NUMSPRITES_PLUS_1 = Spritenum::NUMSPRITES + 1 # Weird Crystal moment
  $sprnames : LibC::Char**

  enum Mobjtype
    MT_PLAYER
    MT_POSSESSED
    MT_SHOTGUY
    MT_VILE
    MT_FIRE
    MT_UNDEAD
    MT_TRACER
    MT_SMOKE
    MT_FATSO
    MT_FATSHOT
    MT_CHAINGUY
    MT_TROOP
    MT_SERGEANT
    MT_SHADOWS
    MT_HEAD
    MT_BRUISER
    MT_BRUISERSHOT
    MT_KNIGHT
    MT_SKULL
    MT_SPIDER
    MT_BABY
    MT_CYBORG
    MT_PAIN
    MT_WOLFSS
    MT_KEEN
    MT_BOSSBRAIN
    MT_BOSSSPIT
    MT_BOSSTARGET
    MT_SPAWNSHOT
    MT_SPAWNFIRE
    MT_BARREL
    MT_TROOPSHOT
    MT_HEADSHOT
    MT_ROCKET
    MT_PLASMA
    MT_BFG
    MT_ARACHPLAZ
    MT_PUFF
    MT_BLOOD
    MT_TFOG
    MT_IFOG
    MT_TELEPORTMAN
    MT_EXTRABFG
    MT_MISC0
    MT_MISC1
    MT_MISC2
    MT_MISC3
    MT_MISC4
    MT_MISC5
    MT_MISC6
    MT_MISC7
    MT_MISC8
    MT_MISC9
    MT_MISC10
    MT_MISC11
    MT_MISC12
    MT_INV
    MT_MISC13
    MT_INS
    MT_MISC14
    MT_MISC15
    MT_MISC16
    MT_MEGA
    MT_CLIP
    MT_MISC17
    MT_MISC18
    MT_MISC19
    MT_MISC20
    MT_MISC21
    MT_MISC22
    MT_MISC23
    MT_MISC24
    MT_MISC25
    MT_CHAINGUN
    MT_MISC26
    MT_MISC27
    MT_MISC28
    MT_SHOTGUN
    MT_SUPERSHOTGUN
    MT_MISC29
    MT_MISC30
    MT_MISC31
    MT_MISC32
    MT_MISC33
    MT_MISC34
    MT_MISC35
    MT_MISC36
    MT_MISC37
    MT_MISC38
    MT_MISC39
    MT_MISC40
    MT_MISC41
    MT_MISC42
    MT_MISC43
    MT_MISC44
    MT_MISC45
    MT_MISC46
    MT_MISC47
    MT_MISC48
    MT_MISC49
    MT_MISC50
    MT_MISC51
    MT_MISC52
    MT_MISC53
    MT_MISC54
    MT_MISC55
    MT_MISC56
    MT_MISC57
    MT_MISC58
    MT_MISC59
    MT_MISC60
    MT_MISC61
    MT_MISC62
    MT_MISC63
    MT_MISC64
    MT_MISC65
    MT_MISC66
    MT_MISC67
    MT_MISC68
    MT_MISC69
    MT_MISC70
    MT_MISC71
    MT_MISC72
    MT_MISC73
    MT_MISC74
    MT_MISC75
    MT_MISC76
    MT_MISC77
    MT_MISC78
    MT_MISC79
    MT_MISC80
    MT_MISC81
    MT_MISC82
    MT_MISC83
    MT_MISC84
    MT_MISC85
    MT_MISC86
    NUMMOBJTYPES
  end

  struct Mobjinfo
    doomednum : LibC::Int
    spawnstate : LibC::Int
    spawnhealth : LibC::Int
    seestate : LibC::Int
    seesound : LibC::Int
    reactiontime : LibC::Int
    attacksound : LibC::Int
    painstate : LibC::Int
    painchance : LibC::Int
    painsound : LibC::Int
    meleestate : LibC::Int
    missilestate : LibC::Int
    deathstate : LibC::Int
    xdeathstate : LibC::Int
    deathsound : LibC::Int
    speed : LibC::Int
    radius : LibC::Int
    height : LibC::Int
    mass : LibC::Int
    damage : LibC::Int
    activesound : LibC::Int
    flags : LibC::Int
    raisestate : LibC::Int
  end

  $mobjinfo : Mobjinfo[Mobjtype::NUMMOBJTYPES]

  # __M__ARGV__

  #
  # MISC
  #
  $myargc : LibC::Int
  $myargv : LibC::Char**

  # Returns the position of the given parameter
  # in the arg list (0 if not found).
  fun m_check_parm = M_CheckParm(check : LibC::Char*) : LibC::Int

  # __M_CHEAT__

  #
  # CHEAT SEQUENCE PACKAGE
  #

  struct Cheatseq
    sequence : LibC::UChar*
    p : LibC::UChar*
  end

  fun cht_check_cheat = cht_CheckCheat(cht : Cheatseq*, key : LibC::Char) : LibC::Int
  fun cht_get_param = cht_GetParam(cht : Cheatseq*, buffer : LibC::Char*)

  # __M_FIXED__

  #
  # Fixed point, 32bit as 16.16.
  #
  FRACBITS = 16
  FRACUNIT = (1 << FRACBITS)

  alias Fixed = LibC::Int

  fun fixed_mul = FixedMul(a : Fixed, b : Fixed) : Fixed
  fun fixed_div = FixedDiv(a : Fixed, b : Fixed) : Fixed
  fun fixed_div2 = FixedDiv2(a : Fixed, b : Fixed) : Fixed

  # __M_BBOX__

  # Bounding box coordinate storage.
  BOXTOP    = 0
  BOXBOTTOM = 1
  BOXLEFT   = 2
  BOXRIGHT  = 3
  # bbox coordinates

  # Bounding box functions
  fun m_clear_box = M_ClearBox(box : Fixed*)
  fun m_add_to_box = M_AddToBox(box : Fixed*, x : Fixed, y : Fixed)

  # __M_MENU__

  #
  # MENUS
  #

  # Called by main loop,
  # saves config file and calls I_Quit when user exits.
  # Even when the menu is not displayed,
  # this can resize the view and change game parameters.
  # Does all the real work of the menu interaction.
  fun m_responder = M_Responder(ev : Event*) : DoomBool

  # Called by main loop,
  # only used for menu (skull cursor) animation.
  fun m_ticker = M_Ticker

  # Called by main loop,
  # draws the menus directly into the screen buffer.
  fun m_drawer = M_Drawer

  # Called by D_DoomMain,
  # loads the config file.
  fun m_init = M_Init

  # Called by intro code to force menu up upon a keypress,
  # does nothing if menu is already up.
  fun m_start_control_panel = M_StartControlPanel

  # __M_MISC__

  #
  # MISC
  #
  struct Default
    name : LibC::Char*
    location : LibC::Int*
    defaultvalue : LibC::Int
    scantranslate : LibC::Int        # PC scan code hack
    untranslated : LibC::Int         # lousy hack
    text_location : LibC::Char**     # [pd] int* location was used to store text pointer. Can't change to intptr_t unless we change all settings type
    default_text_value : LibC::Char* # [pd] So we don't change defaultvalue behavior for int to intptr_t
  end

  fun m_write_file = M_WriteFile(name : LibC::Char*, source : Void*, length : LibC::Int) : DoomBool
  fun m_read_file = M_ReadFile(name : LibC::Char*, buffer : Byte**) : LibC::Int
  fun m_screenshot = M_ScreenShot
  fun m_load_defaults = M_LoadDefaults
  fun m_save_defaults = M_SaveDefaults
  fun m_draw_text(x : LibC::Int, y : LibC::Int, direct : DoomBool, string : LibC::Char*) : LibC::Int

  # __M_RANDOM__

  # Returns a number from 0 to 255,
  # from a lookup table.
  fun m_random = M_Random : LibC::Int

  # As M_Random, but used only by the play simulation.
  fun p_random = P_Random : LibC::Int

  # Fix randoms for demos.
  fun m_clear_random = M_ClearRandom

  # __P_SAVEG__

  # Persistent storage/archiving.
  # These are the load / save game routines.
  fun p_archive_players = P_ArchivePlayers
  fun p_unarchive_players = P_UnArchivePlayers
  fun p_archive_world = P_ArchiveWorld
  fun p_unarchive_world = P_UnArchiveWorld
  fun p_archive_thinkers = P_ArchiveThinkers
  fun p_unarchive_thinkers = P_UnArchiveThinkers
  fun p_archive_specials = P_ArchiveSpecials
  fun p_unarchive_specials = P_UnArchiveSpecials

  $save_p : Byte*

  # __P_SETUP__

  # NOT called by W_Ticker. Fixme.
  fun p_setup_level = P_SetupLevel(episode : LibC::Int, map : LibC::Int, playermask : LibC::Int, skill : Skill)

  # Called by startup code.
  fun p_init = P_Init

  # __P_TICK__

  # Called by C_Ticker,
  # can call G_PlayerExited.
  # Carries out all thinking of monsters and players.
  fun p_ticker = P_Ticker

  # __R_SKY__

  # SKY, store the number for name.
  SKYFLATNAME = "F_SKY1"

  # The sky map is 256*128*4 maps.
  ANGLETOSKYSHIFT = 22

  $skytexture : LibC::Int
  $skytexturemid : LibC::Int

  # Called whenever the view size changes.
  fun r_init_sky_map = R_InitSkyMap

  # __S_SOUND__

  #
  # Initializes sound stuff, including volume
  # Sets channels, SFX and music volume,
  # allocates channel buffer, sets S_sfx lookup.
  #
  fun s_init = S_Init(sfx_volume : LibC::Int, music_volume : LibC::Int)

  #
  # Per level startup code.
  # Kills playing sounds at start of level,
  #  determines music if any, changes music.
  #
  fun s_start = S_Start

  #
  # Start sound for thing at <origin>
  #  using <sound_id> from sounds.h
  #
  fun s_start_sound = S_StartSound(origin : Void*, sound_id : LibC::Int)

  # Will start a sound at a given volume.
  fun s_start_sound_at_volume = S_StartSoundAtVolume(origin : Void*, sound_id : LibC::Int, volume : LibC::Int)

  # Stop sound for thing at <origin>
  fun s_stop_sound = S_StopSound(origin : Void*)

  # Start music using <music_id> from sounds.h
  fun s_start_music = S_StartMusic(music_id : LibC::Int)

  # Start music using <music_id> from sounds.h,
  # and set whether looping
  fun s_change_music = S_ChangeMusic(music_id : LibC::Int, looping : LibC::Int)

  # Stops the music fer sure.
  fun s_stop_music = S_StopMusic

  # Stop and resume music, during game PAUSE.
  fun s_pause_sound = S_PauseSound
  fun s_resume_sound = S_ResumeSound

  #
  # Updates music & sounds
  #
  fun s_update_sounds = S_UpdateSounds(listener : Void*)

  fun s_set_music_volume = S_SetMusicVolume(volume : LibC::Int)
  fun s_set_sfx_volume = S_SetSfxVolume(volume : LibC::Int)

  # __SOUNDS__

  #
  # SoundFX struct.
  #
  struct Sfxinfo
    # up to 6-character name
    name : LibC::Char*

    # Sfx singularity (only one at a time)
    singularity : LibC::Int

    # Sfx priority
    priority : LibC::Int

    # referenced sound if a link
    link : Sfxinfo*

    # pitch if a link
    pitch : LibC::Int

    # volume if a link
    volume : LibC::Int

    # sound data
    data : Void*

    # this is checked every second to see if sound
    # can be thrown out (if 0, then decrement, if -1,
    # then throw out, if > 0, then it is in use)
    usefulness : LibC::Int

    # lump number of sfx
    lumpnum : LibC::Int
  end

  #
  # MusicInfo struct.
  #
  struct Musicinfo
    # up to 6-character name
    name : LibC::Char*

    # lump number of music
    lumpnum : LibC::Int

    # music data
    data : Void*

    # music handle once registered
    handle : LibC::Int
  end

  # the complete set of sound effects
  $s_sfx = S_sfx : Sfxinfo[1]

  # the complete set of music
  $s_music = S_music : Sfxinfo[1]

  #
  # Identifiers for all music in game.
  #
  enum Musicenum
    MUS_None
    MUS_e1m1
    MUS_e1m2
    MUS_e1m3
    MUS_e1m4
    MUS_e1m5
    MUS_e1m6
    MUS_e1m7
    MUS_e1m8
    MUS_e1m9
    MUS_e2m1
    MUS_e2m2
    MUS_e2m3
    MUS_e2m4
    MUS_e2m5
    MUS_e2m6
    MUS_e2m7
    MUS_e2m8
    MUS_e2m9
    MUS_e3m1
    MUS_e3m2
    MUS_e3m3
    MUS_e3m4
    MUS_e3m5
    MUS_e3m6
    MUS_e3m7
    MUS_e3m8
    MUS_e3m9
    MUS_inter
    MUS_intro
    MUS_bunny
    MUS_victor
    MUS_introa
    MUS_runnin
    MUS_stalks
    MUS_countd
    MUS_betwee
    MUS_doom
    MUS_the_da
    MUS_shawn
    MUS_ddtblu
    MUS_in_cit
    MUS_dead
    MUS_stlks2
    MUS_theda2
    MUS_doom2
    MUS_ddtbl2
    MUS_runni2
    MUS_dead2
    MUS_stlks3
    MUS_romero
    MUS_shawn2
    MUS_messag
    MUS_count2
    MUS_ddtbl3
    MUS_ampie
    MUS_theda3
    MUS_adrian
    MUS_messg2
    MUS_romer2
    MUS_tense
    MUS_shawn3
    MUS_openin
    MUS_evil
    MUS_ultima
    MUS_read_m
    MUS_dm2ttl
    MUS_dm2int
    NUMMUSIC
  end

  #
  # Identifiers for all sfx in game.
  #
  enum Sfxenum
    SFX_None
    SFX_pistol
    SFX_shotgn
    SFX_sgcock
    SFX_dshtgn
    SFX_dbopn
    SFX_dbcls
    SFX_dbload
    SFX_plasma
    SFX_bfg
    SFX_sawup
    SFX_sawidl
    SFX_sawful
    SFX_sawhit
    SFX_rlaunc
    SFX_rxplod
    SFX_firsht
    SFX_firxpl
    SFX_pstart
    SFX_pstop
    SFX_doropn
    SFX_dorcls
    SFX_stnmov
    SFX_swtchn
    SFX_swtchx
    SFX_plpain
    SFX_dmpain
    SFX_popain
    SFX_vipain
    SFX_mnpain
    SFX_pepain
    SFX_slop
    SFX_itemup
    SFX_wpnup
    SFX_oof
    SFX_telept
    SFX_posit1
    SFX_posit2
    SFX_posit3
    SFX_bgsit1
    SFX_bgsit2
    SFX_sgtsit
    SFX_cacsit
    SFX_brssit
    SFX_cybsit
    SFX_spisit
    SFX_bspsit
    SFX_kntsit
    SFX_vilsit
    SFX_mansit
    SFX_pesit
    SFX_sklatk
    SFX_sgtatk
    SFX_skepch
    SFX_vilatk
    SFX_claw
    SFX_skeswg
    SFX_pldeth
    SFX_pdiehi
    SFX_podth1
    SFX_podth2
    SFX_podth3
    SFX_bgdth1
    SFX_bgdth2
    SFX_sgtdth
    SFX_cacdth
    SFX_skldth
    SFX_brsdth
    SFX_cybdth
    SFX_spidth
    SFX_bspdth
    SFX_vildth
    SFX_kntdth
    SFX_pedth
    SFX_skedth
    SFX_posact
    SFX_bgact
    SFX_dmact
    SFX_bspact
    SFX_bspwlk
    SFX_vilact
    SFX_noway
    SFX_barexp
    SFX_punch
    SFX_hoof
    SFX_metal
    SFX_chgun
    SFX_tink
    SFX_bdopn
    SFX_bdcls
    SFX_itmbk
    SFX_flame
    SFX_flamst
    SFX_getpow
    SFX_bospit
    SFX_boscub
    SFX_bossit
    SFX_bospn
    SFX_bosdth
    SFX_manatk
    SFX_mandth
    SFX_sssit
    SFX_ssdth
    SFX_keenpn
    SFX_keendt
    SFX_skeact
    SFX_skesit
    SFX_skeatk
    SFX_radio
    NUMSFX
  end

  # __STSTUFF_H__

  # Size of statusbar.
  # Now sensitive for scaling.
  ST_HEIGHT = (32 * SCREEN_MUL)
  ST_WIDTH  = SCREENWIDTH
  ST_Y      = (SCREENHEIGHT - ST_HEIGHT)

  #
  # STATUS BAR
  #

  # Called by main loop.
  fun st_responder = ST_Responder(ev : Event*) : DoomBool

  # Called by main loop.
  fun st_ticker = ST_Ticker

  # Called by main loop.
  fun st_drawer = ST_Drawer(fullscreen : DoomBool, refresh : DoomBool)

  # Called when the console player is spawned on each level.
  fun st_start = ST_Start

  # Called by startup code.
  fun st_init = ST_Init

  # States for status bar code.
  enum ST_Statenum
    AutomapState
    FirstPersonState
  end

  # States for the chat code.
  enum ST_Chatstateenum
    StartChatState
    WaitDestState
    GetChatState
  end

  # __TABLES__

  PI = 3.141592657

  FINEANGLES = 8192
  FINEMASK   = (FINEANGLES - 1)

  # 0x100000000 to 0x2000
  ANGLETOFINESHIFT = 19

  # Effective size is 10240.
  FINESINE_SIZE = 5 * FINEANGLES//4
  $finesine : Fixed[FINESINE_SIZE]

  # Re-use data, is just PI/2 pahse shift.
  $finecosine : Fixed*

  # Effective size is 4096.
  FINETANGENT_SIZE = FINEANGLES//2
  $finetangent : Fixed[FINETANGENT_SIZE]

  # Binary Angle Measument, BAM.
  ANG45  = 0x20000000
  ANG90  = 0x40000000
  ANG180 = 0x80000000
  ANG270 = 0xc0000000

  SLOPERANGE = 2048
  SLOPEBITS  =   11
  DBITS      = (FRACBITS - SLOPEBITS)

  alias Angle = LibC::UInt

  # Effective size is 2049;
  # The +1 size is to handle the case when x==y
  #  without additional checking.
  TANTOANGLE_SIZE = SLOPERANGE + 1
  $tantoangle : Angle[TANTOANGLE_SIZE]

  # Utility function,
  #  called by R_PointToAngle.
  fun slope_div = SlopeDiv(num : LibC::UInt, den : LibC::UInt) : LibC::Int

  # __P_MOBJ__

  #
  # NOTES: mobj_t
  #
  # mobj_ts are used to tell the refresh where to draw an image,
  # tell the world simulation when objects are contacted,
  # and tell the sound driver how to position a sound.
  #
  # The refresh uses the next and prev links to follow
  # lists of things in sectors as they are being drawn.
  # The sprite, frame, and angle elements determine which patch_t
  # is used to draw the sprite if it is visible.
  # The sprite and frame values are allmost allways set
  # from state_t structures.
  # The statescr.exe utility generates the states.h and states.c
  # files that contain the sprite/frame numbers from the
  # statescr.txt source file.
  # The xyz origin point represents a point at the bottom middle
  # of the sprite (between the feet of a biped).
  # This is the default origin position for patch_ts grabbed
  # with lumpy.exe.
  # A walking creature will have its z equal to the floor
  # it is standing on.
  #
  # The sound code uses the x,y, and subsector fields
  # to do stereo positioning of any sound effited by the mobj_t.
  #
  # The play simulation uses the blocklinks, x,y,z, radius, height
  # to determine when mobj_ts are touching each other,
  # touching lines in the map, or hit by trace lines (gunshots,
  # lines of sight, etc).
  # The mobj_t->flags element has various bit flags
  # used by the simulation.
  #
  # Every mobj_t is linked into a single sector
  # based on its origin coordinates.
  # The subsector_t is found with R_PointInSubsector(x,y),
  # and the sector_t can be found with subsector->sector.
  # The sector links are only used by the rendering code,
  # the play simulation does not care about them at all.
  #
  # Any mobj_t that needs to be acted upon by something else
  # in the play world (block movement, be shot, etc) will also
  # need to be linked into the blockmap.
  # If the thing has the MF_NOBLOCK flag set, it will not use
  # the block links. It can still interact with other things,
  # but only as the instigator (missiles will run into other
  # things, but nothing can run into a missile).
  # Each block in the grid is 128*128 units, and knows about
  # every line_t that it contains a piece of, and every
  # interactable mobj_t that has its origin contained.
  #
  # A valid mobj_t is a mobj_t that has the proper subsector_t
  # filled in for its xy coordinates and is linked into the
  # sector from which the subsector was made, or has the
  # MF_NOSECTOR flag set (the subsector_t needs to be valid
  # even if MF_NOSECTOR is set), and is linked into a blockmap
  # block or has the MF_NOBLOCKMAP flag set.
  # Links should only be modified by the P_[Un]SetThingPosition()
  # functions.
  # Do not change the MF_NO? flags while a thing is valid.
  #
  # Any questions?
  #

  #
  # Misc. mobj flags
  #
  enum Mobjflag
    # Call P_SpecialThing when touched.
    MF_SPECIAL = 1
    # Blocks.
    MF_SOLID = 2
    # Can be hit.
    MF_SHOOTABLE = 4
    # Don't use the sector links (invisible but touchable).
    MF_NOSECTOR = 8
    # Don't use the blocklinks (inert but displayable)
    MF_NOBLOCKMAP = 16

    # Not to be activated by sound, deaf monster.
    MF_AMBUSH = 32
    # Will try to attack right back.
    MF_JUSTHIT = 64
    # Will take at least one step before attacking.
    MF_JUSTATTACKED = 128
    # On level spawning (initial position),
    #  hang from ceiling instead of stand on floor.
    MF_SPAWNCEILING = 256
    # Don't apply gravity (every tic),
    #  that is, object will float, keeping current height
    #  or changing it actively.
    MF_NOGRAVITY = 512

    # Movement flags.
    # This allows jumps from high places.
    MF_DROPOFF = 0x400
    # For players, will pick up items.
    MF_PICKUP = 0x800
    # Player cheat. ???
    MF_NOCLIP = 0x1000
    # Player: keep info about sliding along walls.
    MF_SLIDE = 0x2000
    # Allow moves to any height, no gravity.
    # For active floaters, e.g. cacodemons, pain elementals.
    MF_FLOAT = 0x4000
    # Don't cross lines
    #   ??? or look at heights on teleport.
    MF_TELEPORT = 0x8000
    # Don't hit same species, explode on block.
    # Player missiles as well as fireballs of various kinds.
    MF_MISSILE = 0x10000
    # Dropped by a demon, not level spawned.
    # E.g. ammo clips dropped by dying former humans.
    MF_DROPPED = 0x20000
    # Use fuzzy draw (shadow demons or spectres),
    #  temporary player invisibility powerup.
    MF_SHADOW = 0x40000
    # Flag: don't bleed when shot (use puff),
    #  barrels and shootable furniture shall not bleed.
    MF_NOBLOOD = 0x80000
    # Don't stop moving halfway off a step,
    #  that is, have dead bodies slide down all the way.
    MF_CORPSE = 0x100000
    # Floating to a height for a move, ???
    #  don't auto float to target's height.
    MF_INFLOAT = 0x200000

    # On kill, count this enemy object
    #  towards intermission kill total.
    # Happy gathering.
    MF_COUNTKILL = 0x400000

    # On picking up, count this item object
    #  towards intermission item total.
    MF_COUNTITEM = 0x800000

    # Special handling: skull in flight.
    # Neither a cacodemon nor a missile.
    MF_SKULLFLY = 0x1000000

    # Don't spawn this object
    #  in death match mode (e.g. key cards).
    MF_NOTDMATCH = 0x2000000

    # Player sprites in multiplayer modes are modified
    #  using an internal color lookup table for re-indexing.
    # If 0x4 0x8 or 0xc,
    #  use a translation table for player colormaps
    MF_TRANSLATION = 0xc000000
    # Hmm ???.
    MF_TRANSSHIFT = 26
  end

  # Map Object definition.
  struct Mobj
    # List: thinker links.
    thinker : Thinker

    # Info for drawing: position.
    x : Fixed
    y : Fixed
    z : Fixed

    # More list: links in sector (if needed)
    snext : Mobj*
    sprev : Mobj*

    # More drawing info: to determine current sprite.
    angle : Angle      # orientation
    sprite : Spritenum # used to find patch_t and flip value
    frame : LibC::Int  # might be ORed with FF_FULLBRIGHT

    # Interaction info, by BLOCKMAP.
    # Links in blocks (if needed).
    bnext : Mobj*
    bprev : Mobj*

    subsector : Subsector*

    # The closest interval over all contacted Sectors.
    floorz : Fixed
    ceilingz : Fixed

    # For movement checking.
    radius : Fixed
    height : Fixed

    # Momentums, used to update position.
    momx : Fixed
    momy : Fixed
    momz : Fixed

    # If == validcount, already checked.
    validcount : LibC::Int

    type : Mobjtype
    info : Mobjinfo* # &mobjinfo[mobj->type]

    tics : LibC::Int # state tic counter
    state : State*
    flags : LibC::Int
    health : LibC::Int

    # Movement direction, movement generation (zig-zagging).
    movedir : LibC::Int   # 0-7
    movecount : LibC::Int # when 0, select a new dir

    # Thing being chased/attacked (or 0),
    # also the originator for missiles.
    target : Mobj*

    # Reaction time: if non 0, don't attack yet.
    # Used by player to freeze a bit after teleporting.
    reactiontime : LibC::Int

    # If >0, the target will be chased
    # no matter what (even if shot)
    threshold : LibC::Int

    # Additional info record for player avatars only.
    # Only valid if type == MT_PLAYER
    player : Player*

    # Player number last looked for.
    lastlook : LibC::Int

    # For nightmare respawn.
    spawnpoint : Mapthing

    # Thing being chased/attacked for tracers.
    tracer : Mobj*
  end

  # __P_PSPR__

  #
  # Frame flags:
  # handles maximum brightness (torches, muzzle flare, light sources)
  #
  FF_FULLBRIGHT = 0x8000
  FF_FRAMEMASK  = 0x7fff

  #
  # Overlay psprites are scaled shapes
  # drawn directly on the view screen,
  # coordinates are given for a 320*200 view screen.
  #
  enum Psprnum
    Weapon
    Flash
    NUMPSPRITES
  end

  struct Pspdef
    state : State* # a 0 state means not active
    tics : LibC::Int
    sx : Fixed
    sy : Fixed
  end

  # __D_PLAYER__

  #
  # Player states.
  #
  enum Playerstate
    # Playing or camping.
    PST_LIVE
    # Dead on the ground, view follows killer.
    PST_DEAD
    # Ready to restart/respawn???
    PST_REBORN
  end

  #
  # Player internal flags, for cheats and debug.
  #
  enum Cheat
    # No clipping, walk through barriers.
    CF_NOCLIP = 1
    # No damage, no health loss.
    CF_GODMODE = 2
    # Not really a cheat, just a debug aid.
    CF_NOMOMENTUM = 4
  end

  #
  # Extended player object info: player_t
  #
  struct Player
    mo : Mobj*
    playerstate : Playerstate
    cmd : Ticcmd

    # Determine POV,
    #  including viewpoint bobbing during movement.
    # Focal origin above r.z
    viewz : Fixed
    # Base height above floor for viewz.
    viewheight : Fixed
    # Bob/squat speed.
    deltaviewheight : Fixed
    # bounded/scaled total momentum.
    bob : Fixed

    # This is only used between levels,
    # mo->health is used during levels.
    health : LibC::Int
    armorpoints : LibC::Int
    # Armor type is 0-2.
    armortype : LibC::Int

    # Power ups. invinc and invis are tic counters.
    powers : LibC::Int[Powertype::NUMPOWERS]
    cards : DoomBool[Card::NUMCARDS]
    backpack : DoomBool

    # Frags, kills of other players.
    frags : LibC::Int[MAXPLAYERS]
    readyweapon : Weapontype

    # Is wp_nochange if not changing.
    pendingweapon : Weapontype

    weaponowned : DoomBool[Weapontype::NUMWEAPONS]
    ammo : LibC::Int[Ammotype::NUMAMMO]
    maxammo : LibC::Int[Ammotype::NUMAMMO]

    # True if button down last tic.
    attackdown : LibC::Int
    usedown : LibC::Int

    # Bit flags, for cheats and debug.
    # See cheat_t, above.
    cheats : LibC::Int

    # Refired shots are less accurate.
    refire : LibC::Int

    # For intermission stats.
    killcount : LibC::Int
    itemcount : LibC::Int
    secretcount : LibC::Int

    # Hint messages.
    message : LibC::Char*

    # For screen flashing (red or bright).
    damagecount : LibC::Int
    bonuscount : LibC::Int

    # Who did damage (0 for floors/ceilings).
    attacker : Mobj*

    # So gun flashes light up areas.
    extralight : LibC::Int

    # Current PLAYPAL, ???
    #  can be set to REDCOLORMAP for pain, etc.
    fixedcolormap : LibC::Int

    # Player skin colorshift,
    #  0-3 for which color to draw player.
    colormap : LibC::Int

    # Overlay view sprites (gun, etc).
    psprites : Pspdef[Psprnum::NUMPSPRITES]

    # True if secret level has been done.
    didsecret : DoomBool
  end

  #
  # INTERMISSION
  # Structure passed e.g. to WI_Start(wb)
  #
  struct Wbplayerstruct
    in : DoomBool # whether the player is in game

    # Player stats, kills, collected items etc.
    skills : LibC::Int
    sitems : LibC::Int
    ssecret : LibC::Int
    stime : LibC::Int
    frags : LibC::Int[4]
    score : LibC::Int # current score on entry, modified on return
  end

  struct Wbstartstruct
    epsd : LibC::Int # episode # (0-2)

    # if true, splash the secret level
    didsecret : DoomBool

    # previous and next levels, origin 0
    last : LibC::Int
    next : LibC::Int

    maxkills : LibC::Int
    maxitems : LibC::Int
    maxsecret : LibC::Int
    maxfrags : LibC::Int

    # the par time
    partime : LibC::Int

    # index of this player in game
    pnum : LibC::Int

    plyr : Wbplayerstruct[MAXPLAYERS]
  end

  # __D_NET__

  #
  # Network play related stuff.
  # There is a data struct that stores network
  # communication related stuff, and another
  # one that defines the actual packets to
  # be transmitted.
  #

  DOOMCOM_ID = 0x12345678

  # Max computers/players in a game.
  MAXNETNODES = 8

  # Networking and tick handling related.
  BACKUPTICS = 12

  enum Command
    SEND = 1
    GET  = 2
  end

  #
  # Network packet data.
  #
  struct Doomdata
    # High bit is retransmit request.
    checksum : LibC::UInt
    # Only valid if NCMD_RETRANSMIT.
    retransmitfrom : Byte

    starttic : Byte
    player : Byte
    numtics : Byte
    cmds : Ticcmd[BACKUPTICS]
  end

  struct Doomcom
    # Supposed to be DOOMCOM_ID?
    id : LibC::Long

    # DOOM executes an int to execute commands.
    intnum : LibC::Short
    # Communication between DOOM and the driver.
    # Is CMD_SEND or CMD_GET.
    command : LibC::Short
    # Is dest for send, set by get (-1 = no packet).
    remotenode : LibC::Short

    # Number of bytes in doomdata to be sent
    datalength : LibC::Short

    # Info common to all nodes.
    # Console is allways node 0.
    numnodes : LibC::Short
    # Flag: 1 = no duplication, 2-5 = dup for slow nets.
    ticdup : LibC::Short
    # Flag: 1 = send a backup tic in every packet.
    extratics : LibC::Short
    # Flag: 1 = deathmatch.
    deathmatch : LibC::Short
    # Flag: -1 = new game, 0-5 = load savegame
    savegame : LibC::Short
    episode : LibC::Short # 1-3
    map : LibC::Short     # 1-9
    skill : LibC::Short   # 1-5

    # Info specific to this node.
    consoleplayer : LibC::Short
    numplayers : LibC::Short

    # These are related to the 3-display mode,
    #  in which two drones looking left and right
    #  were used to render two additional views
    #  on two additional computers.
    # Probably not operational anymore.
    # 1 = left, 0 = center, -1 = right
    angleoffset : LibC::Short
    # 1 = drone
    drone : LibC::Short

    # The packet data to be sent.
    data : Doomdata
  end

  # Create any new ticcmds and broadcast to other players.
  fun net_update = NetUpdate

  # Broadcasts special packets to other players
  #  to notify of game exit
  fun d_quit_net_game = D_QuitNetGame

  # ? how many ticks to run?
  fun try_run_tics = TryRunTics

  # __D_STATE__

  # ------------------------
  # Command line parameters.
  #
  $nomonsters : DoomBool  # checkparm of -nomonsters
  $respawnparm : DoomBool # checkparm of -respawn
  $fastparm : DoomBool    # checkparm of -fast
  $devparm : DoomBool     # DEBUG: launched with -devparm

  # -----------------------------------------------------
  # Game Mode - identify IWAD as shareware, retail etc.
  #
  $gamemode : GameMode
  $gamemission : GameMission

  # Set if homebrew PWAD stuff has been added.
  $modifiedgame : DoomBool

  # -------------------------------------------
  # Language.
  $language : Language

  # -------------------------------------------
  # Selected skill type, map etc.
  #

  # Defaults for menu, methinks.
  $startskill : Skill
  $startepisode : LibC::Int
  $startmap : LibC::Int

  $autostart : DoomBool

  # Selected by user.
  $gameskill : Skill
  $gameepisode : LibC::Int
  $gamemap : LibC::Int

  # Nightmare mode flag, single player.
  $respawnmonsters : DoomBool

  # Netgame? Only true if >1 player.
  $netgame : DoomBool

  # Flag: true only if started as net deathmatch.
  # An enum might handle altdeath/cooperative better.
  $deathmatch : DoomBool

  # -------------------------
  # Internal parameters for sound rendering.
  # These have been taken from the DOS version,
  # but are not (yet) supported with Linux
  # (e.g. no sound volume adjustment with menu.

  # These are not used, but should be (menu).
  # From m_menu.c:
  # Sound FX volume has default, 0 - 15
  # Music volume has default, 0 - 15
  # These are multiplied by 8.
  $snd_sfx_volume = snd_SfxVolume : LibC::Int     # maximum volume for sound
  $snd_music_volume = snd_MusicVolume : LibC::Int # maximum volume for music

  # -------------------------
  # Status flags for refresh.
  #

  # Depending on view size - no status bar?
  # Note that there is no way to disable the
  #  status bar explicitely.
  $statusbaractive : DoomBool

  $automapactive : DoomBool # In AutoMap mode?
  $menuactive : DoomBool    # Menu overlayed?
  $paused : DoomBool        # Game Pause?

  $viewactive : DoomBool

  $nodrawers : DoomBool
  $noblit : DoomBool

  $viewwindowx : LibC::Int
  $viewwindowy : LibC::Int
  $viewheight : LibC::Int
  $viewwidth : LibC::Int
  $scaledviewwidth : LibC::Int

  # This one is related to the 3-screen display mode.
  # ANG90 = left side, ANG270 = right
  $viewangleoffset : LibC::Int

  # Player taking events, and displaying.
  $consoleplayer : LibC::Int
  $displayplayer : LibC::Int

  # -------------------------------------
  # Scores, rating.
  # Statistics on a given map, for intermission.
  #
  $totalkills : LibC::Int
  $totalitems : LibC::Int
  $totalsecret : LibC::Int

  # Timer, for scores.
  $levelstarttic : LibC::Int # gametic at level start
  $leveltime : LibC::Int     # tics in game play for par

  # --------------------------------------
  # DEMO playback/recording related stuff.
  # No demo, there is a human player in charge?
  # Disable save/end game?
  $usergame : DoomBool

  # ?
  $demoplayback : DoomBool
  $demorecording : DoomBool

  # Quit after playing a demo from cmdline.
  $singledemo : DoomBool

  # ?
  $gamestate : Gamestate

  # -----------------------------
  # Internal parameters, fixed.
  # These are set by the engine, and not changed
  # according to user inputs. Partly load from
  # WAD, partly set at startup time.

  $gametic : LibC::Int

  # Bookkeeping on players - state.
  $players : Player[MAXPLAYERS]

  # Alive? Disconnected?
  $playeringame : DoomBool[MAXPLAYERS]

  # Player spawn spots for deathmatch.
  MAX_DM_STARTS = 10
  $deathmatchstarts : Mapthing[MAX_DM_STARTS]
  $deathmatch_p : Mapthing*

  # Player spawn spots.
  $playerstarts : Mapthing[MAXPLAYERS]

  # Intermission stats.
  # Parameters for world map / intermission.
  $wminfo : Wbstartstruct

  # LUT of ammunition limits for each kind.
  # This doubles with BackPack powerup item.
  $maxammo : LibC::Int[Ammotype::NUMAMMO]

  # -----------------------------------------
  # Internal parameters, used for engine.
  #

  # File handling stuff.
  $basedefault : LibC::Char[1024]
  $debugfile : Void*

  # if true, load all graphics at level load
  $precache : DoomBool

  # wipegamestate can be set to -1
  # to force a wipe on the next draw
  $wipegamestate : Gamestate

  $mouse_sensitivity = mouseSensitivity : LibC::Int
  # ?
  # debug flag to cancel adaptiveness
  $singletics : DoomBool

  $bodyqueslot : LibC::Int

  # Needed to store the number of the dummy sky flat.
  # Used for rendering,
  #  as well as tracking projectiles etc.
  $skyflatnum : LibC::Int

  # Netgame stuff (buffers and pointers, i.e. indices).

  # This is ???
  $doomcom : Doomcom*

  # This points inside doomcom.
  $netbuffer : Doomdata*

  $localcmds : Ticcmd[BACKUPTICS]
  $rndindex : LibC::Int

  $maketic : LibC::Int
  $nettics : LibC::Int[MAXNETNODES]

  $netcmds : Ticcmd[BACKUPTICS][MAXPLAYERS]
  $ticdup : LibC::Int

  # __I_SOUND__

  # Init at program start...
  fun i_init_sound = I_InitSound

  # ... update sound buffer and audio device at runtime...
  fun i_update_sound = I_UpdateSound
  fun i_submit_sound = I_SubmitSound

  # ... shut down and relase at program termination.
  fun i_shutdown_sound = I_ShutdownSound

  #
  #  SFX I/O
  #

  # Initialize channels?
  fun i_set_channels = I_SetChannels

  # Get raw data lump index for sound descriptor.
  fun i_get_sfx_lump_num = I_GetSfxLumpNum(sfx : Sfxinfo*) : LibC::Int

  # Starts a sound in a particular sound channel.
  fun i_start_sound = I_StartSound(id : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int, priority : LibC::Int) : LibC::Int

  # Stops a sound channel.
  fun i_stop_sound = I_StopSound(handle : LibC::Int)

  # Called by S_*() functions
  #  to see if a channel is still playing.
  # Returns 0 if no longer playing, 1 if playing.
  fun i_sound_is_playing = I_SoundIsPlaying(handle : LibC::Int) : LibC::Int

  # Updates the volume, separation,
  #  and pitch of a sound channel.
  fun i_update_sound_params = I_UpdateSoundParams(handle : LibC::Int, vol : LibC::Int, sep : LibC::Int, pitch : LibC::Int)

  #
  #  MUSIC I/O
  #
  fun i_init_music = I_InitMusic
  fun i_shutdown_music = I_ShutdownMusic

  # Volume.
  fun i_set_music_volume = I_SetMusicVolume(volume : LibC::Int)

  # PAUSE game handling.
  fun i_pause_song = I_PauseSong(handle : LibC::Int)
  fun i_resume_song = I_ResumeSong(handle : LibC::Int)

  # Registers a song handle to song data.
  fun i_register_song = I_RegisterSong(data : Void*) : LibC::Int

  # Called by anything that wishes to start music.
  #  plays a song, and when the song is done,
  #  starts playing it again in an endless loop.
  # Horrible thing to do, considering.
  fun i_play_song = I_PlaySong(handle : LibC::Int, looping : LibC::Int)

  # Stops a song over 3 seconds.
  fun i_stop_song = I_StopSong(handle : LibC::Int)

  # See above (register), then think backwards
  fun i_unregister_song = I_UnRegisterSong(handle : LibC::Int)

  # Get next MIDI message
  fun i_tick_song = I_TickSong : LibC::ULong

  # __P_INTER__

  fun p_give_power = P_GivePower(player : Player*, power : LibC::Int) : DoomBool

  # __R_DEFS__

  # Silhouette, needed for clipping Segs (mainly)
  # and sprites representing things.
  SIL_NONE   = 0
  SIL_BOTTOM = 1
  SIL_TOP    = 2
  SIL_BOTH   = 3

  MAXDRAWSEGS = 256

  #
  # INTERNAL MAP TYPES
  # used by play and refresh
  #

  #
  # Your plain vanilla vertex.
  # Note: transformed values not buffered locally,
  # like some DOOM-alikes ("wt", "WebView") did.
  #
  struct Vertex
    x : Fixed
    y : Fixed
  end

  # Each sector has a degenmobj_t in its center
  # for sound origin purposes.
  # I suppose this does not handle sound from
  # moving objects (doppler), because
  # position is prolly just buffered, not
  # updated.
  struct Degenmobj
    thinker : Thinker # not used for anything
    x : Fixed
    y : Fixed
    z : Fixed
  end

  #
  # The SECTORS record, at runtime.
  # Stores things/mobjs.
  #
  struct Sector
    floorheight : Fixed
    ceilingheight : Fixed
    floorpic : LibC::Short
    ceilingpic : LibC::Short
    lightlevel : LibC::Short
    special : LibC::Short
    tag : LibC::Short

    # 0 = untraversed, 1,2 = sndlines - 1
    soundtraversed : LibC::Int

    # thing that made a sound (or null)
    soundtarget : Mobj*

    # mapblock bounding box for height changes
    blockbox : LibC::Int[4]

    # origin for any sounds played by the sector
    soundorg : Degenmobj

    # if == validcount, already checked
    validcount : LibC::Int

    # list of mobjs in sector
    thinglist : Mobj*

    # thinker_t for reversable actions
    specialdata : Void*

    linecount : LibC::Int
    lines : Line** # [linecount] size
  end

  #
  # The SideDef.
  #
  struct Side
    # add this to the calculated texture column
    textureoffset : Fixed

    # add this to the calculated texture top
    rowoffset : Fixed

    # Texture indices.
    # We do not maintain names here.
    toptexture : LibC::Short
    bottomtexture : LibC::Short
    midtexture : LibC::Short

    # Sector the SideDef is facing.
    sector : Sector*
  end

  #
  # Move clipping aid for LineDefs.
  #
  enum Slopetype
    HORIZONTAL
    VERTICAL
    POSITIVE
    NEGATIVE
  end

  struct Line
    # Vertices, from v1 to v2.
    v1 : Vertex*
    v2 : Vertex*

    # Precalculated v2 - v1 for side checking.
    dx : Fixed
    dy : Fixed

    # Animation related.
    flags : LibC::Short
    special : LibC::Short
    tag : LibC::Short

    # Visual appearance: SideDefs.
    # sidenum[1] will be -1 if one sided
    sidenum : LibC::Short[2]

    # Neat. Another bounding box, for the extent
    # of the LineDef.
    bbox : Fixed[4]

    # To aid move clipping.
    slopetype : Slopetype

    # Front and back sector.
    # Note: redundant? Can be retrieved from SideDefs.
    frontsector : Sector*
    backsector : Sector*

    # if == validcount, already checked
    validcount : LibC::Int

    # thinker_t for reversable actions
    specialdata : Void*
  end

  #
  # A SubSector.
  # References a Sector.
  # Basically, this is a list of LineSegs,
  # indicating the visible walls that define
  # (all or some) sides of a convex BSP leaf.
  #
  struct Subsector
    sector : Sector*
    numlines : LibC::Short
    firstline : LibC::Short
  end

  #
  # The LineSeg.
  #
  struct Seg
    v1 : Vertex*
    v2 : Vertex*

    offset : Fixed

    angle : Angle

    sidedef : Side*
    linedef : Line*

    # Sector references.
    # Could be retrieved from linedef, too.
    # backsector is 0 for one sided lines
    frontsector : Sector*
    backsector : Sector*
  end

  #
  # BSP node.
  #
  struct Node
    # Partition line.
    x : Fixed
    y : Fixed
    dx : Fixed
    dy : Fixed

    # Bounding box for each child.
    bbox : Fixed[4][2]

    # If NF_SUBSECTOR its a subsector.
    children : LibC::UShort[2]
  end

  # posts are runs of non masked source pixels
  struct Post
    topdelta : Byte # -1 is the last post in a column
    length : Byte   # length data bytes follows
  end

  # column_t is a list of 0 or more post_t, (byte)-1 terminated
  alias Column = Post

  #
  # OTHER TYPES
  #

  # This could be wider for >8 bit display.
  # Indeed, true color support is posibble
  #  precalculating 24bpp lightmap/colormap LUT.
  #  from darkening PLAYPAL to all black.
  # Could even us emore than 32 levels.
  alias Lighttable = Byte

  #
  # ?
  #
  struct Drawseg
    curline : Seg*
    x1 : LibC::Int
    x2 : LibC::Int

    scale1 : Fixed
    scale2 : Fixed
    scalestep : Fixed

    # 0=none, 1=bottom, 2=top, 3=both
    silhouette : LibC::Int

    # do not clip sprites above this
    bsilheight : Fixed

    # do not clip sprites below this
    tsilheight : Fixed

    # Pointers to lists for sprite clipping,
    #  all three adjusted so [x1] is first value.
    sprtopclip : LibC::Short*
    sprbottomclip : LibC::Short*
    maskedtexturecol : LibC::Short*
  end

  # Patches.
  # A patch holds one or more columns.
  # Patches are used for sprites and all masked pictures,
  # and we compose textures from the TEXTURE1/2 lists
  # of patches.
  struct Patch
    width : LibC::Short # bounding box size
    height : LibC::Short
    leftoffset : LibC::Short # pixels to the left of origin
    topoffset : LibC::Short  # pixels below the origin
    columnofs : LibC::Int[8] # only [width] used
    # the [0] is &columnofs[width]
  end

  # A vissprite_t is a thing
  #  that will be drawn during a refresh.
  # I.e. a sprite object that is partly visible.
  struct Vissprite
    # Doubly linked list.
    prev : Vissprite*
    next : Vissprite*

    x1 : LibC::Int
    x2 : LibC::Int

    # for line side calculation
    gx : Fixed
    gy : Fixed

    # global bottom / top for silhouette clipping
    gz : Fixed
    gzt : Fixed

    # horizontal position of x1
    startfrac : Fixed

    scale : Fixed

    # negative if flipped
    xiscale : Fixed

    texturemid : Fixed
    patch : LibC::Int

    # for color translation and shadow draw,
    #  maxbright frames as well
    colormap : Lighttable*

    mobjflags : LibC::Int
  end

  #
  # Sprites are patches with a special naming convention
  #  so they can be recognized by R_InitSprites.
  # The base name is NNNNFx or NNNNFxFx, with
  #  x indicating the rotation, x = 0, 1-7.
  # The sprite and frame specified by a thing_t
  #  is range checked at run time.
  # A sprite is a patch_t that is assumed to represent
  #  a three dimensional object and may have multiple
  #  rotations pre drawn.
  # Horizontal flipping is used to save space,
  #  thus NNNNF2F5 defines a mirrored patch.
  # Some sprites will only have one picture used
  # for all views: NNNNF0
  #
  struct Spriteframe
    # If false use 0 for any position.
    # Note: as eight entries are available,
    #  we might as well insert the same name eight times.
    rotate : DoomBool

    # Lump to use for view angles 0-7.
    lump : LibC::Short[8]

    # Flip bit (1 = flip) to use for view angles 0-7.
    flip : Byte[8]
  end

  #
  # A sprite definition:
  #  a number of animation frames.
  #
  struct Spritedef
    numframes : LibC::Int
    spriteframes : Spriteframe*
  end

  #
  # Now what is a visplane, anyway?
  #
  struct Visplane
    height : Fixed
    picnum : LibC::Int
    lightlevel : LibC::Int
    minx : LibC::Int
    maxx : LibC::Int

    # leave pads for [minx-1]/[maxx+1]

    pad1 : Byte
    # Here lies the rub for all
    #  dynamic resize/change of resolution.
    top : Byte[SCREENWIDTH]
    pad2 : Byte
    pad3 : Byte
    # See above.
    bottom : Byte[SCREENWIDTH]
    pad4 : Byte
  end

  # __HULIB__

  # background and foreground screen numbers
  # different from other modules.
  BG = 1
  FG = 0

  # font stuff
  HU_CHARERASE = KEY_BACKSPACE

  HU_MAXLINES      =  4
  HU_MAXLINELENGTH = 80

  #
  # Typedefs of widgets
  #

  # Text Line widget
  #  (parent of Scrolling Text and Input Text widgets)
  LINEOFTEXT_SIZE = HU_MAXLINELENGTH + 1

  struct HU_Textline
    # left-justified position of scrolling text window
    x : LibC::Int
    y : LibC::Int

    f : Patch**                     # font
    sc : LibC::Int                  # start character
    l : LibC::Char[LINEOFTEXT_SIZE] # line of text
    len : LibC::Int                 # current line length

    # whether this line needs to be udpated
    needsupdate : LibC::Int
  end

  # Scrolling Text window widget
  #  (child of Text Line widget)
  struct HU_Stext
    l : HU_Textline[HU_MAXLINES] # text lines to draw
    h : LibC::Int                # height in lines
    cl : LibC::Int               # current line number

    # pointer to doom_boolean stating whether to update window
    on : DoomBool*
    laston : DoomBool # last value of *->on.
  end

  # Input Text Line widget
  #  (child of Text Line widget)
  struct HU_Itext
    l : HU_Textline # text line to input on

    # left margin past which I am not to delete characters
    lm : LibC::Int

    # pointer to doom_boolean stating whether to update window
    on : DoomBool*
    laston : DoomBool # last value of *->on
  end

  #
  # Widget creation, access, and update routines
  #

  # initializes heads-up widget library
  fun hulib_init = HUlib_init

  #
  # textline code
  #

  # clear a line of text
  fun hulib_clear_text_line = HUlib_clearTextLine(t : HU_Textline*)

  fun hulib_init_text_line = HUlib_initTextLine(t : HU_Textline*, x : LibC::Int, y : LibC::Int, f : Patch**, sc : LibC::Int)

  # returns success
  fun hulib_add_char_to_text_line = HUlib_addCharToTextLine(t : HU_Textline*, ch : LibC::Char) : DoomBool

  # returns success
  fun hulib_del_char_from_text_line = HUlib_delCharFromTextLine(t : HU_Textline*) : DoomBool

  # draws tline
  fun hulib_draw_text_line = HUlib_drawTextLine(l : HU_Textline*, drawcursor : DoomBool)

  # erases text line
  fun hulib_erase_text_line = HUlib_eraseTextLine(l : HU_Textline*)

  #
  # Scrolling Text window widget routines
  #

  # ?
  fun hulib_init_s_text = HUlib_initSText(s : HU_Stext*,
                                          x : LibC::Int,
                                          y : LibC::Int,
                                          h : LibC::Int,
                                          font : Patch**,
                                          startchar : LibC::Int,
                                          on : DoomBool*)

  # add a new line
  fun hulib_add_line_to_s_text = HUlib_addLineToSText(s : HU_Stext*)

  # ?
  fun hulib_add_message_to_s_text = HUlib_addMessageToSText(s : HU_Stext*, prefix : LibC::Char*, msg : LibC::Char*)

  # draws stext
  fun hulib_draw_s_text = HUlib_drawSText(s : HU_Stext*)

  # erases all stext lines
  fun hulib_erase_s_text = HUlib_eraseSText(s : HU_Stext*)

  # Input Text Line widget routines
  fun hulib_init_i_text = HUlib_initIText(it : HU_Itext*,
                                          x : LibC::Int,
                                          y : LibC::Int,
                                          font : Patch**,
                                          startchar : LibC::Int,
                                          on : DoomBool*)

  # enforces left margin
  fun hulib_del_char_from_i_text = HUlib_delCharFromIText(it : HU_Itext*)

  # enforces left margin
  fun hulib_erase_line_from_i_text = HUlib_eraseLineFromIText(it : HU_Itext*)

  # resets line and left margin
  fun hulib_reset_i_text = HUlib_resetIText(it : HU_Itext*)

  # left of left-margin
  fun hulib_add_prefix_to_i_text = HUlib_addPrefixToIText(it : HU_Itext*, str : LibC::Char*)

  # whether eaten
  fun hulib_key_in_i_text = HUlib_keyInIText(it : HU_Itext*, ch : LibC::UChar) : DoomBool

  fun hulib_draw_i_text = HUlib_drawIText(it : HU_Itext*)

  # erases all itext lines
  fun hulib_erase_i_text = HUlib_eraseIText(it : HU_Itext*)

  # __P_SPEC__

  #
  # End-level timer (-TIMER option)
  #
  $level_timer = levelTimer : DoomBool
  $level_time_count = levelTimeCount : LibC::Int

  # Define values for map objects
  MO_TELEPORTMAN = 14

  # at game start
  fun p_init_pic_anims = P_InitPicAnims

  # at map load
  fun p_spawn_specials = P_SpawnSpecials

  # every tic
  fun p_update_specials = P_UpdateSpecials

  # when needed
  fun p_use_special_line = P_UseSpecialLine(thing : Mobj*, line : Line*, side : LibC::Int) : DoomBool

  fun p_shoot_special_line = P_ShootSpecialLine(thing : Mobj*, line : Line*)
  fun p_cross_special_line = P_CrossSpecialLine(linenum : LibC::Int, side : LibC::Int, thing : Mobj*)
  fun p_player_in_special_sector = P_PlayerInSpecialSector(player : Player*)
  fun two_sided = twoSided(sector : LibC::Int, line : LibC::Int) : LibC::Int
  fun get_sector = getSector(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : Sector*
  fun get_side = getSide(current_sector : LibC::Int, line : LibC::Int, side : LibC::Int) : Side*
  fun p_find_lowest_floor_surrounding = P_FindLowestFloorSurrounding(sec : Sector*) : Fixed
  fun p_find_highest_floor_surrounding = P_FindHighestFloorSurrounding(sec : Sector*) : Fixed
  fun p_find_next_highest_floor = P_FindNextHighestFloor(sec : Sector*, currentheight : LibC::Int) : Fixed
  fun p_find_lowest_ceiling_surrounding = P_FindLowestCeilingSurrounding(sec : Sector*) : Fixed
  fun p_find_highest_ceiling_surrounding = P_FindHighestCeilingSurrounding(sec : Sector*) : Fixed
  fun p_find_sector_from_line_tag = P_FindSectorFromLineTag(line : Line*, start : LibC::Int) : LibC::Int
  fun p_find_min_surrounding_light = P_FindMinSurroundingLight(sector : Sector*, max : LibC::Int) : LibC::Int
  fun get_next_sector = getNextSector(line : Line*, sec : Sector*) : Sector*

  #
  # SPECIAL
  #
  fun ev_do_donut = EV_DoDonut(line : Line*) : LibC::Int

  #
  # P_LIGHTS
  #
  struct Fireflicker
    thinker : Thinker
    sector : Sector*
    count : LibC::Int
    maxlight : LibC::Int
    minlight : LibC::Int
  end

  struct Lightflash
    thinker : Thinker
    sector : Sector*
    count : LibC::Int
    maxlight : LibC::Int
    minlight : LibC::Int
    maxtime : LibC::Int
    mintime : LibC::Int
  end

  struct Strobe
    thinker : Thinker
    sector : Sector*
    count : LibC::Int
    minlight : LibC::Int
    maxlight : LibC::Int
    darktime : LibC::Int
    brighttime : LibC::Int
  end

  struct Glow
    thinker : Thinker
    sector : Sector*
    minlight : LibC::Int
    maxlight : LibC::Int
    direction : LibC::Int
  end

  GLOWSPEED    =  8
  STROBEBRIGHT =  5
  FASTDARK     = 15
  SLOWDARK     = 35

  fun p_spawn_fire_flicker = P_SpawnFireFlicker(sector : Sector*)
  fun t_light_flash = T_LightFlash(flash : Lightflash*)
  fun p_spawn_light_flash = P_SpawnLightFlash(sector : Sector*)
  fun t_strobe_flash = T_StrobeFlash(flash : Strobe*)

  fun p_spawn_strobe_flash = P_SpawnStrobeFlash(sector : Sector*, fast_or_slow : LibC::Int, in_sync : LibC::Int)
  fun ev_start_light_strobing = EV_StartLightStrobing(line : Line*)
  fun ev_turn_tag_lights_off = EV_TurnTagLightsOff(line : Line*)

  fun ev_light_turn_on = EV_LightTurnOn(line : Line*, bright : LibC::Int)

  fun t_glow = T_Glow(g : Glow*)
  fun p_spawn_glowing_light = P_SpawnGlowingLight(sector : Sector*)

  #
  # P_SWITCH
  #
  struct Switchlist
    name1 : LibC::Char[9]
    name2 : LibC::Char[9]
    episode : LibC::Short
  end

  enum Bwhere
    Top
    Middle
    Bottom
  end

  struct Button
    line : Line*
    where : Bwhere
    btexture : LibC::Int
    btimer : LibC::Int
    soundorg : Mobj*
  end

  # max # of wall switches in a level
  MAXSWITCHES = 50

  # 4 players, 4 buttons each at once, max.
  MAXBUTTONS = 16

  # 1 second, in ticks.
  BUTTONTIMES = 35

  $buttonlist : Button[MAXBUTTONS]

  fun p_change_switch_texture = P_ChangeSwitchTexture(line : Line*, use_again : LibC::Int)
  fun p_init_switch_list = P_InitSwitchList

  #
  # P_PLATS
  #
  enum Platenum
    Up
    Down
    Waiting
    InStasis
  end

  enum Plattype
    PerpetualRaise
    DownWaitUpStay
    RaiseAndChange
    RaiseToNearestAndChange
    BlazeDWUS
  end

  struct Plat
    thinker : Thinker
    sector : Sector*
    speed : Fixed
    low : Fixed
    hight : Fixed
    wait : LibC::Int
    count : LibC::Int
    status : Platenum
    oldstatus : Platenum
    crush : DoomBool
    tag : LibC::Int
    type : Plattype
  end

  PLATWAIT  = 3
  PLATSPEED = FRACUNIT
  MAXPLATS  = 30

  $activeplats : Plat*[MAXPLATS]

  fun t_plat_raise = T_PlatRaise(plat : Plat*)
  fun ev_do_plat = EV_DoPlat(line : Line*, type : Plattype, amount : LibC::Int) : LibC::Int
  fun p_add_active_plat = P_AddActivePlat(plat : Plat*)
  fun p_remove_active_plat = P_RemoveActivePlat(plat : Plat*)
  fun ev_stop_plat = EV_StopPlat(line : Line*)
  fun p_activate_in_stasis = P_ActivateInStasis(tag : LibC::Int)

  #
  # P_DOORS
  #
  enum Vldoorenum
    DoorNormal
    Close30ThenOpen
    DoorClose
    DoorOpen
    RaiseIn5Mins
    BlazeRaise
    BlazeOpen
    BlazeClose
  end

  struct Vldoor
    thinker : Thinker
    type : Vldoorenum
    sector : Sector*
    topheight : Fixed
    speed : Fixed

    # 1 = up, 0 = waiting at top, -1 = down
    direction : LibC::Int

    # tics to wait at the top
    topwait : LibC::Int

    # (keep in case a door going down is reset)
    # when it reaches 0, start going down
    topcountdown : LibC::Int
  end

  VDOORSPEED = FRACUNIT*2
  VDOORWAIT  = 150

  fun ev_vertical_door = EV_VerticalDoor(line : Line*, thing : Mobj*)
  fun ev_do_door = EV_DoDoor(line : Line*, type : Vldoorenum) : LibC::Int
  fun ev_do_locked_door = EV_DoLockedDoor(line : Line*, type : Vldoorenum, thing : Mobj*) : LibC::Int
  fun t_vertical_door = T_VerticalDoor(door : Vldoor*)
  fun p_spawn_door_close_in_30 = P_SpawnDoorCloseIn30(sec : Sector*)
  fun p_spawn_door_raise_in_5_mins = P_SpawnDoorRaiseIn5Mins(sec : Sector*, secnum : LibC::Int)

  #
  # P_CEILNG
  #
  enum Ceilingenum
    LowerToFloor
    RaiseToHighest
    LowerAndCrush
    CrushAndRaise
    FastCrushAndRaise
    SilentCrushAndRaise
  end

  struct Ceiling
    thinker : Thinker
    type : Ceilingenum
    sector : Sector*
    bottomheight : Fixed
    topheight : Fixed
    speed : Fixed
    crush : DoomBool

    # 1 = up, 0 = waiting, -1 = down
    direction : LibC::Int

    # ID
    tag : LibC::Int
    olddirection : LibC::Int
  end

  CEILSPEED   = FRACUNIT
  CEILWAIT    = 150
  MAXCEILINGS =  30

  $activeceilings : Ceiling*[MAXCEILINGS]

  fun ev_do_ceiling = EV_DoCeiling(line : Line*, type : Ceilingenum) : LibC::Int
  fun t_move_ceiling = T_MoveCeiling(ceiling : Ceiling*)
  fun p_add_active_ceiling = P_AddActiveCeiling(c : Ceiling*)
  fun p_remove_active_ceiling = P_RemoveActiveCeiling(c : Ceiling*)
  fun ev_ceiling_crush_stop = EV_CeilingCrushStop(line : Line*) : LibC::Int
  fun p_activate_in_stasis_ceiling = P_ActivateInStasisCeiling(line : Line*)

  #
  # P_FLOOR
  #
  enum Floorenum
    # lower floor to highest surrounding floor
    LowerFloor

    # lower floor to lowest surrounding floor
    LowerFloorToLowest

    # lower floor to highest surrounding floor VERY FAST
    TurboLower

    # raise floor to lowest surrounding CEILING
    RaiseFloor

    # raise floor to next highest surrounding floor
    RaiseFloorToNearest

    # raise floor to shortest height texture around it
    RaiseToTexture

    # lower floor to lowest surrounding floor
    #  and change floorpic
    LowerAndChange

    RaiseFloor24
    RaiseFloor24AndChange
    RaiseFloorCrush

    # raise to next highest floor, turbo-speed
    RaiseFloorTurbo
    DonutRaise
    RaiseFloor512
  end

  enum Stairenum
    Build8  # slowly build by 8
    Turbo16 # quickly build by 16
  end

  struct Floormove
    thinker : Thinker
    type : Floorenum
    crush : DoomBool
    sector : Sector*
    direction : LibC::Int
    newspecial : LibC::Int
    texture : LibC::Short
    floordestheight : Fixed
    speed : Fixed
  end

  FLOORSPEED = FRACUNIT

  enum Result
    Ok
    Crushed
    Pastdest
  end

  fun t_move_plane = T_MovePlane(sector : Sector*, speed : Fixed, dest : Fixed, crush : DoomBool, floor_or_ceiling : LibC::Int, direction : LibC::Int) : Result
  fun ev_build_stairs = EV_BuildStairs(line : Line*, type : Stairenum) : LibC::Int
  fun ev_do_floor = EV_DoFloor(line : Line*, floortype : Floorenum) : LibC::Int
  fun t_move_floor = T_MoveFloor(floor : Floormove*)

  #
  # P_TELEPT
  #
  fun ev_teleport = EV_Teleport(line : Line*, side : LibC::Int, think : Mobj*) : LibC::Int

  # __R_BSP__
  $curline : Seg*
  $sidedef : Side*
  $linedef : Line*
  $frontsector : Sector*
  $backsector : Sector*

  $rw_w : LibC::Int
  $rw_stopx : LibC::Int

  $segtextured : DoomBool

  # false if the back side is the same plane
  $markfloor : DoomBool
  $markceiling : DoomBool

  $skymap : DoomBool

  $drawsegs : Drawseg[MAXDRAWSEGS]
  $ds_p : Drawseg*

  $hscalelight : Lighttable**
  $vscalelight : Lighttable**
  $dscalelight : Lighttable**

  alias Drawfunc = Proc(LibC::Int, LibC::Int, Nil)

  # BSP?
  fun r_clear_clip_segs = R_ClearClipSegs
  fun r_clear_draw_segs = R_ClearDrawSegs
  fun r_render_bsp_node = R_RenderBSPNode(bspnum : LibC::Int)

  # __R_DRAW__

  $dc_colormap : Lighttable*
  $dc_x : LibC::Int
  $dc_yl : LibC::Int
  $dc_yh : LibC::Int
  $dc_iscale : Fixed
  $dc_texturemid : Fixed

  # first pixel in a column
  $dc_source : Byte*

  # The span blitting interface.
  # Hook in assembler or system specific BLT
  #  here.
  fun r_draw_column = R_DrawColumn
  fun r_draw_column_low = R_DrawColumnLow

  # The Spectre/Invisibility effect.
  fun r_draw_fuzz_column = R_DrawFuzzColumn
  fun r_draw_fuzz_column_low = R_DrawFuzzColumnLow

  # Draw with color translation tables,
  #  for player sprite rendering,
  #  Green/Red/Blue/Indigo shirts.
  fun r_draw_translated_column = R_DrawTranslatedColumn
  fun r_draw_translated_column_low = R_DrawTranslatedColumnLow

  fun r_video_erase = R_VideoErase(ofs : LibC::UInt, count : LibC::Int)

  $ds_y : LibC::Int
  $ds_x1 : LibC::Int
  $ds_x2 : LibC::Int

  $ds_colormap : Lighttable*

  $ds_xfrac : Fixed
  $ds_yfrac : Fixed
  $ds_xstep : Fixed
  $ds_ystep : Fixed

  # start of a 64*64 tile image
  $ds_source : Byte*

  $translationtables : Byte*
  $dc_translation : Byte*

  # Span blitting for rows, floor/ceiling.
  # No Sepctre effect needed.
  fun r_draw_span = R_DrawSpan

  # Low resolution mode, 160x200?
  fun r_draw_span_low = R_DrawSpanLow

  fun r_init_buffer = R_InitBuffer(width : LibC::Int, height : LibC::Int)

  # Initialize color translation tables,
  #  for player rendering etc.
  fun r_init_translation_tables = R_InitTranslationTables

  # Rendering function.
  fun r_fill_back_screen = R_FillBackScreen

  # If the view size is not full screen, draws a border around it.
  fun r_draw_view_border = R_DrawViewBorder

  # __R_SEGS__

  fun r_render_masked_seg_range = R_RenderMaskedSegRange(ds : Drawseg*, x1 : LibC::Int, x2 : LibC::Int)

  # __R_STATE__

  # needed for texture pegging
  $textureheight : Fixed*

  # needed for pre rendering (fracs)
  $spritewidth : Fixed*

  $spriteoffset : Fixed*
  $spritetopoffset : Fixed*

  $colormaps : Lighttable*

  $viewwidth : LibC::Int
  $scaledviewwidth : LibC::Int
  $viewheight : LibC::Int

  $firstflat : LibC::Int

  # for global animation
  $flattranslation : LibC::Int*
  $texturetranslation : LibC::Int*

  # Sprite....
  $firstspritelump : LibC::Int
  $lastspritelump : LibC::Int
  $numspritelumps : LibC::Int

  #
  # Lookup tables for map data.
  #
  $numsprites : LibC::Int
  $sprites : Spritedef*

  $numvertexes : LibC::Int
  $vertexes : Vertex*

  $numsegs : LibC::Int
  $segs : Seg*

  $numsectors : LibC::Int
  $sectors : Sector*

  $numsubsectors : LibC::Int
  $subsectors : Subsector*

  $numnodes : LibC::Int
  $nodes : Node*

  $numlines : LibC::Int
  $lines : Line*

  $numsides : LibC::Int
  $sides : Side*

  #
  # POV data.
  #
  $viewx : Fixed
  $viewy : Fixed
  $viewz : Fixed

  $viewangle : Angle
  $viewplayer : Player*

  # ?
  $clipangle : Angle

  VIEWANGLETOX_SIZE = FINEANGLES//2
  $viewangletox : LibC::Int[VIEWANGLETOX_SIZE]
  XTOVIEWANGLE_SIZE = SCREENWIDTH + 1
  $xtoviewangle : Angle[XTOVIEWANGLE_SIZE]

  $rw_distance : Fixed
  $rw_normalangle : Fixed

  # angle to line origin
  $rw_angle1 : LibC::Int

  # Segs count?
  $sscount : LibC::Int

  $floorplane : Visplane*
  $ceilingplane : Visplane*

  # __R_DATA__

  # Retrieve column data for span blitting.
  fun r_get_column = R_GetColumn(tex : LibC::Int, col : LibC::Int) : Byte*

  # I/O, setting up the stuff.
  fun r_init_data = R_InitData
  fun r_precache_level = R_PrecacheLevel

  # Retrieval.
  # Floor/ceiling opaque texture tiles,
  # lookup by name. For animation?
  fun r_flat_num_for_name = R_FlatNumForName(name : LibC::Char*) : LibC::Int

  # Called by P_Ticker for switches and animations,
  # returns the texture number for the texture name.
  fun r_texture_num_for_name = R_TextureNumForName(name : LibC::Char*) : LibC::Int
  fun r_check_texture_num_for_name = R_CheckTextureNumForName(name : LibC::Char*) : LibC::Int

  # __R_MAIN__

  #
  # POV related.
  #
  $viewcos : Fixed
  $viewsin : Fixed

  $viewwidth : LibC::Int
  $viewheight : LibC::Int
  $viewwindowx : LibC::Int
  $viewwindowy : LibC::Int

  $centerx : LibC::Int
  $centery : LibC::Int

  $centerxfrac : Fixed
  $centeryfrac : Fixed
  $projection : Fixed

  $validcount : LibC::Int

  $linecount : LibC::Int
  $loopcount : LibC::Int

  #
  # Lighting LUT.
  # Used for z-depth cuing per column/row,
  # and other lighting effects (sector ambient, flash).
  #

  # Lighting constants.
  # Now why not 32 levels here?
  LIGHTLEVELS   = 16
  LIGHTSEGSHIFT =  4

  MAXLIGHTSCALE   =  48
  LIGHTSCALESHIFT =  12
  MAXLIGHTZ       = 128
  LIGHTZSHIFT     =  20

  $scalelight : Lighttable*[MAXLIGHTSCALE][LIGHTLEVELS]
  $scalelightfixed : Lighttable*[MAXLIGHTSCALE]
  $zlight : Lighttable*[MAXLIGHTZ][LIGHTLEVELS]

  $extralight : LibC::Int
  $fixedcolormap : Lighttable*

  # Number of diminishing brightness levels.
  # There a 0-31, i.e. 32 LUT in the COLORMAP lump.
  NUMCOLORMAPS = 32

  # Blocky/low detail mode.
  # B remove this?
  #  0 = high, 1 = low
  $detailshift : LibC::Int

  #
  # Function pointers to switch refresh/drawing functions.
  # Used to select shadow mode etc.
  #
  alias Colfunc = Proc(Nil)
  alias Basecolfunc = Proc(Nil)
  alias Fuzzcolfunc = Proc(Nil)
  # No shadow effects on floors.
  alias Spanfunc = Proc(Nil)

  #
  # Utility functions.
  fun r_point_on_side = R_PointOnSide(x : Fixed, y : Fixed, node : Node*) : LibC::Int
  fun r_point_on_seg_side = R_PointOnSegSide(x : Fixed, y : Fixed, line : Seg*) : LibC::Int
  fun r_point_to_angle = R_PointToAngle(x : Fixed, y : Fixed) : Angle
  fun r_point_to_angle2 = R_PointToAngle2(x1 : Fixed, y1 : Fixed, x2 : Fixed, y2 : Fixed) : Angle
  fun r_point_to_dist = R_PointToDist(x : Fixed, y : Fixed) : Fixed
  fun r_scale_from_global_angle = R_ScaleFromGlobalAngle(visangle : Angle) : Fixed
  fun r_point_in_subsector = R_PointInSubsector(x : Fixed, y : Fixed) : Subsector*
  fun r_add_point_to_box = R_AddPointToBox(x : LibC::Int, y : LibC::Int, box : Fixed*)

  #
  # REFRESH - the actual rendering functions.
  #

  # Called by G_Drawer.
  fun r_render_player_view = R_RenderPlayerView(player : Player*)

  # Called by startup code.
  fun r_init = R_Init

  # Called by M_Responder.
  fun r_set_view_size = R_SetViewSize(blocks : LibC::Int, detail : LibC::Int)

  # __R_PLANE__

  # Visplane related.
  $lastopening : LibC::Short*

  $floorclip : LibC::Short[SCREENWIDTH]
  $ceilingclip : LibC::Short[SCREENWIDTH]

  $yslope : Fixed[SCREENHEIGHT]
  $distscale : Fixed[SCREENWIDTH]

  fun r_init_planes = R_InitPlanes
  fun r_clear_planes = R_ClearPlanes
  fun r_map_plane = R_MapPlane(y : LibC::Int, x1 : LibC::Int, x2 : LibC::Int)
  fun r_make_spans = R_MakeSpans(x : LibC::Int, t1 : LibC::Int, b1 : LibC::Int, t2 : LibC::Int, b2 : LibC::Int)
  fun r_draw_planes = R_DrawPlanes
  fun r_find_plane = R_FindPlane(height : Fixed, picnum : LibC::Int, lightlevel : LibC::Int) : Visplane*
  fun r_check_plane = R_CheckPlane(pl : Visplane*, start : LibC::Int, stop : LibC::Int) : Visplane*

  # __R_THINGS__

  MAXVISSPRITES = 128

  $vissprites : Vissprite[MAXVISSPRITES]
  $vissprite_p : Vissprite*
  $vsprsortedhead : Vissprite

  # Constant arrays used for psprite clipping
  # and initializing clipping.
  $negonearray : LibC::Short[SCREENWIDTH]
  $screenheightarray : LibC::Short[SCREENWIDTH]

  # vars for R_DrawMaskedColumn
  $mfloorclip : LibC::Short*
  $mceilingclip : LibC::Short*
  $spryscale : Fixed
  $sprtopscreen : Fixed

  $pspritescale : Fixed
  $pspriteiscale : Fixed

  fun r_draw_masked_column = R_DrawMaskedColumn(column : Column*)
  fun r_sort_vis_sprites = R_SortVisSprites
  fun r_add_sprites = R_AddSprites(sec : Sector*)
  fun r_init_sprites = R_InitSprites(namelist : LibC::Char**)
  fun r_clear_sprites = R_ClearSprites
  fun r_draw_masked = R_DrawMasked

  # __R_LOCAL__

  FLOATSPEED = (FRACUNIT*4)

  MAXHEALTH  = 100
  VIEWHEIGHT = (41*FRACUNIT)

  # mapblocks are used to check movement
  # against lines and things
  MAPBLOCKUNITS = 128
  MAPBLOCKSIZE  = (MAPBLOCKUNITS*FRACUNIT)
  MAPBLOCKSHIFT = (FRACBITS + 7)
  MAPBMASK      = (MAPBLOCKSIZE - 1)
  MAPBTOFRAC    = (MAPBLOCKSHIFT - FRACBITS)

  # player radius for movement checking
  PLAYERRADIUS = 16*FRACUNIT

  # MAXRADIUS is for precalculated sector block boxes
  # the spider demon is larger,
  # but we do not have any moving sectors nearby
  MAXRADIUS = 32*FRACUNIT

  GRAVITY = FRACUNIT
  MAXMOVE = (30*FRACUNIT)

  USERANGE     = (64*FRACUNIT)
  MELEERANGE   = (64*FRACUNIT)
  MISSILERANGE = (32*64*FRACUNIT)

  # follow a player exlusively for 3 seconds
  BASETHRESHOLD = 100

  #
  # P_TICK
  #

  # both the head and tail of the thinker list
  $thinkercap : Thinker

  fun p_init_thinkers = P_InitThinkers
  fun p_add_thinker = P_AddThinker(thinker : Thinker*)
  fun p_remove_thinker = P_RemoveThinker(thinker : Thinker*)

  #
  # P_PSPR
  #
  fun p_setup_psprites = P_SetupPsprites(curplayer : Player*)
  fun p_move_psprites = P_MovePsprites(curplayer : Player*)
  fun p_drop_weapon = P_DropWeapon(player : Player*)

  #
  # P_USER
  #
  fun p_player_think = P_PlayerThink(player : Player*)

  #
  # P_MOBJ
  #
  ONFLOORZ   = LibC::Int::MIN
  ONCEILINGZ = LibC::Int::MAX

  # Time interval for item respawning.
  ITEMQUESIZE = 128

  $itemrespawnque : Mapthing[ITEMQUESIZE]
  $itemrespawntime : LibC::Int[ITEMQUESIZE]
  $iquehead : LibC::Int
  $iquetail : LibC::Int

  fun p_respawn_specials = P_RespawnSpecials
  fun p_spawn_mobj = P_SpawnMobj(x : Fixed, y : Fixed, z : Fixed, type : Mobjtype) : Mobj*
  fun p_remove_mobj = P_RemoveMobj(mobj : Mobj*)
  fun p_set_mobj_state = P_SetMobjState(mobj : Mobj*, state : Statenum) : DoomBool
  fun p_mobj_thinker = P_MobjThinker(mobj : Mobj*)
  fun p_spawn_puff = P_SpawnPuff(x : Fixed, y : Fixed, z : Fixed)
  fun p_spawn_blood = P_SpawnBlood(x : Fixed, y : Fixed, z : Fixed, damage : LibC::Int)
  fun p_spawn_missile = P_SpawnMissile(source : Mobj*, dest : Mobj*, type : Mobjtype) : Mobj*
  fun p_spawn_player_missile = P_SpawnPlayerMissile(source : Mobj*, type : Mobjtype)

  #
  # P_ENEMY
  #
  fun p_noise_alert = P_NoiseAlert(target : Mobj*, emmiter : Mobj*)

  #
  # P_MAPUTL
  #
  struct Divline
    x : Fixed
    y : Fixed
    dx : Fixed
    dy : Fixed
  end

  union InterceptD
    thing : Mobj*
    line : Line*
  end

  struct Intercept
    frac : Fixed # along trace line
    isaline : DoomBool
    d : InterceptD
  end

  MAXINTERCEPTS = 128
  $intercepts : Intercept[MAXINTERCEPTS]
  $intercept_p : Intercept*

  alias Traverser = Proc(Intercept*, DoomBool)

  fun p_aprox_distance = P_AproxDistance(dx : Fixed, dy : Fixed) : Fixed
  fun p_point_on_line_side = P_PointOnLineSide(x : Fixed, y : Fixed, line : Line*) : LibC::Int
  fun p_point_on_divline_side = P_PointOnDivlineSide(x : Fixed, y : Fixed, line : Divline*) : LibC::Int
  fun p_make_divline = P_MakeDivline(li : Line*, dl : Divline*)
  fun p_intercept_vector = P_InterceptVector(v2 : Divline*, v1 : Divline*) : Fixed
  fun p_box_on_line_side = P_BoxOnLineSide(tmbox : Fixed*, ld : Line*) : LibC::Int

  $opentop : Fixed
  $openbottom : Fixed
  $openrange : Fixed
  $lowfloor : Fixed

  fun p_line_opening = P_LineOpening(linedef : Line*)

  fun p_block_lines_iterator = P_BlockLinesIterator(x : LibC::Int, y : LibC::Int, func : Proc(Line*, DoomBool)) : DoomBool
  fun p_block_things_iterator = P_BlockThingsIterator(x : LibC::Int, y : LibC::Int, func : Proc(Mobj*, DoomBool)) : DoomBool

  PT_ADDLINES  = 1
  PT_ADDTHINGS = 2
  PT_EARLYOUT  = 4

  $trace : Divline

  fun p_path_traverse = P_PathTraverse(x1 : Fixed, y1 : Fixed, x2 : Fixed, y2 : Fixed, flags : LibC::Int, trav : Proc(Intercept*, DoomBool)) : DoomBool
  fun p_unset_thing_position = P_UnsetThingPosition(thing : Mobj*)
  fun p_set_thing_position = P_SetThingPosition(thing : Mobj*)

  #
  # P_MAP
  #

  # If "floatok" true, move would be ok
  # if within "tmfloorz - tmceilingz".
  $floatok : DoomBool
  $tmfloorz : Fixed
  $tmceilingz : Fixed

  # keep track of the line that lowers the ceiling,
  # so missiles don't explode against sky hack walls
  $ceilingline : Line*

  fun p_check_position = P_CheckPosition(thing : Mobj*, x : Fixed, y : Fixed) : DoomBool
  fun p_try_move = P_TryMove(thing : Mobj*, x : Fixed, y : Fixed) : DoomBool
  fun p_teleport_move = P_TeleportMove(thing : Mobj*, x : Fixed, y : Fixed) : DoomBool
  fun p_slide_move = P_SlideMove(mo : Mobj*)
  fun p_check_sight = P_CheckSight(t1 : Mobj*, t2 : Mobj*) : DoomBool
  fun p_use_lines = P_UseLines(player : Player*)
  fun p_change_sector = P_ChangeSector(sector : Sector*, crunch : DoomBool) : DoomBool

  $linetarget : Mobj* # who got hit (or 0)
  $shootthing : Mobj*

  fun p_aim_line_attack = P_AimLineAttack(t1 : Mobj*, angle : Angle, distance : Fixed) : Fixed
  fun p_line_attack = P_LineAttack(t1 : Mobj*, angle : Angle, distance : Fixed, slope : Fixed, damage : LibC::Int)
  fun p_radius_attack = P_RadiusAttack(spot : Mobj*, source : Mobj*, damage : LibC::Int)

  #
  # P_SETUP
  #
  $rejectmatrix : Byte*        # for fast sight rejection
  $blockmaplump : LibC::Short* # offsets in blockmap are from here
  $blockmap : LibC::Short*
  $bmapwidth : LibC::Int
  $bmapheight : LibC::Int # in mapblocks
  $bmaporgx : Fixed
  $bmaporgy : Fixed    # origin of block map
  $blocklinks : Mobj** # for thing chains

  #
  # P_INTER
  #
  $maxammo : LibC::Int[Ammotype::NUMAMMO]
  $clipammo : LibC::Int[Ammotype::NUMAMMO]

  fun p_touch_special_thing = P_TouchSpecialThing(special : Mobj*, toucher : Mobj*)
  fun p_damage_mobj = P_DamageMobj(target : Mobj*, inflictor : Mobj*, source : Mobj*, damage : LibC::Int)

  # __STLIB__

  #
  # Background and foreground screen numbers
  #
  STLIB_BG = 4
  STLIB_FG = 0

  #
  # Typedefs of widgets
  #

  # Number widget
  struct ST_Number
    # upper right-hand corner
    #  of the number (right-justified)
    x : LibC::Int
    y : LibC::Int

    # max # of digits in number
    width : LibC::Int

    # last number value
    oldnum : LibC::Int

    # pointer to current value
    num : LibC::Int*

    # pointer to doom_boolean stating
    #  whether to update number
    on : DoomBool*

    # list of patches for 0-9
    p : Patch**

    # user data
    data : LibC::Int
  end

  # Percent widget ("child" of number widget,
  #  or, more precisely, contains a number widget.)
  struct ST_Percent
    # number information
    n : ST_Number

    # percent sign graphic
    p : Patch*
  end

  # Multiple Icon widget
  struct ST_Multicon
    # center-justified location of icons
    x : LibC::Int
    y : LibC::Int

    # last icon number
    oldinum : LibC::Int

    # pointer to current icon
    inum : LibC::Int*

    # pointer to doom_boolean stating
    #  whether to update icon
    on : DoomBool*

    # list of icons
    p : Patch**

    # user data
    data : LibC::Int
  end

  # Binary Icon widget
  struct ST_Binicon
    # center-justified location of icons
    x : LibC::Int
    y : LibC::Int

    # last icon value
    oldval : LibC::Int

    # pointer to current icon status
    val : DoomBool*

    # pointer to bool
    #  stating whether to update icon
    on : DoomBool*

    p : Patch*       # icon
    data : LibC::Int # user data
  end

  #
  # Widget creation, access, and update routines
  #

  # Initializes widget library.
  # More precisely, initialize STMINUS,
  # everything else is done somewhere else.
  #
  fun stlib_init = STlib_init

  # Number widget routines
  fun stlib_init_num = STlib_initNum(n : ST_Number*,
                                     x : LibC::Int,
                                     y : LibC::Int,
                                     pl : Patch**,
                                     num : LibC::Int*,
                                     on : DoomBool*,
                                     width : LibC::Int)

  fun stlib_update_num = STlib_updateNum(n : ST_Number*, refresh : DoomBool)

  # Percent widget routines
  fun stlib_init_percent = STlib_initPercent(p : ST_Percent*,
                                             x : LibC::Int,
                                             y : LibC::Int,
                                             pl : Patch**,
                                             num : LibC::Int*,
                                             on : DoomBool*,
                                             percent : Patch*)

  fun stlib_update_percent = STlib_updatePercent(per : ST_Percent*, refresh : LibC::Int)

  # Multiple Icon widget routines
  fun stlib_init_mult_icon = STlib_initMultIcon(mi : ST_Multicon*,
                                                x : LibC::Int,
                                                y : LibC::Int,
                                                il : Patch**,
                                                inum : LibC::Int*,
                                                on : DoomBool*)

  fun stlib_update_mult_icon = STlib_updateMultIcon(mi : ST_Multicon*, refresh : DoomBool)

  # Binary Icon widget routines
  fun stlib_init_bin_con = STlib_initBinIcon(b : ST_Binicon*,
                                             x : LibC::Int,
                                             y : LibC::Int,
                                             i : Patch*,
                                             val : DoomBool*,
                                             on : DoomBool*)

  fun stlib_update_bin_icon = STlib_updateBinIcon(bi : ST_Binicon*, refresh : DoomBool)

  # __V_VIDEO__

  #
  # VIDEO
  #

  CENTERY = (SCREENHEIGHT//2)

  # Screen 0 is the screen updated by I_Update screen.
  # Screen 1 is an extra buffer.
  $screens : Byte*[5]
  $dirtybox : LibC::Int[4]
  $gammatable : Byte[256][5]
  $usegamma : LibC::Int

  # Allocates buffer screens, call before R_Init.
  fun v_init = V_Init

  fun v_copy_rect = V_CopyRect(srcx : LibC::Int,
                               srcy : LibC::Int,
                               srcscrn : LibC::Int,
                               width : LibC::Int,
                               height : LibC::Int,
                               destx : LibC::Int,
                               desty : LibC::Int,
                               destscrn : LibC::Int,)

  fun v_draw_patch = V_DrawPatch(x : LibC::Int,
                                 y : LibC::Int,
                                 scrn : LibC::Int,
                                 patch : Patch*)

  fun v_draw_patch_direct = V_DrawPatchDirect(x : LibC::Int,
                                              y : LibC::Int,
                                              scrn : LibC::Int,
                                              patch : Patch*)

  fun v_draw_patch_rect_direct = V_DrawPatchRectDirect(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : Patch*, src_x : LibC::Int, src_w : LibC::Int)

  # Draw a linear block of pixels into the view buffer.
  fun v_draw_block = V_DrawBlock(x : LibC::Int,
                                 y : LibC::Int,
                                 scrn : LibC::Int,
                                 width : LibC::Int,
                                 height : LibC::Int,
                                 src : Byte*)

  # Reads a linear block of pixels into the view buffer.
  fun v_get_block = V_GetBlock(x : LibC::Int,
                               y : LibC::Int,
                               scrn : LibC::Int,
                               width : LibC::Int,
                               height : LibC::Int,
                               dest : Byte*)

  fun v_mark_rect = V_MarkRect(x : LibC::Int,
                               y : LibC::Int,
                               width : LibC::Int,
                               height : LibC::Int)

  # __W_WAD__

  #
  # TYPES
  #
  struct Wadinfo
    # Should be "IWAD" or "PWAD".
    identification : LibC::Char[4]
    numlumps : LibC::Int
    infotableofs : LibC::Int
  end

  struct Filelump
    filepos : LibC::Int
    size : LibC::Int
    name : LibC::Char[8]
  end

  #
  # WADFILE I/O related stuff.
  #
  struct Lumpinfo
    name : LibC::Char[8]
    handle : Void*
    position : LibC::Int
    size : LibC::Int
  end

  $lumpcache : Void**
  $lumpinfo : Lumpinfo*
  $numlumps : LibC::Int

  fun w_init_multiple_files = W_InitMultipleFiles(filenames : LibC::Char**)
  fun w_reload = W_Reload

  fun w_check_num_for_name = W_CheckNumForName(name : LibC::Char*) : LibC::Int
  fun w_get_num_for_name = W_GetNumForName(name : LibC::Char*) : LibC::Int

  fun w_lump_length = W_LumpLength(lump : LibC::Int) : LibC::Int
  fun w_read_lump = W_ReadLump(lump : LibC::Int, dest : Void*)

  fun w_cache_lump_num = W_CacheLumpNum(lump : LibC::Int, tag : LibC::Int) : Void*
  fun w_cache_lump_name = W_CacheLumpName(name : LibC::Char*, tag : LibC::Int) : Void*

  # __WI_STUFF__

  # States for the intermission
  enum Stateenum
    NoState     = -1
    StatCount
    ShowNextLoc
  end

  # Called by main loop, animate the intermission.
  fun wi_ticker = WI_Ticker

  # Called by main loop,
  # draws the intermission directly into the screen buffer.
  fun wi_drawer = WI_Drawer

  # Setup for an intermission screen.
  fun wi_start = WI_Start(wbstartstruct : Wbstartstruct*)

  # __Z_ZONE__

  #
  # ZONE MEMORY
  # PU - purge tags.
  # Rags < 100 are not overwritten until freed.
  PU_STATIC  =  1 # static entire execution time
  PU_SOUND   =  2 # static while playing
  PU_MUSIC   =  3 # static while playing
  PU_DAVE    =  4 # anything else Dave wants static
  PU_LEVEL   = 50 # static until level exited
  PU_LEVSPEC = 51 # a special thinker in a level
  # Tags >= 100 are purgable whenever needed.
  PU_PURGELEVEL = 100
  PU_CACHE      = 101

  fun z_init = Z_Init
  fun z_malloc = Z_Malloc(size : LibC::Int, tag : LibC::Int, ptr : Void*) : Void*
  fun z_free = Z_Free(ptr : Void*)
  fun z_free_tags = Z_FreeTags(lowtag : LibC::Int, hightag : LibC::Int)
  fun z_dump_heap = Z_DumpHeap(lowtag : LibC::Int, hightag : LibC::Int)
  fun z_file_dump_heap = Z_FileDumpHeap(f : Void*)
  fun z_check_heap = Z_CheckHeap
  fun z_change_tag2 = Z_ChangeTag2(ptr : Void*, tag : LibC::Int)
  fun z_free_memory = Z_FreeMemory : LibC::Int

  struct Memblock
    size : LibC::Int # including the header and possibly tiny fragments
    user : Void**    # 0 if a free block
    tag : LibC::Int  # purgelevel
    id : LibC::Int   # should be ZONEID
    next : Memblock*
    prev : Memblock*
  end

  # IMPLEMENTATION

  $screens : Byte*[5]
  SCREEN_PALETTE_SIZE = 256 * 3
  $screen_palette : LibC::UChar[SCREEN_PALETTE_SIZE]
  $is_wiping_screen : DoomBool
  $defaults : Default[40]
  $numdefaults : LibC::Int
  $mixbuffer : LibC::Short[2048]

  $screen_buffer : LibC::UChar*
  $final_screen_buffer : LibC::UChar*
  $last_update_time : LibC::Int
  $button_states : LibC::Int[3]
  $itoa_buf : LibC::Char[20]

  $error_buf : LibC::Char[260]
  $doom_print : DoomPrintFn
  $doom_malloc : DoomMallocFn
  $doom_free : DoomFreeFn
  $doom_open : DoomOpenFn
  $doom_close : DoomCloseFn
  $doom_read : DoomReadFn
  $doom_write : DoomWriteFn
  $doom_seek : DoomSeekFn
  $doom_tell : DoomTellFn
  $doom_eof : DoomEofFn
  $doom_gettime : DoomGettimeFn
  $doom_exit : DoomExitFn
  $doom_getenv : DoomGetenvFn

  $setsizeneeded : DoomBool
  $setblocks : LibC::Int
  $setdetail : LibC::Int

  $usemouse : LibC::Int
  $usejoystick : LibC::Int
  $crosshair : LibC::Int
  $always_run : LibC::Int

  fun d_doom_loop = D_DoomLoop
  fun d_update_wipe = D_UpdateWipe

  REDS        = (256 - 5*16)
  REDRANGE    = 16
  BLUES       = (256 - 4*16 + 8)
  BLUERANGE   = 8
  GREENS      = (7*16)
  GREENRANGE  = 16
  GRAYS       = (6*16)
  GRAYSRANGE  = 16
  BROWNS      = (4*16)
  BROWNRANGE  = 16
  YELLOWS     = (256 - 32 + 7)
  YELLOWRANGE = 1
  BLACK       = 0
  WHITE       = (256 - 47)

  # Automap colors
  BACKGROUND       = BLACK
  YOURCOLORS       = WHITE
  YOURRANGE        = 0
  WALLCOLORS       = REDS
  WALLRANGE        = REDRANGE
  TSWALLCOLORS     = GRAYS
  TSWALLRANGE      = GRAYSRANGE
  FDWALLCOLORS     = BROWNS
  FDWALLRANGE      = BROWNRANGE
  CDWALLCOLORS     = YELLOWS
  CDWALLRANGE      = YELLOWRANGE
  THINGCOLORS      = GREENS
  THINGRANGE       = GREENRANGE
  SECRETWALLCOLORS = WALLCOLORS
  SECRETWALLRANGE  = WALLRANGE
  GRIDCOLORS       = (GRAYS + GRAYSRANGE/2)
  GRIDRANGE        = 0
  XHAIRCOLORS      = GRAYS

  # drawing stuff
  FB = 0

  AM_PANDOWNKEY   = KEY_DOWNARROW
  AM_PANUPKEY     = KEY_UPARROW
  AM_PANRIGHTKEY  = KEY_RIGHTARROW
  AM_PANLEFTKEY   = KEY_LEFTARROW
  AM_ZOOMINKEY    = '='
  AM_ZOOMOUTKEY   = '-'
  AM_STARTKEY     = KEY_TAB
  AM_ENDKEY       = KEY_TAB
  AM_GOBIGKEY     = '0'
  AM_FOLLOWKEY    = 'f'
  AM_GRIDKEY      = 'g'
  AM_MARKKEY      = 'm'
  AM_CLEARMARKKEY = 'c'

  AM_NUMMARKPOINTS = 10

  # scale on entry
  INITSCALEMTOF = (0.2*FRACUNIT)
  # how much the automap moves window per tic in frame-buffer coordinates
  # moves 140 pixels in 1 second
  F_PANINC = 4
  # how much zoom-in per tic
  # goes to 2x in 1 second
  M_ZOOMIN = (1.02*FRACUNIT).to_i32
  # how much zoom-out per tic
  # pulls out to 0.5x in 1 second
  M_ZOOMOUT = (FRACUNIT/1.02).to_i32

  # the following is crap
  LINE_NEVERSEE = ML_DONTDRAW

  struct Fpoint
    x : LibC::Int
    y : LibC::Int
  end

  struct Fline
    a : Fpoint
    b : Fpoint
  end

  struct Mpoint
    x : Fixed
    y : Fixed
  end

  struct Mline
    a : Mpoint
    b : Mpoint
  end

  struct Islope
    slp : Fixed
    islp : Fixed
  end

  #
  # The vector graphics for the automap.
  # A line drawing of the player pointing right,
  # starting from the middle.
  #
  R                 = ((8*PLAYERRADIUS)//7)
  NUMPLYRLINES      = 7
  $player_arrow : Mline[NUMPLYRLINES]
  NUMCHEATPLYRLINES = 16
  $cheat_player_arrow : Mline[NUMCHEATPLYRLINES]

  NUMTRIANGLEGUYLINES     = 3
  $triangle_guy : Mline[NUMTRIANGLEGUYLINES]
  NUMTHINTRIANGLEGUYLINES = 3
  $thintriangle_guy : Mline[NUMTHINTRIANGLEGUYLINES]

  $cheating : LibC::Int
  $grid : LibC::Int

  $leveljuststarted : LibC::Int # kluge until AM_LevelInit() is called

  $finit_width : LibC::Int
  $finit_height : LibC::Int

  # location of window on screen
  $f_x : LibC::Int
  $f_y : LibC::Int

  # size of window on screen
  $f_w : LibC::Int
  $f_h : LibC::Int

  $lightlev : LibC::Int # used for funky strobing effect
  $fb : Byte*           # psuedo-frame buffer
  $amclock : LibC::Int

  $m_paninc : Mpoint    # how far the window pans each tic (map coords)
  $mtof_zoommul : Fixed # how far the window zooms in each tic (map coords)
  $ftom_zoommul : Fixed #  how far the window zooms in each tic (fb coords)

  # LL x,y where the window is on the map (map coords)
  $m_x : Fixed
  $m_y : Fixed
  # UR x,y where the window is on the map (map coords)
  $m_x2 : Fixed
  $m_y2 : Fixed

  #
  # width/height of window on map (map coords)
  #
  $m_w : Fixed
  $m_h : Fixed

  # based on level size
  $min_x : Fixed
  $min_y : Fixed
  $max_x : Fixed
  $max_y : Fixed

  $max_w : Fixed # max_x-min_x,
  $max_h : Fixed # max_y-min_y

  # based on player size
  $min_w : Fixed
  $min_h : Fixed

  $min_scale_mtof : Fixed # used to tell when to stop zooming out
  $max_scale_mtof : Fixed # used to tell when to stop zooming in

  # old stuff for recovery later
  $old_m_w : Fixed
  $old_m_h : Fixed
  $old_m_x : Fixed
  $old_m_y : Fixed

  # old location used by the Follower routine
  $f_oldloc : Mpoint

  # used by MTOF to scale from map-to-frame-buffer coords
  $scale_mtof : Fixed
  # used by FTOM to scale from frame-buffer-to-map coords (=1/scale_mtof)
  $scale_ftom : Fixed

  $plr : Player* # the player represented by an arrow

  $marknums : Patch*[10]                 # numbers used for marking by the automap
  $markpoints : Mpoint[AM_NUMMARKPOINTS] # where the points are
  $markpointnum : LibC::Int              # next point to be assigned

  $followplayer : LibC::Int # specifies whether to follow the player around

  $cheat_amap_seq : LibC::Char[5]
  $cheat_amap : Cheatseq

  $stopped : DoomBool

  $automapactive : DoomBool

  $viewactive : DoomBool

  fun am_activate_new_scale = AM_activateNewScale

  fun am_save_scale_and_loc = AM_saveScaleAndLoc

  fun am_restore_scale_and_loc = AM_restoreScaleAndLoc

  fun am_add_mark = AM_addMark

  fun am_find_min_max_boundaries = AM_findMinMaxBoundaries

  fun am_change_window_loc = AM_changeWindowLoc

  fun am_init_variables = AM_initVariables

  fun am_load_pics = AM_loadPics

  fun am_unload_pics = AM_unloadPics

  fun am_clear_marks = AM_clearMarks

  fun am_level_init = AM_LevelInit

  fun am_stop = AM_Stop

  fun am_start = AM_Start

  fun am_min_out_window_scale = AM_minOutWindowScale

  fun am_max_out_window_scale = AM_maxOutWindowScale

  fun am_responder = AM_Responder(ev : Event*) : DoomBool

  fun am_change_window_scale = AM_changeWindowScale

  fun am_do_follow_player = AM_doFollowPlayer

  fun am_update_light_lev = AM_updateLightLev

  fun am_ticker = AM_Ticker

  fun am_clear_fb = AM_clearFB(color : LibC::Int)

  fun am_clip_mline = AM_clipMline(ml : Mline*, fl : Fline*) : DoomBool

  fun am_draw_fline = AM_drawFline(fl : Fline*, color : LibC::Int)

  fun am_draw_mline = AM_drawMline(ml : Mline*, color : LibC::Int)

  fun am_draw_grid = AM_drawGrid(color : LibC::Int)

  fun am_draw_walls = AM_drawWalls

  fun am_rotate = AM_rotate(x : Fixed*, y : Fixed*, a : Angle)

  fun am_draw_line_character = AM_drawLineCharacter(lineguy : Mline*,
                                                    lineguylines : LibC::Int,
                                                    scale : Fixed,
                                                    angle : Angle,
                                                    color : LibC::Int,
                                                    x : Fixed,
                                                    y : Fixed)

  fun am_draw_players = AM_drawPlayers

  fun am_draw_things = AM_drawThings(colors : LibC::Int, colorrange : LibC::Int)

  fun am_draw_marks = AM_drawMarks

  fun am_draw_crosshair = AM_drawCrosshair(color : LibC::Int)

  fun am_drawer = AM_Drawer

  $weaponinfo : Weaponinfo[Weapontype::NUMWEAPONS]

  MAXARGVS = 100

  $wadfiles : LibC::Char*[MAXWADFILES]

  $devparm : DoomBool     # started game with -devparm
  $nomonsters : DoomBool  # checkparm of -nomonsters
  $respawnparm : DoomBool # checkparm of -respawn
  $fastparm : DoomBool    # checkparm of -fast

  $drone : DoomBool

  $singletics : DoomBool # debug flag to cancel adaptiveness

  $is_wiping_screen : DoomBool

  $startskill : Skill
  $startepisode : LibC::Int
  $startmap : LibC::Int
  $autostart : DoomBool

  $debugfile : Void*

  $advancedemo : DoomBool

  $wadfile : LibC::Char[1024]     # primary wad file
  $mapdir : LibC::Char[1024]      # directory of development maps
  $basedefault : LibC::Char[1024] # default file

  #
  # EVENT HANDLING
  #
  # Events are asynchronous inputs generally generated by the game user.
  # Events can be discarded if no responder claims them
  #
  $events : Event[MAXEVENTS]
  $eventhead : LibC::Int
  $eventtail : LibC::Int

  # wipegamestate can be set to -1 to force a wipe on the next draw
  $wipegamestate : Gamestate
  fun r_execute_set_view_size = R_ExecuteSetViewSize

  # print title for every printed line
  $title : LibC::Char[128]

  $inhelpscreens : DoomBool
  $setsizeneeded : DoomBool
  $showmessages = showMessages : LibC::Int
  $demorecording : DoomBool

  fun d_doom_loop = D_DoomLoop
  fun d_check_net_game = D_CheckNetGame
  fun d_process_events = D_ProcessEvents
  fun g_build_ticcmd = G_BuildTiccmd(cmd : Ticcmd*)
  fun d_do_advance_demo = D_DoAdvanceDemo

  fun d_post_event = D_PostEvent(ev : Event*)

  fun d_process_events = D_ProcessEvents

  fun d_display = D_Display

  fun d_update_wipe = D_UpdateWipe

  fun d_doom_loop = D_DoomLoop

  #
  # DEMO LOOP
  #
  $demosequence : LibC::Int
  $pagetic : LibC::Int
  $pagename : LibC::Char*

  fun d_page_ticker = D_PageTicker

  fun d_page_drawer = D_PageDrawer

  fun d_advance_demo = D_AdvanceDemo

  fun d_do_advance_demo = D_DoAdvanceDemo

  fun d_start_title = D_StartTitle

  fun d_add_file = D_AddFile(file : LibC::Char*)

  fun identify_version = IdentifyVersion

  fun find_response_file = FindResponseFile

  fun d_doom_main = D_DoomMain

  NCMD_EXIT       = 0x80000000
  NCMD_RETRANSMIT = 0x40000000
  NCMD_SETUP      = 0x20000000
  NCMD_KILL       = 0x10000000 # kill game
  NCMD_CHECKSUM   = 0x0fffffff

  RESENDCOUNT =   10
  PL_DRONE    = 0x80 # bit flag in doomdata->player

  $doomcom : Doomcom*
  $netbuffer : Doomdata* # points inside doomcom

  $localcmds : Ticcmd[BACKUPTICS]

  $netcmds : Ticcmd[BACKUPTICS][MAXPLAYERS]
  $nettics : LibC::Int[MAXNETNODES]
  $nodeingame : DoomBool[MAXNETNODES]   # set false as nodes leave game
  $remoteresend : DoomBool[MAXNETNODES] # set when local needs tics
  $resendto : LibC::Int[MAXNETNODES]    # set when remote needs tics
  $resendcount : LibC::Int[MAXNETNODES]

  $nodeforplayer : LibC::Int[MAXPLAYERS]

  $maketic : LibC::Int
  $lastnettic : LibC::Int
  $skiptics : LibC::Int
  $ticdup : LibC::Int
  $maxsend : LibC::Int # BACKUPTICS//(2*ticdup)-1

  $reboundpacket : DoomBool
  $reboundstore : Doomdata

  $exitmsg : LibC::Char[80]
  $gametime : LibC::Int
  $frametics : LibC::Int[4]
  $frameon : LibC::Int
  $frameskip : LibC::Int[4]
  $oldnettics : LibC::Int

  $viewangleoffset : LibC::Int
  $advancedemo : DoomBool

  fun d_process_events = D_ProcessEvents
  fun g_build_ticcmd = G_BuildTiccmd(cmd : Ticcmd*)
  fun d_do_advance_demo = D_DoAdvanceDemo

  fun net_buffer_size = NetBufferSize : LibC::Int

  fun net_buffer_checksum = NetbufferChecksum : LibC::UInt

  fun expand_tics = ExpandTics(low : LibC::Int) : LibC::Int

  fun h_send_packet = HSendPacket(node : LibC::Int, flags : LibC::Int)

  fun h_get_packet = HGetPacket : DoomBool

  fun get_packets = GetPackets

  fun net_update = NetUpdate

  fun check_abort = CheckAbort

  fun d_arbitrate_net_start = D_ArbitrateNetStart

  fun d_check_net_game = D_CheckNetGame

  fun d_quit_net_game = D_QuitNetGame

  fun try_run_tics = TryRunTics

  $gamemode : GameMode
  $gamemission : GameMission

  $language : Language

  $modifiedgame : DoomBool

  TEXTSPEED =   3
  TEXTWAIT  = 250

  struct Castinfo
    name : LibC::Char*
    type : Mobjtype
  end

  $finalestage : LibC::Int

  $finalecount : LibC::Int

  $e1text : LibC::Char*
  $e2text : LibC::Char*
  $e3text : LibC::Char*
  $e4text : LibC::Char*

  $c1text : LibC::Char*
  $c2text : LibC::Char*
  $c3text : LibC::Char*
  $c4text : LibC::Char*
  $c5text : LibC::Char*
  $c6text : LibC::Char*

  $p1text : LibC::Char*
  $p2text : LibC::Char*
  $p3text : LibC::Char*
  $p4text : LibC::Char*
  $p5text : LibC::Char*
  $p6text : LibC::Char*

  $t1text : LibC::Char*
  $t2text : LibC::Char*
  $t3text : LibC::Char*
  $t4text : LibC::Char*
  $t5text : LibC::Char*
  $t6text : LibC::Char*

  $finaletext : LibC::Char*
  $finaleflat : LibC::Char*

  $castorder : Castinfo[18]

  $castnum : LibC::Int
  $casttics : LibC::Int
  $caststate : State*
  $castdeath : DoomBool
  $castframes : LibC::Int
  $castonmelee : LibC::Int
  $castattacking : DoomBool

  #
  # f_start_cast
  #
  $wipegamestate : Gamestate
  $hu_font : Patch*[HU_FONTSIZE]

  fun f_start_cast = F_StartCast
  fun f_cast_ticker = F_CastTicker
  fun f_cast_responder = F_CastResponder(ev : Event*) : DoomBool
  fun f_cast_drawer = F_CastDrawer
  fun v_draw_patch_flipped = V_DrawPatchFlipped(x : LibC::Int, y : LibC::Int, scrn : LibC::Int, patch : Patch*)

  fun f_start_finale = F_StartFinale

  fun f_responder = F_Responder(event : Event*) : DoomBool

  fun f_ticker = F_Ticker

  fun f_text_write = F_TextWrite

  fun f_start_cast = F_StartCast

  fun f_cast_ticker = F_CastTicker

  fun f_cast_responder = F_CastResponder(ev : Event*) : DoomBool

  fun f_cast_print = F_CastPrint(text : LibC::Char*)

  fun f_cast_drawer = F_CastDrawer

  fun f_draw_patch_col = F_DrawPatchCol(x : LibC::Int, patch : Patch*, col : LibC::Int)

  fun f_bunny_scroll = F_BunnyScroll

  fun f_drawer = F_Drawer

  $go : DoomBool

  $wipe_scr_start : Byte*
  $wipe_scr_end : Byte*
  $wipe_scr : Byte*

  $y : LibC::Int*

  fun wipe_shitty_col_major_x_form = wipe_shittyColMajorXform(array : LibC::Short*, width : LibC::Int, height : LibC::Int)

  fun wipe_init_color_x_form = wipe_initColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_do_color_x_form = wipe_doColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_exit_color_x_form = wipe_exitColorXForm(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_init_melt = wipe_initMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_do_melt = wipe_doMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_exit_melt = wipe_exitMelt(width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  fun wipe_start_screen = wipe_StartScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int

  fun wipe_end_screen = wipe_EndScreen(x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int) : LibC::Int

  fun wipe_screen_wipe = wipe_ScreenWipe(wipeno : LibC::Int, x : LibC::Int, y : LibC::Int, width : LibC::Int, height : LibC::Int, ticks : LibC::Int) : LibC::Int

  SAVEGAMESIZE   = 0x2c000
  SAVESTRINGSIZE =      24
  MAXPLMOVE      = CDoom.forwardmove[1]
  TURBOTHRESHOLD = 0x32
  SLOWTURNTICS   =    6
  NUMKEYS        =  256
  BODYQUESIZE    =   32
  VERSIONSIZE    =   16
  DEMOMARKER     = 0x80

  # Prototypes
  fun g_check_demo_status = G_CheckDemoStatus : DoomBool
  fun g_read_demo_ticcmd = G_ReadDemoTiccmd(cmd : Ticcmd*)
  fun g_write_demo_ticcmd = G_WriteDemoTiccmd(cmd : Ticcmd*)
  fun g_player_reborn = G_PlayerReborn(player : LibC::Int)
  fun g_init_new = G_InitNew(skill : Skill, episode : LibC::Int, map : LibC::Int)
  fun g_do_reborn = G_DoReborn(playernum : LibC::Int)
  fun g_do_load_level = G_DoLoadLevel
  fun g_do_new_game = G_DoNewGame
  fun g_do_load_game = G_DoLoadGame
  fun g_do_play_demo = G_DoPlayDemo
  fun g_do_completed = G_DoCompleted
  fun g_do_world_done = G_DoWorldDone
  fun g_do_save_game = G_DoSaveGame
  fun p_spawn_player = P_SpawnPlayer(mthing : Mapthing*)
  fun r_execute_set_view_size = R_ExecuteSetViewSize

  $gameaction : Gameaction
  $gamestate : Gamestate
  $gameskill : Skill
  $respawnmonsters : DoomBool
  $gameepisode : LibC::Int
  $gamemap : LibC::Int

  $paused : DoomBool
  $sendpause : DoomBool # send a pause event next tic
  $sendsave : DoomBool  # send a save event next tic
  $usergame : DoomBool  # ok to save / end game

  $timingdemo : DoomBool # if true, exit with report on completion
  $nodrawers : DoomBool  # for comparative timing purposes
  $noblit : DoomBool     # for comparative timing purposes
  $starttime : LibC::Int # for comparative timing purposes

  $viewactive : DoomBool

  $deathmatch : DoomBool # only if started as net death

  $demoname : LibC::Char[32]
  $netdemo : DoomBool
  $demobuffer : Byte*
  $demo_p : Byte*
  $demoend : Byte*

  $consistancy : LibC::Short[BACKUPTICS][MAXPLAYERS]

  $savebuffer : Byte*

  #
  # controls (have defaults)
  #
  $key_right : LibC::Int
  $key_left : LibC::Int

  $key_up : LibC::Int
  $key_down : LibC::Int
  $key_strafeleft : LibC::Int
  $key_straferight : LibC::Int
  $key_fire : LibC::Int
  $key_use : LibC::Int
  $key_strafe : LibC::Int
  $key_speed : LibC::Int

  $mousebfire : LibC::Int
  $mousebstrafe : LibC::Int
  $mousebforward : LibC::Int
  $mousemove : LibC::Int

  $joybfire : LibC::Int
  $joybstrafe : LibC::Int
  $joybuse : LibC::Int
  $joybspeed : LibC::Int

  $forwardmove : Fixed[2]
  $sidemove : Fixed[2]
  $angleturn : Fixed[3] # + slow turn

  $gamekeydown : DoomBool[NUMKEYS]
  $turnheld : LibC::Int # for accelerative turning

  $mousearray : DoomBool[4]
  $mousebuttons : DoomBool* # allow [-1]

  $dclicktime : LibC::Int
  $dclickstate : LibC::Int
  $dclicks : LibC::Int
  $dclicktime2 : LibC::Int
  $dclickstate2 : LibC::Int
  $dclicks2 : LibC::Int

  # joystick values are repeated
  $joyxmove : LibC::Int
  $joyymove : LibC::Int
  $joyarray : DoomBool[5]
  $joybuttons : DoomBool* # allow [-1]

  $savegameslot : LibC::Int
  $savedescription : LibC::Char[32]

  $bodyque : Mobj*[BODYQUESIZE]

  $statcopy : Void* # for statistics driver

  # DOOM Par Times
  $pars : LibC::Int[10][4]

  $cpars : LibC::Int[32]

  $secretexit : DoomBool

  $savename : LibC::Char[256]

  $d_skill : Skill
  $d_episode : LibC::Int
  $d_map : LibC::Int

  $defdemoname : LibC::Char*

  fun g_build_ticcmd = G_BuildTiccmd(cmd : Ticcmd*)

  fun g_init_player = G_InitPlayer(player : LibC::Int)

  fun g_player_finish_level = G_PlayerFinishLevel(player : LibC::Int)

  fun g_player_reborn = G_PlayerReborn(player : LibC::Int)

  fun g_check_spot = G_CheckSpot(playernum : LibC::Int, mthing : Mapthing*) : DoomBool

  fun g_deathmatch_spawn_player = G_DeathMatchSpawnPlayer(playernum : LibC::Int)

  NOTERASED = CDoom.viewwindowx

  HU_TITLEHEIGHT = 1
  HU_INPUTTOGGLE = 't'.ord
  HU_INPUTWIDTH  =  64
  HU_INPUTHEIGHT =   1
  QUEUESIZE      = 128

  $w_title : HU_Textline
  $w_chat : HU_Itext
  $always_off : DoomBool
  $chat_dest : LibC::Char[MAXPLAYERS]
  $w_inputbuffer : HU_Itext[MAXPLAYERS]
  $message_on : DoomBool
  $message_nottobefuckedwith : DoomBool
  $w_message : HU_Stext
  $message_counter : LibC::Int
  $headsupactive : DoomBool
  $chatchars : LibC::Char[QUEUESIZE]
  $head : LibC::Int
  $tail : LibC::Int

  $chat_macros : LibC::Char*[10]

  $player_names : LibC::Char*[4]

  $shiftxform : LibC::Char*

  $french_shiftxform : LibC::Char[128]

  $english_shiftxform : LibC::Char[128]

  $french_key_map = frenchKeyMap : LibC::Char[128]

  $chat_char : LibC::Char # remove later.
  $chat_on : DoomBool
  $message_dontfuckwithme : DoomBool

  $show_messages = showMessages : LibC::Int

  # DOOM shareware/registered/retail (Ultimate) names.
  $mapnames : LibC::Char*[45]

  # DOOM 2 map names.
  $mapnames2 : LibC::Char*[32]

  $mapnamesp : LibC::Char*[32]

  $mapnamest : LibC::Char*[32]

  fun foreign_translation = ForeignTranslation(ch : LibC::Char) : LibC::Char

  fun hu_stop = HU_Stop

  fun hu_queue_chat_char = HU_queueChatChar(c : LibC::Char)

  IPPORT_USERRESERVED = 5000

  SAMPLECOUNT  = 512
  NUM_CHANNELS =   8
  # It is 2 for 16bit, and 2 for two channels.
  BUFMUL        = 4
  MIXBUFFERSIZE = SAMPLECOUNT * BUFMUL

  SAMPLERATE = 11025 # Hz
  SAMPLESIZE =     2 # 16bit

  MAX_QUEUED_MIDI_MSGS = 256

  EVENT_RELEASE_NOTE   = 0
  EVENT_PLAY_NOTE      = 1
  EVENT_PITCH_BEND     = 2
  EVENT_SYSTEM_EVENT   = 3
  EVENT_CONTROLLER     = 4
  EVENT_END_OF_MEASURE = 5
  EVENT_FINISH         = 6
  EVENT_UNUSED         = 7

  CONTROLLER_EVENT_ALL_SOUNDS_OFF        = 10
  CONTROLLER_EVENT_ALL_NOTES_OFF         = 11
  CONTROLLER_EVENT_MONO                  = 12
  CONTROLLER_EVENT_POLY                  = 13
  CONTROLLER_EVENT_RESET_ALL_CONTROLLERS = 14
  CONTROLLER_EVENT_EVENT                 = 15

  CONTROLLER_CHANGE_INSTRUMENT = 0
  CONTROLLER_BANK_SELECT       = 1
  CONTROLLER_MODULATION        = 2
  CONTROLLER_VOLUME            = 3
  CONTROLLER_PAN               = 4
  CONTROLLER_EXPRESSION        = 5
  CONTROLLER_REVERB            = 6
  CONTROLLER_CHORUS            = 7
  CONTROLLER_SUSTAIN           = 8
  CONTROLLER_SOFT              = 9

  struct MusHeader
    id : LibC::Char[4]
    score_len : LibC::UShort
    score_start : LibC::UShort
    channels : LibC::UShort
    sec_channels : LibC::UShort
    instr_cnt : LibC::UShort
    dummy : LibC::UShort
  end

  # A quick hack to establish a protocol between
  # synchronous mix buffer updates and asynchronous
  # audio writes. Probably redundant with gametic.
  $flag : LibC::Int

  $mus_data : LibC::Char*
  $mus_header : MusHeader
  $mus_offset : LibC::Int
  $mus_delay : LibC::Int
  $mus_loop : DoomBool
  $mus_playing : DoomBool
  $mus_volume : LibC::Int
  $mus_channel_volumes : LibC::Int[16]

  $looping : LibC::Int
  $musicdies : LibC::Int

  # The number of internal mixing channels,
  #  the samples calculated for each mixing step,
  #  the size of the 16bit, 2 hardware channel (stereo)
  #  mixing buffer, and the samplerate of the raw data.

  # The actual lengths of all sound effects.
  $lengths : LibC::Int[Sfxenum::NUMSFX]

  # The global mixing buffer.
  # Basically, samples from all active internal channels
  #  are modifed and added, and stored in the buffer
  #  that is submitted to the audio device.
  $mixbuffer : LibC::Short[MIXBUFFERSIZE]

  # The channel step amount...
  $channelstep : LibC::UInt[NUM_CHANNELS]
  # ... and a 0.16 bit remainder of last step.
  $channelstepremainder : LibC::UInt[NUM_CHANNELS]

  # The channel data pointers, start and end.
  $channels : LibC::Char*[NUM_CHANNELS]
  $channelsend : LibC::Char*[NUM_CHANNELS]

  # Time/gametic that the channel started playing,
  #  used to determine oldest, which automatically
  #  has lowest priority.
  # In case number of active sounds exceeds
  #  available channels.
  $channelstart : LibC::Int[NUM_CHANNELS]

  # The sound in channel handles,
  #  determined on registration,
  #  might be used to unregister/stop/modify,
  #  currently unused.
  $channelhandles : LibC::Int[NUM_CHANNELS]

  # SFX id of the playing sound effect.
  # Used to catch duplicates (like chainsaw).
  $channelids : LibC::Int[NUM_CHANNELS]

  # Pitch to stepping lookup, unused.
  $steptable : LibC::Int[256]

  # Volume lookups.
  $vol_lookup : LibC::Int[32768]

  # Hardware left and right channel volume lookup.
  $channelleftvol_lookup : LibC::Int*[NUM_CHANNELS]
  $channelrightvol_lookup : LibC::Int*[NUM_CHANNELS]

  $queued_midi_msgs : LibC::ULong[MAX_QUEUED_MIDI_MSGS]
  $queue_midi_head : LibC::Int
  $queue_midi_tail : LibC::Int

  fun tick_song = TickSong

  fun getsfx(sfxname : LibC::Char*, len : LibC::Int*) : Void*
  fun addsfx(sfxid : LibC::Int, volume : LibC::Int, step : LibC::Int, seperation : LibC::Int) : LibC::Int

  fun i_set_sfx_volume = I_SetSfxVolume(volume : LibC::Int)
  fun i_set_music_volume = I_SetMusicVolume(volume : LibC::Int)

  fun reset_all_channels

  fun i_qry_song_playing = I_QrySongPlaying(handle : LibC::Int) : LibC::Int

  $mb_used : LibC::Int
  $emptycmd : Ticcmd

  fun i_get_heap_size = I_GetHeapSize : LibC::Int

  SPRNAMES_SIZE = Spritenum::NUMSPRITES + 1
  $sprnames : LibC::Char**

  fun a_light0 = A_Light0(Void*)
  fun a_weapon_ready = A_WeaponReady(Void*)
  fun a_lower = A_Lower(Void*)
  fun a_raise = A_Raise(Void*)
  fun a_punch = A_Punch(Void*)
  fun a_refire = A_ReFire(player : Player*, psp : Pspdef*)
  fun a_fire_pistol = A_FirePistol(Void*)
  fun a_light1 = A_Light1(Void*)
  fun a_fire_shotgun = A_FireShotgun(Void*)
  fun a_light2 = A_Light2(Void*)
  fun a_fire_shotgun2 = A_FireShotgun2(Void*)
  fun a_check_reload = A_CheckReload(Void*)
  fun a_open_shotgun2 = A_OpenShotgun2(player : Player*, psp : Pspdef*)
  fun a_load_shotgun2 = A_LoadShotgun2(player : Player*, psp : Pspdef*)
  fun a_close_shotgun2 = A_CloseShotgun2(player : Player*, psp : Pspdef*)
  fun a_fire_cgun = A_FireCGun(Void*)
  fun a_gun_flash = A_GunFlash(Void*)
  fun a_fire_missile = A_FireMissile(Void*)
  fun a_saw = A_Saw(Void*)
  fun a_fire_plasma = A_FirePlasma(Void*)
  fun a_bfg_sound = A_BFGsound(Void*)
  fun a_fire_bfg = A_FireBFG(Void*)
  fun a_bfg_spray = A_BFGSpray(Void*)
  fun a_explode = A_Explode(thingy : Mobj*)
  fun a_pain = A_Pain(actor : Mobj*)
  fun a_player_scream = A_PlayerScream(mo : Mobj*)
  fun a_fall = A_Fall(actor : Mobj*)
  fun a_xscream = A_XScream(actor : Mobj*)
  fun a_look = A_Look(actor : Mobj*)
  fun a_chase = A_Chase(actor : Mobj*)
  fun a_face_target = A_FaceTarget(actor : Mobj*)
  fun a_pos_attack = A_PosAttack(actor : Mobj*)
  fun a_scream = A_Scream(actor : Mobj*)
  fun a_spos_attack = A_SPosAttack(actor : Mobj*)
  fun a_vile_chase = A_VileChase(actor : Mobj*)
  fun a_vile_start = A_VileStart(actor : Mobj*)
  fun a_vile_target = A_VileTarget(actor : Mobj*)
  fun a_vile_attack = A_VileAttack(actor : Mobj*)
  fun a_start_fire = A_StartFire(actor : Mobj*)
  fun a_fire = A_Fire(actor : Mobj*)
  fun a_fire_crackle = A_FireCrackle(actor : Mobj*)
  fun a_tracer = A_Tracer(actor : Mobj*)
  fun a_skel_whoosh = A_SkelWhoosh(actor : Mobj*)
  fun a_skel_fist = A_SkelFist(actor : Mobj*)
  fun a_skel_missile = A_SkelMissile(actor : Mobj*)
  fun a_fat_raise = A_FatRaise(actor : Mobj*)
  fun a_fat_attack1 = A_FatAttack1(actor : Mobj*)
  fun a_fat_attack2 = A_FatAttack2(actor : Mobj*)
  fun a_fat_attack3 = A_FatAttack3(actor : Mobj*)
  fun a_boss_death = A_BossDeath(mo : Mobj*)
  fun a_cpos_attack = A_CPosAttack(actor : Mobj*)
  fun a_cpos_refire = A_CPosRefire(actor : Mobj*)
  fun a_troop_attack = A_TroopAttack(actor : Mobj*)
  fun a_sarg_attack = A_SargAttack(actor : Mobj*)
  fun a_head_attack = A_HeadAttack(actor : Mobj*)
  fun a_bruis_attack = A_BruisAttack(actor : Mobj*)
  fun a_skull_attack = A_SkullAttack(actor : Mobj*)
  fun a_metal = A_Metal(mo : Mobj*)
  fun a_spid_refire = A_SpidRefire(actor : Mobj*)
  fun a_baby_metal = A_BabyMetal(mo : Mobj*)
  fun a_bspi_attack = A_BspiAttack(actor : Mobj*)
  fun a_hoof = A_Hoof(mo : Mobj*)
  fun a_cyber_attack = A_CyberAttack(actor : Mobj*)
  fun a_pain_attack = A_PainAttack(actor : Mobj*)
  fun a_pain_die = A_PainDie(actor : Mobj*)
  fun a_keen_die = A_KeenDie(mo : Mobj*)
  fun a_brain_pain = A_BrainPain(mo : Mobj*)
  fun a_brain_scream = A_BrainScream(mo : Mobj*)
  fun a_brain_die = A_BrainDie(Void*)
  fun a_brain_awake = A_BrainAwake(mo : Mobj*)
  fun a_brain_spit = A_BrainSpit(mo : Mobj*)
  fun a_spawn_sound = A_SpawnSound(mo : Mobj*)
  fun a_spawn_fly = A_SpawnFly(mo : Mobj*)
  fun a_brain_explode = A_BrainExplode(mo : Mobj*)

  SKULLXOFF  = -32
  LINEHEIGHT =  16

  #
  # MENU TYPEDEFS
  #
  struct Menuitem
    # 0 = no cursor here, 1 = ok, 2 = arrows ok
    status : LibC::Short

    name : LibC::Char*

    # choice = menu item #.
    # if status = 2,
    #   choice=0:leftarrow,1:rightarrow
    routine : Proc(LibC::Int, Nil)

    # hotkey in menu
    alpha_key : LibC::Char
  end

  struct Menu
    numitems : LibC::Short # # of menu items
    prev_menu : Menu*      # previous menu
    menuitems : Menuitem*  # menu items
    routine : Proc(Nil)    # draw routine
    x : LibC::Short
    y : LibC::Short       # x,y of menu
    last_on : LibC::Short # last item user was on in menu
  end

  struct MenuCustomTextSeg
    lump : LibC::Char*
    x : LibC::Int
    w : LibC::Int
    offx : LibC::Int
    offy : LibC::Int
  end

  struct MenuCustomText
    name : LibC::Char*
    segs : MenuCustomTextSeg[16]
  end

  # Blocky mode, has default, 0 = high, 1 = normal
  $detail_level = detailLevel : LibC::Int
  $screenblocks : LibC::Int # has default

  # temp for screenblocks (0-9)
  $screen_size = screenSize : LibC::Int

  # -1 = no quicksave slot picked!
  $quick_save_slot = quickSaveSlot : LibC::Int

  # 1 = message to be printed
  $message_to_print = messageToPrint : LibC::Int
  # ...and here is the message string!
  $message_string = messageString : LibC::Char*

  # message x & y
  $messx : LibC::Int
  $messy : LibC::Int
  $message_last_menu_active = messageLastMenuActive : LibC::Int

  # timed message = no input from user
  $message_needs_input = messageNeedsInput : DoomBool

  $message_routine = messageRoutine : Proc(LibC::Int, Nil)

  $gammamsg : LibC::Char*[5]

  # we are going to be entering a savegame string
  $save_string_enter = saveStringEnter : LibC::Int
  $save_slot = saveSlot : LibC::Int            # which slot to save in
  $save_char_index = saveCharIndex : LibC::Int # which char we're editing
  # old save description before edit
  $save_old_string = saveOldString : LibC::Char[SAVESTRINGSIZE]

  $savegamestrings : LibC::Char[SAVESTRINGSIZE][10]

  $endstring : LibC::Char[160]

  $item_on = itemOn : LibC::Short                      # menu item skull is on
  $skull_anim_counter = skullAnimCounter : LibC::Short # skull animation counter
  $which_skull = whichSkull : LibC::Short              # which skull to draw

  # graphic name of skulls
  # warning: initializer-string for array of chars is too long
  $skull_name = skullName : LibC::Char*[2]

  # current menudef
  $current_menu = currentMenu : Menu*

  # We create new menu text by cutting into existing graphics and pasting them to create the new text.
  # This way we don't ship code with embeded graphics that come from WAD files.
  $menu_custom_texts : MenuCustomText[4]

  $custom_texts_count : LibC::Int

  $tempstring : LibC::Char[80]
  $epi : LibC::Int
  $detail_names = detailNames : LibC::Char*[2]
  $msg_names = msgNames : LibC::Char*[2]

  $quitsounds : LibC::Int[8]

  $quitsounds2 : LibC::Int[8]

  fun m_new_game = M_NewGame(choice : LibC::Int)
  fun m_episode = M_Episode(choice : LibC::Int)
  fun m_choose_skill = M_ChooseSkill(choice : LibC::Int)
  fun m_load_game = M_LoadGame(choice : LibC::Int)
  fun m_save_game = M_SaveGame(choice : LibC::Int)
  fun m_options = M_Options(choice : LibC::Int)
  fun m_endgame = M_EndGame(choice : LibC::Int)
  fun m_readthis = M_ReadThis(choice : LibC::Int)
  fun m_readthis2 = M_ReadThis2(choice : LibC::Int)
  fun m_quitdoom = M_QuitDOOM(choice : LibC::Int)

  fun m_change_messages = M_ChangeMessages(choice : LibC::Int)
  fun m_sfxvol = M_SfxVol(choice : LibC::Int)
  fun m_musicvol = M_MusicVol(choice : LibC::Int)
  fun m_mouse_options = M_MouseOptions(choice : LibC::Int)
  fun m_size_display = M_SizeDisplay(choice : LibC::Int)
  fun m_startgame = M_StartGame(choice : LibC::Int)
  fun m_sound = M_Sound(choice : LibC::Int)
  fun m_change_crosshair = M_ChangeCrosshair(choice : LibC::Int)
  fun m_change_alwaysrun = M_ChangeAlwaysRun(choice : LibC::Int)

  fun m_mouse_move = M_MouseMove(choice : LibC::Int)
  fun m_change_sensitivity = M_ChangeSensitivity(choice : LibC::Int)

  fun m_finish_readthis = M_FinishReadThis(choice : LibC::Int)
  fun m_load_select = M_LoadSelect(choice : LibC::Int)
  fun m_save_select = M_SaveSelect(choice : LibC::Int)
  fun m_read_save_strings = M_ReadSaveStrings
  fun m_quicksave = M_QuickSave
  fun m_quickload = M_QuickLoad

  fun m_draw_mainmenu = M_DrawMainMenu
  fun m_draw_readthis1 = M_DrawReadThis1
  fun m_draw_readthis2 = M_DrawReadThis2
  fun m_draw_newgame = M_DrawNewGame
  fun m_draw_episode = M_DrawEpisode
  fun m_draw_options = M_DrawOptions
  fun m_draw_sound = M_DrawSound
  fun m_draw_load = M_DrawLoad
  fun m_draw_save = M_DrawSave

  fun m_draw_save_load_border = M_DrawSaveLoadBorder(x : LibC::Int, y : LibC::Int)
  fun m_setup_next_menu = M_SetupNextMenu(menudef : Menu*)
  fun m_draw_thermo = M_DrawThermo(x : LibC::Int, y : LibC::Int, therm_width : LibC::Int, therm_dot : LibC::Int)
  fun m_draw_empty_cell = M_DrawEmptyCell(menu : Menu*, item : LibC::Int)
  fun m_draw_selcell = M_DrawSelCell(menu : Menu*, item : LibC::Int)
  fun m_write_text = M_WriteText(x : LibC::Int, y : LibC::Int, string : LibC::Char*)
  fun m_string_width = M_StringWidth(string : LibC::Char*) : LibC::Int
  fun m_string_height = M_StringHeight(string : LibC::Char*) : LibC::Int
  fun m_start_control_panel = M_StartControlPanel
  fun m_start_message = M_StartMessage(string : LibC::Char*, routine : Proc(Int32, Nil), input : DoomBool)
  fun m_stop_message = M_StopMessage
  fun m_clear_menus = M_ClearMenus
  fun m_draw_mouse_options = M_DrawMouseOptions

  #
  # DOOM MENU
  #
  enum Mainenum
    Newgame
    Options
    Loadgame
    Savegame
    Readthis
    Quitdoom
    MainEnd
  end

  $mainmenu = MainMenu : Menuitem[6]

  $maindef = MainDef : Menu

  #
  # EPISODE SELECT
  #
  enum Episodesenum
    Ep1
    Ep2
    Ep3
    Ep4
    EpEnd
  end

  $episodemenu = EpisodeMenu : Menuitem[4]

  $epidef = EpiDef : Menu

  #
  # NEW GAME
  #
  enum NewgameEnum
    Killthings
    Toorough
    Hurtme
    Violence
    Nightmare
    NewgEnd
  end

  $newgame_menu = NewGameMenu : Menuitem[5]

  $newdef = NewDef : Menu

  #
  # OPTIONS MENU
  #
  enum OptionsEnum
    Endgame
    Messages
    Crosshairopt
    Alwaysrunopt
    # Detail, # Details do nothing?
    Scrnsize
    Optionempty1
    Mouseoptions
    Soundvol
    OptEnd
  end

  $options_menu = OptionsMenuFull : Menuitem[8]

  $optionsdef = OptionsDef : Menu

  #
  # MOUSE OPTIONS
  #
  enum MouseoptionsEnum
    Mousemov
    Mousesens
    Mouseoptionempty1
    MouseOptEnd
  end

  $mouse_options_menu = MouseOptionsMenu : Menuitem[3]

  $mouseoptionsdef = MouseOptionsDef : Menu

  #
  # Read This! MENU 1 & 2
  #
  enum Readenum
    Rdthsempty1
    Read1End
  end

  $readmenu1 = ReadMenu1 : Menuitem[1]

  $readdef1 = ReadDef1 : Menu

  enum Read2enum
    Rdthsempty2
    Read2End
  end

  $readmenu2 = ReadMenu2 : Menuitem[1]

  $readdef2 = ReadDef2 : Menu

  #
  # SOUND VOLUME MENU
  #
  enum Soundenum
    Sfxvol
    Sfxempty1
    Musicvol
    Sfxempty2
    SoundEnd
  end

  $soundmenu = SoundMenuFull : Menuitem[4]

  $sounddef = SoundDef : Menu

  #
  # LOAD GAME MENU
  #
  enum Loadenum
    Load1
    Load2
    Load3
    Load4
    Load5
    Load6
    LoadEnd
  end

  $loadmenu = DOOM_LoadMenu : Menuitem[6]

  $loaddef = LoadDef : Menu

  #
  # SAVE GAME MENU
  #
  $savemenu = SaveMenu : Menuitem[6]

  $savedef = SaveDef : Menu

  fun m_draw_custom_menu_text = M_DrawCustomMenuText(name : LibC::Char*, x : LibC::Int, y : LibC::Int)

  fun m_do_save = M_DoSave(slot : LibC::Int)

  fun m_quicksave_response = M_QuickSaveResponse(ch : LibC::Int)

  fun m_quickload_response = M_QuickLoadResponse(ch : LibC::Int)

  fun m_verify_nightmare = M_VerifyNightmare(ch : LibC::Int)

  fun m_endgame_response = M_EndGameResponse(ch : LibC::Int)

  fun m_quit_response = M_QuitResponse(ch : LibC::Int)

  fun m_responder = M_Responder(ev : Event*) : DoomBool

  STRING_VALUE = 0xffff

  #
  # SCREEN SHOTS
  #
  struct PCX
    manufacturer : LibC::Char
    version : LibC::Char
    encoding : LibC::Char
    bits_per_pixel : LibC::Char

    xmin : LibC::UShort
    ymin : LibC::UShort
    xmax : LibC::UShort
    ymax : LibC::UShort

    hres : LibC::UShort
    vres : LibC::UShort

    palette : LibC::Char[48]

    reserved : LibC::Char
    color_planes : LibC::Char
    bytes_per_line : LibC::UShort
    palette_type : LibC::UShort

    filler : LibC::Char[58]
    data : LibC::Char # unbounded
  end

  $num_channels = numChannels : LibC::Int
  $scantokey : Byte[128]

  $numdefaults : LibC::Int
  $defaultfile : LibC::Char*

  fun write_pcx_file = WritePCXfile(filename : LibC::Char*, data : Byte*, width : LibC::Int, height : LibC::Int, palette : Byte*)

  $rndtable : LibC::Char[256]

  $rndindex : LibC::Int
  $prndindex : LibC::Int

  fun p_random = P_Random : LibC::Int

  MAXSPECIALCROSS = 8
  FATSPREAD       = ANG90 // 8
  SKULLSPEED      = 20*FRACUNIT

  enum Dirtype
    East
    NorthEast
    North
    NorthWest
    West
    SouthWest
    South
    SouthEast
    NoDir
    NUMDIRS
  end

  $opposite : Dirtype[9]
  $diags : Dirtype[4]

  $soundtarget : Mobj*
  $xspeed : Fixed[8]
  $yspeed : Fixed[8]
  $traceangle = TRACEANGLE : LibC::Int
  $corpsehit : Mobj*
  $vileobj : Mobj*
  $viletryx : Fixed
  $viletryy : Fixed
  $braintargets : Mobj*[32]
  $numbraintargets : LibC::Int
  $braintargeton : LibC::Int

  # keep track of special lines as they are hit,
  # but don't process them until the move is proven valid
  $spechit : Line*[MAXSPECIALCROSS]
  $numspechit : LibC::Int

  fun p_recursive_sound = P_RecursiveSound(sec : Sector*, soundblocks : LibC::Int)

  fun p_check_melee_range = P_CheckMeleeRange(actor : Mobj*) : DoomBool

  fun p_check_missile_range = P_CheckMissileRange(actor : Mobj*) : DoomBool

  fun p_move = P_Move(actor : Mobj*) : DoomBool

  fun p_try_walk = P_TryWalk(actor : Mobj*) : DoomBool

  fun p_new_chase_dir = P_NewChaseDir(actor : Mobj*)

  fun p_look_for_players = P_LookForPlayers(actor : Mobj*, allaround : DoomBool) : DoomBool

  fun pit_vile_check = PIT_VileCheck(thing : Mobj*) : DoomBool

  fun a_pain_shoot_skull = A_PainShootSkull(actor : Mobj*, angle : Angle)

  BONUSADD = 6

  fun p_give_ammo = P_GiveAmmo(player : Player*, ammo : Ammotype, num : LibC::Int) : DoomBool
  fun p_give_weapon = P_GiveWeapon(player : Player*, weapon : Weapontype, dropped : DoomBool) : DoomBool
  fun p_give_body = P_GiveBody(player : Player*, num : LibC::Int) : DoomBool
  fun p_give_armor = P_GiveArmor(player : Player*, armortype : LibC::Int) : DoomBool
  fun p_give_card = P_GiveCard(player : Player*, card : Card)

  fun p_kill_mobj = P_KillMobj(source : Mobj*, target : Mobj*)

  fun t_fire_flicker = T_FireFlicker(flick : Fireflicker*)

  $tmbbox : Fixed[4]
  $tmthing : Mobj*
  $tmflags : LibC::Int
  $tmx : Fixed
  $tmy : Fixed
  $tmdropoffz : Fixed

  # Height if not aiming up or down
  # ???: use slope for monsters?
  $shootz : Fixed

  $la_damage : LibC::Int
  $attackrange : Fixed

  $aimslope : Fixed
  $usething : Mobj*
  $crushchange : DoomBool
  $nofit : DoomBool

  # slopes to top and bottom of target
  $topslope : Fixed
  $bottomslope : Fixed

  fun pit_stomp_thing = PIT_StompThing(thing : Mobj*) : DoomBool
  fun pit_check_line = PIT_CheckLine(ld : Line*) : DoomBool

  fun pit_check_thing = PIT_CheckThing(thing : Mobj*) : DoomBool
  fun p_thing_height_clip = P_ThingHeightClip(thing : Mobj*) : DoomBool

  $bestslidefrac : Fixed
  $secondslidefrac : Fixed

  $bestslideline : Line*
  $secondslideline : Line*

  $slidemo : Mobj*

  $tmxmove : Fixed
  $tmymove : Fixed

  fun p_hit_slide_line = P_HitSlideLine(ld : Line*)
  fun ptr_slide_traverse = PTR_SlideTraverse(int : Intercept*) : DoomBool
  fun ptr_aim_traverse = PTR_AimTraverse(int : Intercept*) : DoomBool
  fun ptr_shoot_traverse = PTR_ShootTraverse(int : Intercept*) : DoomBool
  fun ptr_use_traverse = PTR_UseTraverse(int : Intercept*) : DoomBool

  $bombsource : Mobj*
  $bombspot : Mobj*
  $bombdamage : LibC::Int
  fun pit_radius_attack = PIT_RadiusAttack(thing : Mobj*) : DoomBool
  fun pit_change_sector = PIT_ChangeSector(thing : Mobj*) : DoomBool

  $earlyout : DoomBool
  $ptflags : LibC::Int

  fun pit_add_line_intercepts = PIT_AddLineIntercepts(ld : Line*) : DoomBool
  fun pit_add_thing_intercepts = PIT_AddThingIntercepts(thing : Mobj*) : DoomBool
  fun p_traverse_intercepts = P_TraverseIntercepts(func : Traverser, maxfrac : Fixed) : DoomBool

    STOPSPEED = 0x1000
    FRICTION = 0xe800

    fun p_explode_missile = P_ExplodeMissile(mo : Mobj*)

      fun p_xymovement = P_XYMovement(mo : Mobj*)
        fun p_zmovement = P_ZMovement(mo : Mobj*)

          fun p_nightmare_respawn = P_NightmareRespawn(mobj : Mobj*)


end
