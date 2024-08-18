-- https://pico-8.fandom.com/wiki/Memory#Sound_effects

function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  NOTE_NAMES = split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")
  HEX_VALUES = "0123456789abcdef"
  CHANNEL_X_OFFSET = 16

  menuitem(1, "save", function()
    sfx_editor:store_sfx_in_memory()
    -- TODO adapt
    cstore(0x3200, 0x3200, 64*68)
  end)

  T = 0 -- test variable

  current_pane = pattern_editor

  pattern_editor:init()
  sfx_editor:init(0)
end

function _update60()
  -- debug
  if btnp(0, 1) then T -= 1 end
  if btnp(1, 1) then T += 1 end

  current_pane:update()

  key_handler:update() -- should be done last
end

function _draw()
  cls(7)

  current_pane:draw()

  debug:draw()
end
