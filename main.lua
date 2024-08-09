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
    add(notes, {
      pitch = 0, -- [0-63]
      waveform = 0, -- [0-7] aka instrument
      volume = 0, -- [0-7]
      effect = 0, -- [0-7]
      custom_inst = 0, -- [0-1]

      draw = function(self, x, y)
        if self.volume == 0 then
          pset(x,    y+4, 0)
          pset(x+4,  y+4, 0)
          pset(x+8,  y+4, 0)
          pset(x+13, y+4, 0)
          pset(x+18, y+4, 0)
          pset(x+23, y+4, 0)
        else
          print(note_names[self.pitch % 12 + 1], x, y, 0)
          print(self.pitch \ 12, x+8, y, 0)

          print(self.waveform, x+13, y, 0)
          print(self.volume, x+18, y, 0)
          print(self.effect > 0 and self.effect or ".", x+22, y, 0)
        end
      end
    })
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

  if btn(5) and not btn(4) then
    if sub_selection == 0 then
      if cur_note.volume == 0 then
        cur_note.volume = last_volume
        cur_note.pitch = last_pitch
      else
        -- edit pitch
        local delta = get_delta_value(12)

        cur_note.pitch = mid(0, cur_note.pitch + delta, 63)
        last_pitch = cur_note.pitch
      end
    elseif sub_selection == 1 then
      -- edit waveform
      cur_note.waveform = mid(0, cur_note.waveform + get_delta_value(1), 7)
    elseif sub_selection == 2 then
      -- edit volume
      cur_note.volume = mid(0, cur_note.volume + get_delta_value(7), 7)
    elseif sub_selection == 3 then
      -- edit effect
      cur_note.effect = mid(0, cur_note.effect + get_delta_value(1), 7)
    end

    if get_delta_value(1) ~= 0 or btnp_once(5) then
      play_tmp_note(cur_note)
    end

    return
  end

  if btn(4) then
    if btnp_once(5) and cur_note.volume ~= 0 then
      last_volume = cur_note.volume
      -- delete the note
      cur_note.volume = 0
      last_pitch = cur_note.pitch
    else
      local delta = get_delta_value(-4, 16)

      if delta ~= 0 then
        selection = mid(0, selection + get_delta_value(-4, 16), 31)
        selection = (selection \ 4) * 4
      end
    end

    return
  end

  if btnp(0) then sub_selection -= 1 end
  if btnp(1) then sub_selection += 1 end

  sub_selection = mid(0, sub_selection, 3)

  if btnp(2) then selection -= 1 end
  if btnp(3) then selection += 1 end

  selection %= 32

  if btnp_once(4) then
    cur_note.volume = cur_note.volume == 0 and 5 or 0
  end
end

function play_tmp_note(note)
  store_note(note, 0x3200 + 68) -- store to first note of sfx 1
  sfx(1, -1, 0, 1)
end

function store_note(note, addr)
  local v = 0
  v += note.pitch
  v += shl(note.waveform, 6)
  v += shl(note.volume, 9)
  v += shl(note.effect, 12)

  poke2(addr, v)
end

function store_in_mem()
  local sfxid = 0

  -- compute address of sfx
  local sfxaddr = 0x3200

  for i=1,32 do
    store_note(notes[i], sfxaddr)
    sfxaddr += 2
  end
end

function _update60()
  update_menu()
  key_handler:update()
end

function _draw()
  local start_y = 12

  cls(7)

  local sel_x, sel_y = selection >= 16 and 41 or 1, start_y + (selection % 16 + 1)*6

  local sel_width = 12

  if sub_selection > 0 then
    sel_width = 4
    sel_x += 13 + 5*(sub_selection-1)
  end

  rectfill(sel_x, sel_y-1, sel_x + sel_width, sel_y+5, 9)

  print("♪",  4, 10, 6)
  print("i", 15, 10, 6)
  print("v", 20, 10, 6)
  print("e", 25, 10, 6)

  for i=1,16 do
    local x, y = 2, start_y + i*6

    notes[i]:draw(x, y)
    x += 40
    notes[i+16]:draw(x, y)
  end

  print(selection, 0, 0, 0)
  print(sub_selection, 10, 0, 0)
end
