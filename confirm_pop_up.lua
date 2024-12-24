-- could @Refactor a lot with proj_create_win

confirm_pop_up = class:new {
  init = function(_ENV, text, on_confirm)
    txt = text
    active = true

    conf_btn_i = 1

    sub_widgs = {
      -- cancel
      make_btn_pushed_widget("no", function() end),

      -- confirm
      make_btn_pushed_widget("yes!", function()
        on_confirm()
      end)
    }
  end,

  update = function(_ENV)
    if active then
      conf_btn_i = mid(1, conf_btn_i + nudge(), 2)

      if sub_widgs[conf_btn_i]:update() or btnp(4) then
        active = false
      end
    end
  end,

  draw = function(_ENV)
    if active then
      local start_x, start_y = 29, 34

      draw_win_bg(start_x-6, start_y-4, start_x+72, start_y + 62)

      print("confirmation", start_x+10, start_y-1, 6)
      print(txt, start_x-2, start_y+7, 0)

      local d = 0
      for i=1,2 do
        sub_widgs[i]:draw(start_x + d, start_y + 54, conf_btn_i == i)
        d += 52
      end
    end
  end
}
