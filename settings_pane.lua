settings_pane = class:new {
  sub_wins = {proj_create_win, file_chooser},
  proj_name = nil,

  widgs = {
    make_btn_pushed_widget("save scratch", function()
      pattern_editor:store_all_patterns_in_mem()
      cstore(0x3100, 0x3100, 0x1200)

      send_msg("scratch saved to cartridge")
    end),

    make_btn_pushed_widget("open new project", function()
      proj_create_win:init(function(new_name)
        proj_name = new_name
      end)
    end),

    make_btn_pushed_widget("set export file", function()
      file_chooser:init(function(new_file)
        proj_name = new_file
      end)
    end),

    make_btn_pushed_widget("clear scratch data", function()
      memset(0x3100, 0b01000000, 0x0100)
      memset(0x3200, 0, 0x1100)
      -- set the default speed of each sfx to 16
      for i=0,63 do
        poke(0x3200 + i*68+65, 16)
      end

      pattern_editor:init()

      send_msg("scratch data cleared")
    end)
  },

  cur_widg = 1,

  update = function(_ENV)
    -- restore the default behaviour of the start button for this screen
    poke(0x5f30, 0)

    for w in all(sub_wins) do
      local was_active = w.active
      w:update()
      if was_active then return end
    end

    if btn(4) then
      if btnp(1) then
        GLOBAL.current_pane = pattern_editor
        return
      end
    else
      if widgs[cur_widg]:update() then
        -- input handled
        return
      end

      if btnp(2) then cur_widg -= 1 end
      if btnp(3) then cur_widg += 1 end

      cur_widg = mid(1, cur_widg, #widgs)
    end
  end,

  draw = function(_ENV)
    shadow_print("settings", 1, 1)

    local start_x, start_y = 3, 6

    for i = 1,#widgs do
      widgs[i]:draw(start_x, start_y + 8*i, i == cur_widg)
    end

    for w in all(sub_wins) do
      w:draw()
    end
  end,
}
