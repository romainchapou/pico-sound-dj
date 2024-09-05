-- https://pico-8.fandom.com/wiki/Memory#Sound_effects

function set_change_export_file_nb_menuitem()
  menuitem(4, "< export nb " .. export_file_nb .. " >", function(b)
    export_file_nb -= bool_to_num(b&1 > 0) -- left
    export_file_nb += bool_to_num(b&2 > 0) -- right

    export_file_nb = max(0, export_file_nb)

    set_change_export_file_nb_menuitem()

    return true
  end)
end

function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  CHANNEL_X_OFFSET = 16

  export_file_nb = 0

  menuitem(1, "save", function()
    pattern_editor:store_all_patterns_in_mem()

    cstore(0x3100, 0x3100, 0x1200)
  end)

  menuitem(2, "export", function()
    pattern_editor:store_all_patterns_in_mem()

    cstore(0x3100, 0x3100, 0x1200, "export_" .. export_file_nb .. ".p8")
  end)

  menuitem(3, "load export", function()
    reload(0x3100, 0x3100, 0x1200, "export_" .. export_file_nb .. ".p8")

    _init()
  end)

  set_change_export_file_nb_menuitem()

  menuitem(5, "clear data", function()
    memset(0x3100, 0b01000000, 0x0100)
    memset(0x3200, 0, 0x1100)
    -- set the default speed of each sfx to 16
    for i=0,63 do
      poke(0x3200 + i*68+65, 16)
    end

    _init()
  end)

  T = 0 -- test variable

  current_pane = pattern_editor

  pattern_editor:init()
  sfx_editor:init(0)
end

function _update60()
  -- disable the default behaviour of the start button (which is to bring up
  -- the pause menu) so we can use it for playback launch
  poke(0x5f30, 1)

  -- debug
  if btnp(0, 1) then T -= 1 end
  if btnp(1, 1) then T += 1 end

  current_pane:update()

  if current_pane.post_udpate ~= nil then
    current_pane:post_udpate()
  end

  message_panel:update()

  key_handler:update() -- should be done last
end

function _draw()
  cls(7)

  current_pane:draw()

  message_panel:draw()

  debug:draw()
end
