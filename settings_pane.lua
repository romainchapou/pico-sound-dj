settings_pane = class:new {
  init = function(_ENV)
    sub_wins = {confirm_pop_up, proj_create_win, file_chooser}
    project_file = nil
    has_unsaved_modifications = false

    local save_current_project = function()
      pattern_editor:store_all_patterns_in_mem()
      cstore(0x3100, 0x3100, 0x1200, project_file)
      has_unsaved_modifications = false
      send_msg("saved to " .. formatted_project_file(_ENV))
    end

    local select_and_open_file = function()
      file_chooser:init(function(chosen_file)
        project_file = chosen_file
        save_widg.inactive = false

        -- load project file
        reload(0x3100, 0x3100, 0x1200, project_file)
        pattern_editor:init()
        has_unsaved_modifications = false
      end)
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

    widgs = {
      make_btn_pushed_widget("open", action_after_check_unsaved(select_and_open_file)),

      make_btn_pushed_widget("open last", function()
          confirm_pop_up:init("TODO!", function() end)
      end),

      save_widg,

      make_btn_pushed_widget("save as", function()
        proj_create_win:init(function(new_name)
          local new_file = "/" .. new_name .. ".p8"

          if not file_readable(new_file) then
            project_file = new_file
            save_widg.inactive = false
            save_current_project()
          else
            send_msg "failed: project already exists"
          end
        end)
      end),

      make_btn_pushed_widget("clear", function()
        confirm_pop_up:init("current project\ndata will be\ncleared, continue?", function()
          reload(0x3100, 0x3100, 0x1200)
          has_unsaved_modifications = project_file ~= nil
          pattern_editor:init()

          send_msg "project data cleared"
        end)
      end),

      make_named_input_widget("theme", 1, 1, #THEMES, nil, nil,
        function(_ENV)
          base_widget_udpate(_ENV)

          for i=1,4 do
            pal(THEMES[1][2][i], THEMES[value][2][i], 1)
          end
        end,
        THEMES),

      make_btn_pushed_widget("exit", action_after_check_unsaved(stop))
    }

    -- the save widget is inactive until a project has been opened
    save_widg.inactive = true

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

    if not btn(4) then
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
    end
  end,

  formatted_project_file = function(_ENV)
    if project_file == nil then
      return "<scratch>"
    else
      local path = split(project_file, "/")
      return path[#path]
    end
  end,

  draw = function(_ENV)
    shadow_print("settings", 1, 1)

    local start_x, start_y = 4, 6

    shadow_rect(start_x -1, start_y + 12, start_x + 51, start_y + 60)
    shadow_print("project", start_x+4, start_y+10)

    for i=1,7 do
      local last_y = i >= 6 and 30 or 0
      local last_x = i >= 6 and -7 or 0
      widgs[i]:draw(start_x+8 + last_x, start_y + 8*i+11 + last_y, i == cur_widg)
    end

    -- draw logo
    sspr(40, 0, 32, 16, 16, 74)

    -- TODO bake this into the sprite sheet to clean up and save some tokens
    do
      local sx = 64
      local sy = 16

      local pr = function(txt)
        print(txt, sx, sy, 6)
        sy += 6
      end

      pr(" -- basics --")
      sy += 2
      pr("play:   start")
      pr("move:   ❎+⬅️➡️")
      sy += 4
      pr(" -- changes --")
      sy += 2
      pr("small:  🅾️+⬅️➡️")
      pr("big:    🅾️+⬆️⬇️")
      sy += 2
      pr("create: 🅾️")
      pr("clear:  ❎+🅾️")
      sy += 4
      pr("-- selection --")
      sy += 2
      pr("start:  ❎,❎")
      pr("copy:   ❎")
      pr("cut:    🅾️,🅾️")
      pr("paste:  🅾️,❎")
    end

    for w in all(sub_wins) do
      w:draw()
    end
  end,
}
