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
{% if @top_level.has_constant?("FAST_TICK") %}
  TICKMUL = 2
{% else %}
  TICKMUL = 1
{% end %}
TICRATE = 35 * TICKMUL

# The current state of the game: whether we are
# playing, gazing at the intermission screen,
# the game final animation, or a demo.
enum Gamestate
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

# Deaf monsters/do not react to sound
MTF_AMBUSH = 8

enum Skill
  Baby
  Easy
  Medium
  Hard
  Nightmare
end

#
# Key cards.
#
enum Card
  Bluecard
  Yellowcard
  Redcard
  Blueskull
  Yellowskull
  Redskull
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
  Num
  Nochange
end
NUMWEAPONS = Weapontype::Num.value

# Ammunition types defined.
enum Ammotype
  Clip  # Pistol / chaingun ammo.
  Shell # Shotgun / double barreled shotgun.
  Cell  # Plasma rifle, BFG.
  Misl  # Missile launcher.
  Num
  Noammo # Unlimited for chainsaw / fist.
end
NUMAMMO = Ammotype::Num.value

# Power up artifacts.
enum Powertype
  Invulnerability
  Strength
  Invisibility
  Ironfeet
  Allmap
  Infrared
  Num
end
NUMPOWERS = Powertype::Num.value

#
# Power up durations,
#  how many seconds till expiration,
#  assuming TICRATE is 35 ticks/second.
#
INVULNTICS = 30 * TICRATE
INVISTICS  = 60 * TICRATE
INFRATICS  = 120 * TICRATE
IRONTICS   = 60 * TICRATE

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
