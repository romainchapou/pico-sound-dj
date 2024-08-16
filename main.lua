-- https://pico-8.fandom.com/wiki/Memory#Sound_effects

function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  NOTE_NAMES = split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")
  HEX_VALUES = "0123456789abcdef"

  menuitem(1, "play", function()
    sfx_editor:store_sfx_in_memory()
    sfx(0)
  end)

  menuitem(2, "save", function()
    sfx_editor:store_sfx_in_memory()
    -- TODO adapt
    cstore(0x3200, 0x3200, 68)
  end)

  T = 0 -- test variable
  -- debug:add("last", function() return T end)
  -- debug:add("sub_sel", function() return note_sub_selection end)

  sfx_editor:init(0)
end

function _update60()
  -- debug
  if btnp(0, 1) then T -= 1 end
  if btnp(1, 1) then T += 1 end

  sfx_editor:update()

  key_handler:update()
end

function _draw()
  cls(7)

  sfx_editor:draw()

  debug:draw()
end
