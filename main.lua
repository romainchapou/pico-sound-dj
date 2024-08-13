-- https://pico-8.fandom.com/wiki/Memory#Sound_effects

function _init()
  -- set key repeat
  poke(0x5f5c, 8)
  poke(0x5f5d, 1)

  note_names = split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")

  last_pitch = 24
  last_volume = 5

  notes = {}

  selection = 0
  sub_selection = 0

  for i=1,32 do
    add(notes, make_note_widget())
  end

  menuitem(1, "play", function()
    store_in_mem()
    sfx(0)
  end)

  menuitem(2, "save", function()
    store_in_mem()
    cstore(0x3200, 0x3200, 64)
  end)
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
  local cur_note = notes[selection+1]

  cur_note:update(sub_selection)

  if not btn(4) and not btn(5) then
    if btnp(0) then sub_selection -= 1 end
    if btnp(1) then sub_selection += 1 end

    sub_selection = mid(0, sub_selection, 3)

    if btnp(2) then selection -= 1 end
    if btnp(3) then selection += 1 end
  end

  selection %= 32
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
  update_menu()
  key_handler:update()
end

function _draw()
  local start_x, start_y = 2, 12

  cls(7)

  for i=0,1 do
    print("♪", start_x + i*40 +  2, 10, 6)
    print("i", start_x + i*40 + 15, 10, 6)
    print("v", start_x + i*40 + 21, 10, 6)
    print("e", start_x + i*40 + 27, 10, 6)
  end

  for i=1,16 do
    local x, y = start_x, start_y + i*6

    notes[i]:draw(x, y, i-1 == selection, sub_selection)
    x += 40
    notes[i+16]:draw(x, y, i+15 == selection, sub_selection)
  end

  print(selection, 0, 0, 0)
  print(sub_selection, 10, 0, 0)

  debug:draw()
end
