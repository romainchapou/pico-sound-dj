-- https://pico-8.fandom.com/wiki/Memory#Sound_effects

function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  note_names = split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")

  hex_values = "0123456789abcdef"

  last_pitch = 24
  last_volume = 5

  notes = {}

  selection = 0
  sub_selection = 0

  for i=1,32 do
    add(notes, make_note_widget())
  end

  last_edited_note = make_note_widget()
  last_edited_note.volume.value = 5
  last_edited_note.pitch.value = 24

  menuitem(1, "play", function()
    store_in_mem()
    sfx(0)
  end)

  menuitem(2, "save", function()
    store_in_mem()
    cstore(0x3200, 0x3200, 64)
  end)

  T = 0 -- test variable
  -- debug:add("last", function() return T end)
end

function get_delta_value(high, low)
  local delta = 0

  if low == nil then low = 1 end

  if btnp(0) then delta = -low end
  if btnp(1) then delta = low end
  if btnp(2) then delta = high end
  if btnp(3) then delta = -high end

  return delta
end

function update_menu()
  notes[selection+1]:update(sub_selection)

  if not btn(4) and not btn(5) then
    if btnp(0) then sub_selection -= 1 end
    if btnp(1) then sub_selection += 1 end

    sub_selection = mid(0, sub_selection, 3)

    if btnp(2) then selection -= 1 end
    if btnp(3) then selection += 1 end
  end

  selection = mid(0, selection, 31)
end

function store_in_mem()
  local sfxid = 0

  -- compute address of sfx
  local sfxaddr = 0x3200

  for i=1,32 do
    notes[i]:store_in_mem(sfxaddr)
    sfxaddr += 2
  end
end

function _update60()
  if btnp(0) then T -= 1 end
  if btnp(1) then T += 1 end

  update_menu()
  key_handler:update()
end

function _draw()
  local start_x, start_y, col_x_diff = 8, 12, 46

  cls(7)

  for i=0,1 do
    print("♪", start_x + i*col_x_diff +  2, 10, 6)
    print("i", start_x + i*col_x_diff + 16, 10, 6)
    print("v", start_x + i*col_x_diff + 22, 10, 6)
    print("e", start_x + i*col_x_diff + 28, 10, 6)

    fillp(0b10100101.1)
    line(start_x + 15 + i*col_x_diff -2, start_y + 5,
         start_x + 15 + i*col_x_diff -2, start_y + 101, 6)
    fillp()
  end

  rectfill(start_x-8, start_y+6, start_x-4, start_y+28, 9)
  rectfill(start_x-8, start_y+54, start_x-4, start_y+76, 9)

  rectfill(start_x-8+col_x_diff, start_y+6,  start_x-4+col_x_diff, start_y+28, 9)
  rectfill(start_x-8+col_x_diff, start_y+54, start_x-4+col_x_diff, start_y+76, 9)

  for i=1,16 do
    local x, y = start_x, start_y + i*6

    print(hex_values[i], x-7, y, (i-1)\4 % 2 == 0 and 7 or 6)

    notes[i]:draw(x, y, i-1 == selection, sub_selection)
    x += col_x_diff

    print(hex_values[i], x-7, y, (i-1)\4 % 2 == 0 and 7 or 6)

    notes[i+16]:draw(x, y, i+15 == selection, sub_selection)
  end

  print(selection, 0, 0, 0)
  print(sub_selection, 10, 0, 0)

  debug:draw()
end
