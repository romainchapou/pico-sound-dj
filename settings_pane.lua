settings_pane = class:new {
  init = function(_ENV)
    -- ugly :(
    if done_once then
      return
    end
    done_once = true

    sub_wins = {confirm_pop_up, proj_create_win, file_chooser}
    project_file = nil
    has_unsaved_modifications = false

    local save_current_project = function()
      pattern_editor:store_all_patterns_in_mem()
      cstore(0x3100, 0x3100, 0x1200, project_file)
      has_unsaved_modifications = false
      send_msg("saved to " .. formatted_project_file(_ENV))
    end

    local post_load_file = function(chosen_file)
      project_file = chosen_file
      save_widg.inactive = false

      has_unsaved_modifications = false

      store_str_to_cartdata(project_file)
      open_last_widg.inactive = load_str_from_cartdata() == ""
    end

    local open_chosen_file = function(chosen_file)
      local read_bytes = reload(0x3100, 0x3100, 0x1200, chosen_file)

      if read_bytes == 0 then
        send_msg "failed to read project file"
        open_last_widg.inactive = true
        store_str_to_cartdata ""
        cur_widg = 1
        return
      end

      post_load_file(chosen_file)
    end

    local action_after_check_unsaved = function(act_func)
      return function()
        if has_unsaved_modifications then
          confirm_pop_up:init("current project\nhas unsaved\nmodifications,\ndiscard them?",
                              act_func)
        else
          act_func()
        end
      end
    end

    save_widg = make_btn_pushed_widget("save", save_current_project)

    open_last_widg = make_btn_pushed_widget("open last", function()
      local open_last = function()
        open_chosen_file(load_str_from_cartdata())
      end

      if has_unsaved_modifications then
        confirm_pop_up:init(
        "current project\nhas unsaved\nmodifications,\ndiscard them\nto load\n"
        .. basename(load_str_from_cartdata()) ..
        "\n?", open_last)
      else
        open_last()
      end
    end
    )

    local apply_theme = function(val)
      for i=1,4 do
        pal(THEMES[1][2][i], THEMES[val][2][i], 1)
      end
    end

    theme_widg = make_named_input_widget("theme", 1, 1, #THEMES, nil, nil,
      function(_ENV)
        base_widget_udpate(_ENV)
        apply_theme(value)
        dset(0, value)
      end,
    THEMES)

    local apply_btn_swap_setting = function(val)
      if val == 0 then
        GLOBAL.BTN_A = 4
        GLOBAL.BTN_B = 5
      else
        GLOBAL.BTN_A = 5
        GLOBAL.BTN_B = 4
      end
    end

    btn_swap_widg = make_named_input_widget("btn config", 0, 0, 1, nil, nil,
      function(_ENV)
        local prev_value = value

        base_widget_udpate(_ENV)

        if value ~= prev_value then
          send_msg "❎ and ⬅️ swaped"
        end

        apply_btn_swap_setting(value)
        dset(1, value)
      end
    )

    widgs = {
      make_btn_pushed_widget("open", action_after_check_unsaved(function()
        file_chooser:init(open_chosen_file)
      end)),

      open_last_widg,

      save_widg,

      make_btn_pushed_widget("save as", function()
        proj_create_win:init(function(new_name)
          local new_file = "/" .. new_name .. ".p8"

          if not file_readable(new_file) then
            post_load_file(new_file)
            save_current_project()
          else
            send_msg "failed: project already exists"
          end
        end)
      end),

      theme_widg,

      btn_swap_widg,

      make_btn_pushed_widget("⌂ exit", action_after_check_unsaved(function()
        cls()
        print "bye!"
        stop()
      end))
    }

    -- the save widget is inactive until a project has been opened
    save_widg.inactive = true

    open_last_widg.inactive = load_str_from_cartdata() == ""

    -- apply settings saved in cartdata
    theme_widg(mid(1, dget(0), #THEMES) \ 1)
    apply_theme(theme_widg.value)

    btn_swap_widg(dget(1) == 1 and 1 or 0)
    apply_btn_swap_setting(btn_swap_widg.value)

    cur_widg = 1
  end,


  update = function(_ENV)
    -- restore the default behaviour of the start button for this screen
    poke(0x5f30, 0)

    for w in all(sub_wins) do
      local was_active = w.active
      w:update()
      if was_active then return end
    end

    if handle_move_pane(1) then return end

    if widgs[cur_widg]:update() then
      -- input handled
      return
    end

    cur_widg = mid(1, cur_widg + nudge(true), #widgs)

    -- note that this would produce an infinite loop if there was an inactive
    -- widget as the first or last one
    while widgs[cur_widg].inactive do
      cur_widg = mid(1, cur_widg + nudge(true), #widgs)
    end
  end,

  formatted_project_file = function(_ENV)
    return project_file and basename(project_file) or "<scratch>"
  end,

  draw = function(_ENV)
    shadow_print("settings", 1, 1)

    local start_x, start_y = 4, 3

    shadow_rect(start_x -1, start_y + 12, start_x + 51, start_y + 52)
    shadow_print("project", start_x+4, start_y+10)

    for i=1,7 do
      local last_x, last_y, is_bottom_widg = 0, 0, i >= 5

      if is_bottom_widg then
        last_x, last_y = -7, 24
      end

      widgs[i]:draw(start_x+8 + last_x, start_y + (is_bottom_widg and 9 or 8)*i+11 + last_y, i == cur_widg)
    end

    -- draw logo
    sspr(40, 0, 41, 17, 16, start_y + 56)

    -- draw the controls summary that has been baked in the spritesheet for token optimization
    -- below is the commented actual drawing code
    sspr(8, 24, 63, 93, 63, start_y + 10)

    -- do
    --   local sx = 63
    --   local sy = 16
    --
    --   local pr = function(txt)
    --     print(txt, sx, sy, 6)
    --     sy += 6
    --   end
    --
    --   pr " -- basics --"
    --   sy += 2
    --   pr "play:   start"
    --   pr "move:   ❎+⬅️➡️"
    --   sy += 4
    --   pr " -- changes --"
    --   sy += 2
    --   pr "small:  🅾️+⬅️➡️"
    --   pr "big:    🅾️+⬆️⬇️"
    --   sy += 2
    --   pr "create: 🅾️"
    --   pr "clear:  ❎+🅾️"
    --   sy += 4
    --   pr "-- selection --"
    --   sy += 2
    --   pr "start:  ❎,❎"
    --   pr "copy:   ❎"
    --   pr "cut:    🅾️,🅾️"
    --   pr "paste:  🅾️+start"
    -- end
  end,

  post_draw = function(_ENV)
    for w in all(sub_wins) do
      w:draw()
    end
  end
}
