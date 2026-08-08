require "./lib-cr/**"

# Sample rate of sound samples from doom
DOOM_SAMPLERATE = 11025

# MIDI tick needs to be called 140 times per seconds
DOOM_MIDI_RATE = 140

enum Seek
  Cur = 1
  End = 2
  Set = 0
end

enum Key
  Unknown      =   -1
  Tab          =    9
  Enter        =   13
  Escape       =   27
  Space        =   32
  Apostrophe   =   39
  KpMultiply   =   42
  Comma        =   44
  Minus        = 0x2d
  Period       =   46
  Slash        =   47
  Zero         =   48
  One          =   49
  Two          =   50
  Three        =   51
  Four         =   52
  Five         =   53
  Six          =   54
  Seven        =   55
  Eight        =   56
  Nine         =   57
  Semicolon    =   59
  Equal        = 0x3d
  LeftBracket  =   91
  RightBracket =   93
  A            =   97
  B            =   98
  C            =   99
  D            =  100
  E            =  101
  F            =  102
  G            =  103
  H            =  104
  I            =  105
  J            =  106
  K            =  107
  L            =  108
  M            =  109
  N            =  110
  O            =  111
  P            =  112
  Q            =  113
  R            =  114
  S            =  115
  T            =  116
  U            =  117
  V            =  118
  W            =  119
  X            =  120
  Y            =  121
  Z            =  122
  Backspace    =  127
  LeftControl  = (0x80 + 0x1d) # Both left and right
  RightControl = (0x80 + 0x1d) # Both left and right
  Left         = 0xac
  Up           = 0xad
  Right        = 0xae
  Down         = 0xaf
  LeftShift    = (0x80 + 0x36) # Both left and right
  RightShift   = (0x80 + 0x36) # Both left and right
  LeftAlt      = (0x80 + 0x38) # Both left and right
  RightAlt     = (0x80 + 0x38) # Both left and right
  F1           = (0x80 + 0x3b)
  F2           = (0x80 + 0x3c)
  F3           = (0x80 + 0x3d)
  F4           = (0x80 + 0x3e)
  F5           = (0x80 + 0x3f)
  F6           = (0x80 + 0x40)
  F7           = (0x80 + 0x41)
  F8           = (0x80 + 0x42)
  F9           = (0x80 + 0x43)
  F10          = (0x80 + 0x44)
  F11          = (0x80 + 0x57)
  F12          = (0x80 + 0x58)
  Pause        = 0xff
end

enum Button
  Left
  Right
  Middle
end
