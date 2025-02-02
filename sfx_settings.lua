sfx_settings = {}

for sfx_id=0,63 do
  add(sfx_settings, class:new {
    init = function(_ENV)
      waveform_edit_mode = false
      wave_do_bass = make_named_input_widget("bass", 0, 0, 1)

      speed = make_named_input_widget("spd", 16, 1, 255, 4)

      loop_in   = make_named_input_widget("in",  0, 0, 63, 8)
      loop_out  = make_named_input_widget("out", 0, 0, 63, 8)

      noise     = make_named_input_widget("noiz", 0, 0, 1)
      buzz      = make_named_input_widget("buzz", 0, 0, 1)
      detune    = make_named_input_widget("detu", 0, 0, 2)
      reverb    = make_named_input_widget("revb", 0, 0, 2)
      dampen    = make_named_input_widget("damp", 0, 0, 2)
      edit_mode = make_named_input_widget("edtm", 1, 0, 1)

      -- wave_do_bass excluded form the regular widgets
      widgets = {speed, loop_in, loop_out, noise, buzz,
                 detune, reverb, dampen, edit_mode}

      load_from_mem(_ENV)
    end,

    load_from_mem = function(_ENV)
      local addr = 0x3200 + 68*sfx_id + 64

      local byte = @addr
      edit_mode(byte & 1)
      noise(shr(byte, 1) & 1)
      buzz(shr(byte, 2) & 1)
      detune(byte\8  % 3)
      reverb(byte\24 % 3)
      dampen(byte\72 % 3)

      wave_do_bass(peek(addr+1) & 0b00000001)
      waveform_edit_mode = (peek(addr+2) & 0b10000000) == 128

      speed(peek(addr+1))
      loop_in(peek(addr+2) & 0b01111111)
      loop_out(peek(addr+3))
    end,

    store_in_mem = function(_ENV, store_waveform, opt_addr)
      if store_waveform == nil then
        store_waveform = waveform_edit_mode
      end

      local addr = opt_addr or 0x3200 + 68*sfx_id + 64

      -- editor mode and filter switches
      poke(addr, edit_mode.value
                 + shl(noise.value, 1)
                 + shl(buzz.value, 2)
                 + detune.value * 8
                 + reverb.value * 24
                 + dampen.value * 72)

      poke(addr+1, store_waveform and (speed.value & 0b11111110)
                   + wave_do_bass.value or speed.value)

      poke(addr+2, loop_in.value + bool_to_num(store_waveform)*128)
      poke(addr+3, loop_out.value)
    end
  })
end
