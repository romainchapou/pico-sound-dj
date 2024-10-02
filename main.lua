function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  palt(0, false)
  palt(14, true)

  CHANNEL_X_OFFSET = 16

  T = 0 -- test variable

  current_pane_i = 2

  prev_pane_i = nil
  prev_pane_dist = 0

  panes = {settings_pane, pattern_editor, sfx_editor}

  settings_pane:init()
  pattern_editor:init()
  sfx_editor:init(0)

  waveform_editor:init()
end

-- dir : -1 for left, +1 for right
-- returns true if input handled
function handle_move_pane(dir)
  if btn(4) and btnp_once(max(dir, 0)) then
    prev_pane_i = current_pane_i
    prev_pane_dist = 128*dir
    current_pane_i = mid(1, current_pane_i+nudge(), 3)
    return true
  end
end

function _update60()
  waveform_editor:update()

  -- -- disable the default behaviour of the start button (which is to bring up
  -- -- the pause menu) so we can use it for playback launch
  -- poke(0x5f30, 1)
  --
  -- -- debug
  -- if btnp(0, 1) then T -= 1 end
  -- if btnp(1, 1) then T += 1 end
  --
  -- -- pane movement animation
  -- if prev_pane_i then
  --   prev_pane_dist *= 0.4
  --   if abs(prev_pane_dist) < 1 then
  --     prev_pane_dist = 0
  --     prev_pane_i = nil
  --   end
  -- end
  --
  -- local current_pane = panes[current_pane_i]
  --
  -- current_pane:update()
  --
  -- if current_pane.post_udpate ~= nil then
  --   current_pane:post_udpate()
  -- end
  --
  -- message_panel:update()
  --
  -- key_handler:update() -- should be done last
end

function _draw()
  cls(7)

  waveform_editor:draw()

  -- if prev_pane_i then
  --   camera(prev_pane_dist > 0 and 128 - prev_pane_dist or -128-prev_pane_dist, 0)
  --   panes[prev_pane_i]:draw()
  --   camera(-prev_pane_dist, 0)
  -- end
  --
  -- panes[current_pane_i]:draw()
  --
  -- camera()
  --
  -- -- mini map draw
  -- for i=1,3 do
  --   local x = 86 + i*9+6
  --
  --   if i < 3 then
  --     line(x+8, 4, x+8, 5, is_in_range(current_pane_i, i, i+1) and 9 or 6)
  --   end
  --
  --   rectfill(x, 1, x+7, 8, i == current_pane_i and 9 or 6)
  --   spr(16+i, x, 1)
  -- end

  message_panel:draw()

  debug:draw()
end
