proj_create_win = class:new {
  init = function(_ENV, on_confirm)
    new_name = ""

    active = true

    panel_i = 1
    letter_i = 0
    conf_btn_i = 0

    timer = 0

    letter_widgs = {}


    for i=0,9 do
      add(letter_widgs, make_btn_pushed_widget(tostr(i)))
    end

    for v=97,122 do
      add(letter_widgs, make_btn_pushed_widget(chr(v)))
    end

    for c in all(split(" _-@", "")) do
      add(letter_widgs, make_btn_pushed_widget(c))
    end

    validate_widgs = {
      make_btn_pushed_widget("cancel", function() end),
      make_btn_pushed_widget("ok", function()
        on_confirm(new_name)
      end)
    }
  end,

  update = function(_ENV)
    if active then
      timer += 1
      timer %= 60

      -- remove char with btn X
      if btnp_once(5) then
        if new_name == "" then
          active = false
        end

        new_name = sub(new_name, 1, #new_name-1)
      end

      if panel_i == 1 then
        -- letters panel
        if letter_i >= 30 and btnp(3) then
          panel_i += 1
          conf_btn_i = (letter_i - 30) \ 5
        else
          if btnp(0) and letter_i % 10 ~= 0 then letter_i -= 1 end
          if btnp(1) and letter_i % 10 ~= 9 then letter_i += 1 end
          if btnp(2) and letter_i >= 10 then letter_i -= 10 end
          if btnp(3) then letter_i += 10 end

          letter_i = mid(0, letter_i, 39)

          local letter = letter_widgs[letter_i+1]:update()

          -- add letter from button widget press
          if letter then
            new_name = new_name .. letter
            timer = 0
          end
        end
      else
        if btnp(2) then
          panel_i -= 1
        else
          conf_btn_i = mid(0, conf_btn_i + nudge(), 1)

          if validate_widgs[conf_btn_i+1]:update() then
            active = false
          end
        end
      end

      panel_i = mid(1, panel_i, 2)
    end
  end,

  draw = function(_ENV)
    if active then
      local start_x, start_y = 29, 36

      draw_win_bg(start_x-6, start_y-4, start_x+72, start_y + 56)

      print("new project name:", start_x, start_y, 6)

      rectfill(start_x - 2,  start_y+8, start_x + 68, start_y + 14, 6)

      print(sub(new_name, max(1, #new_name-15)), start_x, start_y+9, 0)

      if timer \ 30 <= 0 then
        print("_", start_x + min(#new_name, 16)*4, start_y+9, 0)
      end

      for i=0,#letter_widgs-1 do
        letter_widgs[i+1]:draw(start_x + 5 + (i%10)*6, start_y + 20 + (i \ 10)*6,
                               i == letter_i and panel_i == 1)
      end

      local d = 0
      for i=1,2 do
        validate_widgs[i]:draw(start_x + d, start_y + 48,
                               conf_btn_i == i-1 and panel_i == 2)
        d += 60
      end
    end
  end
}
