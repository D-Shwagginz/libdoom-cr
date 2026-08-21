@[Link(ldflags: "-L#{__DIR__}/../rsrc -lADLMIDI")]
lib ADLMIDI
  alias Player = Void

  fun adl_init(sample_rate : LibC::Long) : Player*
  fun adl_close(device : Player*) : Void
  fun adl_setNumChips(device : Player*, num_chips : LibC::Int) : LibC::Int
  fun adl_setBank(device : Player*, bank : LibC::Int) : LibC::Int
  fun adl_errorInfo(device : Player*) : LibC::Char* # check this on any negative return

  fun adl_rt_resetState(device : Player*) : Void
  fun adl_rt_noteOn(device : Player*, channel : UInt8, note : UInt8, velocity : UInt8) : LibC::Int
  fun adl_rt_noteOff(device : Player*, channel : UInt8, note : UInt8) : Void
  fun adl_rt_noteAfterTouch(device : Player*, channel : UInt8, note : UInt8, at_val : UInt8) : Void
  fun adl_rt_channelAfterTouch(device : Player*, channel : UInt8, at_val : UInt8) : Void
  fun adl_rt_controllerChange(device : Player*, channel : UInt8, type : UInt8, value : UInt8) : Void
  fun adl_rt_patchChange(device : Player*, channel : UInt8, patch : UInt8) : Void
  fun adl_rt_pitchBendML(device : Player*, channel : UInt8, msb : UInt8, lsb : UInt8) : Void
  fun adl_setSoftPanEnabled(device : Void*, softPanEn : LibC::Int) : Void

  fun adl_generate(device : Player*, sample_count : LibC::Int, out : Int16*) : LibC::Int
end
