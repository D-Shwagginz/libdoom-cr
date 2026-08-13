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

macro poll_key(doomkey, raylibkey)
  CDoom.doom_key_up(CDoom::DoomKey::{{doomkey}}) if Raylib::KeyboardKey::{{raylibkey}}.released?
  CDoom.doom_key_down(CDoom::DoomKey::{{doomkey}}) if Raylib::KeyboardKey::{{raylibkey}}.pressed?
end

macro poll_button(doombutton, raylibbutton)
  CDoom.doom_button_up(CDoom::DoomButton::{{doombutton}}) if Raylib::MouseButton::{{raylibbutton}}.released?
  CDoom.doom_button_down(CDoom::DoomButton::{{doombutton}}) if Raylib::MouseButton::{{raylibbutton}}.pressed?
end

def run
  Raylib.set_config_flags(Raylib::ConfigFlags::WindowResizable | Raylib::ConfigFlags::VSyncHint)
  Raylib.init_window(1024, 768, "LibDoom")
  Raylib.set_exit_key(Raylib::KeyboardKey::Null)
  Raylib.disable_cursor
  # Raylib.toggle_fullscreen
  # Raylib.set_target_fps(60)

  image = Raylib.gen_image_color(320, 200, Raylib::BLACK)
  screen_texture = Raylib.load_texture_from_image(image)
  Raylib.unload_image(image)
  Raylib.set_texture_filter(screen_texture, Raylib::TextureFilter::Point)

  RAudio.init_audio_device
  RAudio.set_master_volume(10.0)
  RAudio.set_audio_stream_buffer_size_default(512)
  audio_stream = RAudio.load_audio_stream(CDoom::DOOM_SAMPLERATE, 16, 2)
  RAudio.set_audio_stream_volume(audio_stream, 1.0)
  RAudio.play_audio_stream(audio_stream)

  adl_player = ADLMIDI.adl_init(44100)
  ADLMIDI.adl_setNumChips(adl_player, 4)
  ADLMIDI.adl_setBank(adl_player, MIDI_BANK)
  RAudio.set_audio_stream_buffer_size_default(MIDI_BUFFER_SIZE // 2)
  music_stream = RAudio.load_audio_stream(MIDI_SAMPLE_RATE, 16, 2)
  RAudio.set_audio_stream_volume(music_stream, 1.0)
  RAudio.play_audio_stream(music_stream)
  music_buffer = Pointer(Int16).malloc(2048)
  midi_tick_accumulator = 0.0

  ARGV.insert(0, "LibDoom")

  CDoom.doom_set_default_int("key_up", CDoom::DoomKey::W.value)
  CDoom.doom_set_default_int("key_down", CDoom::DoomKey::S.value)
  CDoom.doom_set_default_int("key_strafeleft", CDoom::DoomKey::A.value)
  CDoom.doom_set_default_int("key_straferight", CDoom::DoomKey::D.value)
  CDoom.doom_init(ARGV.size, ARGV.map(&.to_unsafe), 0)

  last_time = Raylib.get_time

  until Raylib.close_window?
    now = Raylib.get_time
    midi_tick_accumulator += now - last_time
    last_time = now

    while midi_tick_accumulator >= MIDI_TICK_TIME
      while (msg = CDoom.doom_tick_midi) != 0
        status = (msg & 0xFF).to_u8
        data1 = ((msg >> 8) & 0xFF).to_u8
        data2 = ((msg >> 16) & 0xFF).to_u8
        command = status & 0xF0
        channel = status & 0x0F

        case command
        when 0x80
          ADLMIDI.adl_rt_noteOff(adl_player, channel, data1)
        when 0x90
          if data2 == 0
            ADLMIDI.adl_rt_noteOff(adl_player, channel, data1) # vel 0 == note off
          else
            ADLMIDI.adl_rt_noteOn(adl_player, channel, data1, data2)
          end
        when 0xA0
          ADLMIDI.adl_rt_noteAfterTouch(adl_player, channel, data1, data2)
        when 0xB0
          ADLMIDI.adl_rt_controllerChange(adl_player, channel, data1, data2)
        when 0xC0
          ADLMIDI.adl_rt_patchChange(adl_player, channel, data1)
        when 0xD0
          ADLMIDI.adl_rt_channelAfterTouch(adl_player, channel, data1)
        when 0xE0
          ADLMIDI.adl_rt_pitchBendML(adl_player, channel, data2, data1) # wire order: LSB, MSB
        end
      end
      midi_tick_accumulator -= MIDI_TICK_TIME
    end

    if RAudio.audio_stream_processed?(music_stream)
      generated = ADLMIDI.adl_generate(adl_player, MIDI_BUFFER_SIZE, music_buffer)
      RAudio.update_audio_stream(music_stream, music_buffer, MIDI_BUFFER_SIZE // 2)
    end

    if RAudio.audio_stream_processed?(audio_stream)
      RAudio.update_audio_stream(audio_stream, CDoom.doom_get_sound_buffer, 512)
    end

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

    Raylib.update_texture(screen_texture, CDoom.doom_get_framebuffer(4))

    scalew = Raylib.get_screen_width.to_f / SRES_X.to_f
    scaleh = Raylib.get_screen_height.to_f / SRES_Y.to_f
    scale = [scalew, scaleh].min

    Raylib.begin_drawing
    Raylib.clear_background(Raylib::BLACK)
    Raylib.draw_texture_pro(screen_texture,
      Raylib::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: screen_texture.width.to_f, height: screen_texture.height.to_f),
      Raylib::Rectangle.new(x: (Raylib.get_screen_width - (SRES_X.to_f * scale)) * 0.5_f32, y: (Raylib.get_screen_height - (SRES_Y.to_f * scale)) * 0.5_f32,
        width: SRES_X.to_f * scale, height: SRES_Y.to_f * scale),
      Raylib::Vector2.new, 0, Raylib::WHITE)
    Raylib.end_drawing
  end

  RAudio.unload_audio_stream(audio_stream)
  RAudio.unload_audio_stream(music_stream)
  RAudio.close_audio_device
  ADLMIDI.adl_close(adl_player)
  Raylib.unload_texture(screen_texture)
  Raylib.close_window
end

run()
