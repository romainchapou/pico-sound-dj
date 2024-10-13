-- some constants
NOTE_NAMES = split "c,c#,d,d#,e,f,f#,g,g#,a,a#,b"
HEX_VALUES = "0123456789abcdef"
INSTRUMENT_NAMES = split "triangle,tilted saw,saw,square,pulse,organ,noise,phaser"
EFFECT_NAMES = split "no effect,slide,vibrato,drop,fade in,fade out,arp fast,arp slow"

-- TODO @Cleanup: use THEMES + THEME_NAMES, would probably save some tokens
THEMES = {
  { "honey"    , split "7,6,0,9"   }, -- default
  { "navy"     , split "1,13,7,4"  },
  { "arctic"   , split "0,13,7,12" },
  { "nerd"     , split "0,3,11,5"  },
  { "pumpkin"  , split "4,2,1,15"  },
}

function two_digit_number_str(num)
  return num < 10 and "0" .. tostr(num) or tostr(num)
end

function file_readable(file)
  return reload(0x4300, 0x4300, 1, file) == 1
end

function bool_to_num(bool)
  return bool and 1 or 0
end

function is_in_range(v, a, b)
  return v >= a and v <= b
end

function shadow_print(txt, x, y)
  rectfill(x-2, y-1, x+#txt*4, y+6, 7)

  print(txt, x, y+1, 6)
  print(txt, x, y, 0)
end

function shadow_rect(x1, y1, x2, y2)
  rect(x1, y1+1, x2, y2+1, 6)
  rect(x1,   y1, x2,   y2, 0)
end

function draw_win_bg(x1, y1, x2, y2)
  rectfill(x1-1, y1-1, x2+1, y2+1, 7)
  rect(x1, y1, x2, y2, 6)
end

function nudge(vert)
  if vert then
    if btnp(2) then return -1 end
    if btnp(3) then return  1 end
  else
    if btnp(0) then return -1 end
    if btnp(1) then return  1 end
  end

  return 0
end

function pitch_to_str(val)
  local name, oct = NOTE_NAMES[val % 12 + 1], val \ 12

  return #name == 1 and name .. " " .. oct or name .. oct

end

function get_playing_note(channel)
  local sfx_id = stat(46 + channel)

  if sfx_id < 0 then
    return "---"
  end

  local data = peek2(0x3200 + 68*sfx_id + 2*stat(50 + channel))
  local note, volume = data & 0b0000000000111111, shr(data & 0b0000111000000000, 9)

  if volume == 0 then
    return ""
  end

  return pitch_to_str(note)
end

function draw_horiz_line(y)
  line(0, y, 128, y, 6)
end
