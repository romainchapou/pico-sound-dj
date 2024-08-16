function store_sfx_in_memory(sfx_id)
  -- compute address of sfx
  local sfxaddr = 0x3200 + 68*sfx_id

  for i=1,32 do
    notes[i]:store_in_mem(sfxaddr)
    sfxaddr += 2
  end

  -- following byte, editor mode and filter switches
  local byte = 0
  byte += 1 -- TODO beware that we may not want to override the editor mode
  byte += shl(sfx_noise.value, 1)
  byte += shl(sfx_buzz.value, 2)
  byte += sfx_detune.value * 8
  byte += sfx_reverb.value * 24
  byte += sfx_dampen.value * 72
  poke(sfxaddr, byte)

  sfxaddr += 1
  poke(sfxaddr, sfx_speed.value)

  sfxaddr += 1
  poke(sfxaddr, sfx_loop_in.value)

  sfxaddr += 1
  poke(sfxaddr, sfx_loop_out.value)
end

function load_sfx_from_memory(sfx_id)
  local sfxaddr = 0x3200 + 68*sfx_id

  for i=1,32 do
    notes[i]:load_from_mem(sfxaddr)
    sfxaddr += 2
  end

  -- following byte, editor mode and filter switches
  local byte = peek(sfxaddr)
  sfx_noise.value = shr(byte, 1) & 1
  sfx_buzz.value = shr(byte, 2) & 1
  sfx_detune.value = byte\8  % 3
  sfx_reverb.value = byte\24 % 3
  sfx_dampen.value = byte\72 % 3

  byte += 1 -- TODO beware that we may not want to override the editor mode
  byte += shl(sfx_noise.value, 1)
  byte += shl(sfx_buzz.value, 2)
  byte += sfx_detune.value * 8
  byte += sfx_reverb.value * 24
  byte += sfx_dampen.value * 72
  poke(sfxaddr, byte)

  sfxaddr += 1
  poke(sfxaddr, sfx_speed.value)

  sfxaddr += 1
  poke(sfxaddr, sfx_loop_in.value)

  sfxaddr += 1
  poke(sfxaddr, sfx_loop_out.value)
end
