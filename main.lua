function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  CHANNEL_X_OFFSET = 16

  T = 0 -- test variable

  current_pane = pattern_editor

  settings_pane:init()
  pattern_editor:init()
  sfx_editor:init(0)
end

function _update60()
  -- disable the default behaviour of the start button (which is to bring up
  -- the pause menu) so we can use it for playback launch
  poke(0x5f30, 1)

  -- debug
  if btnp(0, 1) then T -= 1 end
  if btnp(1, 1) then T += 1 end

  current_pane:update()

  if current_pane.post_udpate ~= nil then
    current_pane:post_udpate()
  end

  message_panel:update()

  key_handler:update() -- should be done last
end

function _draw()
  cls(7)

  current_pane:draw()

  message_panel:draw()

  debug:draw()
end
