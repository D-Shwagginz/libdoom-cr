require "./libdoom-cr/lib.cr"
require "./libdoom-cr/doom.cr"

require "raylib-cr"
require "raylib-cr/audio.cr"

SRES_X = 320
SRES_Y = 240

macro poll_key(key)
  CDoom.doom_key_up(CDoom::Key::{{key}}) if Raylib::KeyboardKey::{{key}}.released?
  CDoom.doom_key_down(CDoom::Key::{{key}}) if Raylib::KeyboardKey::{{key}}.pressed?
end

macro poll_button(button)
  CDoom.doom_button_up(CDoom::Button::{{button}}) if Raylib::MouseButton::{{button}}.released?
  CDoom.doom_button_down(CDoom::Button::{{button}}) if Raylib::MouseButton::{{button}}.pressed?
end

def run
  Raylib.set_config_flags(Raylib::ConfigFlags::WindowResizable | Raylib::ConfigFlags::VSyncHint)
  Raylib.init_window(1024, 768, "LibDoom")
  Raylib.set_exit_key(Raylib::KeyboardKey::Null)
  Raylib.disable_cursor
  # Raylib.set_target_fps(60)

  image = Raylib.gen_image_color(320, 200, Raylib::BLACK)
  screen_texture = Raylib.load_texture_from_image(image)
  Raylib.unload_image(image)
  Raylib.set_texture_filter(screen_texture, Raylib::TextureFilter::Point)

  RAudio.init_audio_device
  RAudio.set_audio_stream_buffer_size_default(512)
  audio_stream = RAudio.load_audio_stream(CDoom::DOOM_SAMPLERATE, 16, 2)
  RAudio.play_audio_stream(audio_stream)

  ARGV.insert(0, "LibDoom")

  CDoom.doom_set_default_int("key_up", CDoom::Key::W.value)
  CDoom.doom_set_default_int("key_down", CDoom::Key::S.value)
  CDoom.doom_set_default_int("key_strafeleft", CDoom::Key::A.value)
  CDoom.doom_set_default_int("key_straferight", CDoom::Key::D.value)
  CDoom.doom_init(ARGV.size, ARGV.map(&.to_unsafe), 0)

  until Raylib.close_window?
    if RAudio.audio_stream_processed?(audio_stream)
      RAudio.update_audio_stream(audio_stream, CDoom.doom_get_sound_buffer, 512)
    end

    poll_key(Tab)
    poll_key(Enter)
    poll_key(Escape)
    poll_key(Space)
    poll_key(Apostrophe)
    poll_key(KpMultiply)
    poll_key(Comma)
    poll_key(Minus)
    poll_key(Period)
    poll_key(Slash)
    poll_key(Zero)
    poll_key(One)
    poll_key(Two)
    poll_key(Three)
    poll_key(Four)
    poll_key(Five)
    poll_key(Six)
    poll_key(Seven)
    poll_key(Eight)
    poll_key(Nine)
    poll_key(Semicolon)
    poll_key(Equal)
    poll_key(LeftBracket)
    poll_key(RightBracket)
    poll_key(A)
    poll_key(B)
    poll_key(C)
    poll_key(D)
    poll_key(E)
    poll_key(F)
    poll_key(G)
    poll_key(H)
    poll_key(I)
    poll_key(J)
    poll_key(K)
    poll_key(L)
    poll_key(M)
    poll_key(N)
    poll_key(O)
    poll_key(P)
    poll_key(Q)
    poll_key(R)
    poll_key(S)
    poll_key(T)
    poll_key(U)
    poll_key(V)
    poll_key(W)
    poll_key(X)
    poll_key(Y)
    poll_key(Z)
    poll_key(Backspace)
    poll_key(LeftControl)
    poll_key(RightControl)
    poll_key(Left)
    poll_key(Up)
    poll_key(Right)
    poll_key(Down)
    poll_key(LeftShift)
    poll_key(RightShift)
    poll_key(LeftAlt)
    poll_key(RightAlt)
    poll_key(F1)
    poll_key(F2)
    poll_key(F3)
    poll_key(F4)
    poll_key(F5)
    poll_key(F6)
    poll_key(F7)
    poll_key(F8)
    poll_key(F9)
    poll_key(F10)
    poll_key(F11)
    poll_key(F12)
    poll_key(Pause)

    poll_button(Left)
    poll_button(Right)
    poll_button(Middle)

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

  Raylib.unload_texture(screen_texture)
  Raylib.close_window
end

# fun crystal_D_DoomMain()
#   puts "D_DoomMain called"
# end

run()
