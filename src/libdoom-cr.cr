require "./libdoom-cr/lib.cr"
require "./libdoom-cr/libdoom.cr"
require "./libdoom-cr/implementation.cr"

require "raylib-cr"
require "raylib-cr/audio.cr"
require "./adlmidi.cr"

SRES_X = 320
SRES_Y = 240

MIDI_BUFFER_SIZE =  2048
MIDI_SAMPLE_RATE = 44100
MIDI_TICK_TIME   = 1.0 / 140.0
MIDI_BANK        = 16
Fiber::ExecutionContext.default.resize(maximum: System.cpu_count)

macro poll_key(doomkey, raylibkey)
  CDoom.doom_key_up(CDoom::DoomKey::{{doomkey}}) if Raylib::KeyboardKey::{{raylibkey}}.released?
  CDoom.doom_key_down(CDoom::DoomKey::{{doomkey}}) if Raylib::KeyboardKey::{{raylibkey}}.pressed?
end

macro poll_button(doombutton, raylibbutton)
  CDoom.doom_button_up(CDoom::DoomButton::{{doombutton}}) if Raylib::MouseButton::{{raylibbutton}}.released?
  CDoom.doom_button_down(CDoom::DoomButton::{{doombutton}}) if Raylib::MouseButton::{{raylibbutton}}.pressed?
end

def run
  CDoom.doom_set_default_int("key_up", CDoom::DoomKey::W.value)
  CDoom.doom_set_default_int("key_down", CDoom::DoomKey::S.value)
  CDoom.doom_set_default_int("key_strafeleft", CDoom::DoomKey::A.value)
  CDoom.doom_set_default_int("key_straferight", CDoom::DoomKey::D.value)
  CDoom.doom_init(ARGC_UNSAFE, ARGV_UNSAFE, 0)

  until Raylib.close_window?
    poll_key(TAB, Tab)
    poll_key(ENTER, Enter)
    poll_key(ESCAPE, Escape)
    poll_key(SPACE, Space)
    poll_key(APOSTROPHE, Apostrophe)
    poll_key(MULTIPLY, KpMultiply)
    poll_key(COMMA, Comma)
    poll_key(MINUS, Minus)
    poll_key(PERIOD, Period)
    poll_key(SLASH, Slash)
    poll_key(ZERO, Zero)
    poll_key(ONE, One)
    poll_key(TWO, Two)
    poll_key(THREE, Three)
    poll_key(FOUR, Four)
    poll_key(FIVE, Five)
    poll_key(SIX, Six)
    poll_key(SEVEN, Seven)
    poll_key(EIGHT, Eight)
    poll_key(NINE, Nine)
    poll_key(SEMICOLON, Semicolon)
    poll_key(EQUALS, Equal)
    poll_key(LEFT_BRACKET, LeftBracket)
    poll_key(RIGHT_BRACKET, RightBracket)
    poll_key(A, A)
    poll_key(B, B)
    poll_key(C, C)
    poll_key(D, D)
    poll_key(E, E)
    poll_key(F, F)
    poll_key(G, G)
    poll_key(H, H)
    poll_key(I, I)
    poll_key(J, J)
    poll_key(K, K)
    poll_key(L, L)
    poll_key(M, M)
    poll_key(N, N)
    poll_key(O, O)
    poll_key(P, P)
    poll_key(Q, Q)
    poll_key(R, R)
    poll_key(S, S)
    poll_key(T, T)
    poll_key(U, U)
    poll_key(V, V)
    poll_key(W, W)
    poll_key(X, X)
    poll_key(Y, Y)
    poll_key(Z, Z)
    poll_key(BACKSPACE, Backspace)
    poll_key(CTRL, LeftControl)
    poll_key(CTRL, RightControl)
    poll_key(LEFT_ARROW, Left)
    poll_key(UP_ARROW, Up)
    poll_key(RIGHT_ARROW, Right)
    poll_key(DOWN_ARROW, Down)
    poll_key(SHIFT, LeftShift)
    poll_key(SHIFT, RightShift)
    poll_key(ALT, LeftAlt)
    poll_key(ALT, RightAlt)
    poll_key(F1, F1)
    poll_key(F2, F2)
    poll_key(F3, F3)
    poll_key(F4, F4)
    poll_key(F5, F5)
    poll_key(F6, F6)
    poll_key(F7, F7)
    poll_key(F8, F8)
    poll_key(F9, F9)
    poll_key(F10, F10)
    poll_key(F11, F11)
    poll_key(F12, F12)
    poll_key(PAUSE, Pause)

    poll_button(LEFT, Left)
    poll_button(RIGHT, Right)
    poll_button(MIDDLE, Middle)

    delta = Raylib.get_mouse_delta * 2
    CDoom.doom_mouse_move(delta.x, delta.y)

    CDoom.doom_update
    LibDoom.doom_draw
  end
  LibDoom.i_quit
end

run()
