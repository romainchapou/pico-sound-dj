settings_pane = class:new {
  sub_wins = {proj_create_win},
  proj_name = nil,

  update = function(_ENV)
    for w in all(sub_wins) do
      if w:update() ~= "inactive" then
        return
      end
    end

    if btn(4) and btnp(1) then
      GLOBAL.current_pane = pattern_editor
      return
    end

    -- restore the default behaviour of the start button for this screen
    poke(0x5f30, 0)

    if btnp_once(5) then
      proj_create_win:init(function(new_name)
        proj_name = new_name
      end)
    end
  end,

  draw = function(_ENV)
    for w in all(sub_wins) do
      w:draw()
    end

    shadow_print("settings", 1, 1)
  end,
}
