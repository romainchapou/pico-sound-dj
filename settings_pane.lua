settings_pane = class:new {
  update = function(_ENV)
    if btn(4, 1) and btnp(1) then
      GLOBAL.current_pane = pattern_editor
    end
  end,

  draw = function(_ENV)
    shadow_print("settings", 1, 1)

    print("wow very empty", 34, 60, 6)
  end,
}
