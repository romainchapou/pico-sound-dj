-- could @Refactor a lot with proj_create_win

confirm_pop_up = class:new {
  init = function(_ENV, text, on_confirm)
    txt = text
    active = true
    conf_func = on_confirm

    conf_btn_i = 0

    cancel_widg = make_btn_pushed_widget("no", function() end)

    confirm_widg = make_btn_pushed_widget("yes!", function()
      conf_func()
    end)
  end,

  update = function(_ENV)
    if not active then return end

    conf_btn_i = mid(0, conf_btn_i + nudge(), 1)

    local conf_ret = conf_btn_i == 0 and cancel_widg:update() or confirm_widg:update()

    if conf_ret or btnp(4) then
      active = false
    end
  end,

  draw = function(_ENV)
    if not active then return end

    local start_x, start_y = 29, 36

    draw_win_bg(start_x-6, start_y-4, start_x+72, start_y + 56)

    print("confirmation", start_x+10, start_y-1, 6)

    print(txt, start_x-2, start_y+7, 0)

    cancel_widg:draw(start_x, start_y + 48, conf_btn_i == 0)
    confirm_widg:draw(start_x+52, start_y + 48, conf_btn_i == 1)
  end
}
