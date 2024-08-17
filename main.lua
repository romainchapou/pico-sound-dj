-- https://pico-8.fandom.com/wiki/Memory#Sound_effects

function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  NOTE_NAMES = split("c,c#,d,d#,e,f,f#,g,g#,a,a#,b")
  HEX_VALUES = "0123456789abcdef"

  menuitem(1, "play", function()
    sfx_editor:play_sfx()
  end)

  menuitem(2, "save", function()
    sfx_editor:store_sfx_in_memory()
    -- TODO adapt
    cstore(0x3200, 0x3200, 64*68)
  end)

  T = 0 -- test variable

  current_pane = pattern_editor

  -- TODO temporary pane structure
  pane_selection = 1
  panes = { pattern_editor, sfx_editor }

  pattern_editor:init()
  sfx_editor:init(0)
end

function _update60()
  -- debug
  if btnp(0, 1) then T -= 1 end
  if btnp(1, 1) then T += 1 end

  -- TODO temporary solution
  if btn(4, 1) then
    if btnp(0) then pane_selection -= 1 end
    if btnp(1) then pane_selection += 1 end

    pane_selection = mid(1, pane_selection, 2)

    current_pane = panes[pane_selection]

    return
  end

  current_pane:update()

  key_handler:update()
end

function _draw()
  cls(7)

  current_pane:draw()

  debug:draw()
end
