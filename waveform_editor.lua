waveform_editor = class:new {
  init = function(_ENV)
    values = {}

    for i=1,64 do
      local v = peek(0x3200 + i-1)
      v = v > 128 and v - 255 or v
      add(values, v)
    end

    cur_col = 32

    do_bass = false

    menuitem(1, "save to cart", function()
      local sfx_id = 0 -- TODO
      local sfxaddr = 0x3200 + 68*sfx_id

      for i=1,64 do
        local v = values[i]
        v = v < 0 and v + 255 or v
        poke(sfxaddr, v)
        sfxaddr += 1
      end

      -- set the bass
      local v = peek(0x3241)
      -- v &= 0b11111110
      -- v += bool_to_num(do_bass)
      poke(0x3241, v)

      -- activate as waveform instrument
      local v = peek(0x3242)
      v &= 0b01111111
      v += 128
      poke(0x3242, v)

      cstore(0x3100, 0x3100, 0x1200)
    end)
  end,

  update = function(_ENV)
    local id_to_change = mid(1, cur_col + nudge(), 64)

    if btn(5) then
      values[id_to_change] = mid(-128, values[cur_col] + nudge(true), 127)
    end

    cur_col = id_to_change
  end,

  draw = function(_ENV)
    for i=1,64 do
      local xpos = 2*(i-1)
      line(xpos, 64, xpos, 64+values[i], i == cur_col and 9 or 6)
    end

    local v = values[cur_col]

    local cur_x_pos, cur_y_pos = 2*(cur_col-1), 64+v
    rect(cur_x_pos-1, cur_y_pos-1, cur_x_pos+1, cur_y_pos+1, 9)
    pset(cur_x_pos, cur_y_pos, 7)

    local print_str = tostr(v)

    if abs(v) > 64 then
      local px, py = cur_x_pos - #print_str*2+1, v <= 0 and 67 or 58
      px = mid(0, px, 129 - #print_str*4)
      rectfill(px-1, py-1, px + #print_str*4 - 1, py+5, 7)
      print(v, px, py, 9)
    end
  end
}
