settings_pane = class:new {
  sub_wins = {confirm_pop_up, proj_create_win, file_chooser},
  export_file = nil,

  widgs = {
    -- scratch --

    make_btn_pushed_widget("save", function()
      pattern_editor:store_all_patterns_in_mem()
      cstore(0x3100, 0x3100, 0x1200)

      send_msg("scratch saved to cartridge")
    end),

    make_btn_pushed_widget("clear", function()
      confirm_pop_up:init("current scratch\ndata will be\nlost, continue?", function()
        memset(0x3100, 0b01000000, 0x0100)
        memset(0x3200, 0, 0x1100)
        -- set the default speed of each sfx to 16
        for i=0,63 do
          poke(0x3200 + i*68+65, 16)
        end

        pattern_editor:init()

        send_msg("scratch data cleared")
      end)
    end),

    -- export file --

    make_btn_pushed_widget("export to file", function()
    end),

    make_btn_pushed_widget("load to scratch", function()
    end),

    make_btn_pushed_widget("choose file", function()
        file_chooser:init(function(new_file)
          export_file = new_file
      end)
    end),

    make_btn_pushed_widget("new file", function()
      proj_create_win:init(function(new_name)
        export_file = new_name .. ".p8"
      end)
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

      cur_widg = mid(1, cur_widg + nudge(true), #widgs)
    end
  end,

  draw = function(_ENV)
    shadow_print("settings", 1, 1)

    local start_x, start_y = 3, 6

    shadow_rect(start_x -1, start_y +12, start_x + 122, start_y + 35)
    shadow_print("scratch", start_x+4, start_y+10)

    for i=1,2 do
      widgs[i]:draw(start_x+12, start_y + 8*i+11, i == cur_widg)
    end

    shadow_rect(start_x -1, start_y +42, start_x + 122, start_y + 100)
    shadow_print("export file", start_x+4, start_y+40)

    local exp_txt, exp_color

    if export_file == nil then
      exp_txt = "not yet set!"
      exp_color = 6
    else
      local path = split(export_file, "/")
      exp_txt = #path > 2 and "../" .. path[#path] or "/" .. path[#path]
      exp_color = 9
    end

    print(exp_txt, start_x+12, start_y+49, 9)

    for i=3,#widgs do
      widgs[i]:draw(start_x+12, start_y + 8*i+35, i == cur_widg)
    end

    for w in all(sub_wins) do
      w:draw()
    end
  end,
}
