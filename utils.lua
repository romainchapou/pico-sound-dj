-- some constants
NOTE_NAMES = split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")
HEX_VALUES = "0123456789abcdef"
INSTRUMENT_NAMES = split("triangle,tilted saw,saw,square,pulse,organ,noise,phaser")
EFFECT_NAMES = split("no effect,slide,vibrato,drop,fade in,fade out,arp fast,arp slow")

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

-- TODO to save some tokens
-- * minmax
-- * nudge btn
