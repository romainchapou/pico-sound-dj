proj_create_win = class:new {
  init = function(_ENV, on_confirm)
    new_name = ""

    on_confirm = on_confirm
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

    cancel_widg = make_btn_pushed_widget("cancel", function() end)

    confirm_widg = make_btn_pushed_widget("ok", function()
      on_confirm(new_name)
    end)
  end,

  update = function(_ENV)
    if not active then
      return "inactive"
    end

    timer += 1
    timer %= 60

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

        -- remove char with btn O
        if btnp_once(4) then
          new_name = sub(new_name, 1, #new_name-1)
        end
      end
    else
      if btnp(2) then
        panel_i -= 1
      else
        if btnp(0) then conf_btn_i -= 1 end
        if btnp(1) then conf_btn_i += 1 end

        conf_btn_i = mid(0, conf_btn_i, 1)
        local conf_ret = conf_btn_i == 0 and cancel_widg:update() or confirm_widg:update()

        if conf_ret then
          active = false
          return "done"
        end
      end
    end

    panel_i = mid(1, panel_i, 2)

    return "updated"
  end,

  draw = function(_ENV)
    if not active then return end

    local start_x, start_y = 29, 36

    rectfill(start_x-7, start_y-5, start_x+73, start_y + 57, 7)
    rect(start_x-6, start_y-4, start_x+72, start_y + 56, 6)

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

    cancel_widg:draw(start_x, start_y + 48, conf_btn_i == 0 and panel_i == 2)
    confirm_widg:draw(start_x+60, start_y + 48, conf_btn_i == 1 and panel_i == 2)


  end
}
