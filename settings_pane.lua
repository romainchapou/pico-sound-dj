settings_pane = class:new {
  init = function(_ENV)
    proj_create_win:init()
  end,

  update = function(_ENV)
    if btn(4) and btnp(1) then
      GLOBAL.current_pane = pattern_editor
      return
    end

    -- restore the default behaviour of the start button for this screen
    poke(0x5f30, 0)

    proj_create_win:update()
  end,

  draw = function(_ENV)
    shadow_print("settings", 1, 1)

    proj_create_win:draw()
  end,
}
