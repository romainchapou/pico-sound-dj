function _init()
  -- set key repeat
  poke(0x5f5c, 4)
  poke(0x5f5d, 1)

  cartdata("__hiyaa_psdj")

  palt(0, false)
  palt(14, true)

  current_pane_x, current_pane_y = 1, 2

  prev_pane_x, prev_pane_y = nil, nil

  prev_pane_dist_x, prev_pane_dist_y = 0, 0

  scheduled_for_init = false

  for s in all(sfx_settings) do
    s:init()
  end

  panes = {
    {settings_pane, sfx_overview,   sfx_editor},
    {settings_pane, pattern_editor, sfx_editor}
  }

  settings_pane:init()
end

-- dir : -1 for left/top, +1 for right/bottom
-- returns true if input handled
function handle_move_pane(dir, vert)
  if btn(BTN_B) and btnp_once(max(dir, 0) + bool_to_num(vert)*2) then
    prev_pane_x,prev_pane_y = current_pane_x,current_pane_y

    if vert then
      prev_pane_dist_y = 128*dir
      prev_pane_dist_x = 0
      current_pane_y = mid(1, current_pane_y+nudge(vert), 2)
    else
      prev_pane_dist_x = 128*dir
      prev_pane_dist_y = 0
      current_pane_x = mid(1, current_pane_x+nudge(), 3)
    end

    scheduled_for_init = true

    return true
  end
end

function _update60()
  -- disable the default behaviour of the start button (which is to bring up
  -- the pause menu) so we can use it for playback launch
  poke(0x5f30, 1)

  -- pane movement animation
  if prev_pane_x or prev_pane_y then
    prev_pane_dist_x *= 0.4
    prev_pane_dist_y *= 0.4

    if abs(prev_pane_dist_y) < 1 and abs(prev_pane_dist_x) < 1 then
      prev_pane_dist_y, prev_pane_dist_x = 0, 0
      prev_pane_y, prev_pane_x = nil, nil
    end
  end

  local current_pane = panes[current_pane_y][current_pane_x]

  current_pane:update()

  if current_pane.post_udpate ~= nil then
    current_pane:post_udpate()
  end

  message_panel:update()

  if scheduled_for_init then
    -- not using 'current_pane' as would differ
    panes[current_pane_y][current_pane_x]:init()
    scheduled_for_init = false
  end

  key_handler:update() -- should be done last
end

function camera_dist(d)
  return d == 0 and 0 or (d > 0 and 128 - d or -128-d)
end

function draw_minimap_square(x, y, selected, sprite)
  rectfill(x-1, y-1, x+16, y+8, 7) -- going more to the right in case of a long filname
  rectfill(x, y, x+7, y+7, selected and 9 or 6)
  spr(sprite, x, y)
end

function _draw()
  cls(7)

  if prev_pane_x and prev_pane_y then
    camera(camera_dist(prev_pane_dist_x), camera_dist(prev_pane_dist_y))

    panes[prev_pane_y][prev_pane_x]:draw()
    camera(-prev_pane_dist_x, -prev_pane_dist_y)
  end

  local current_pane = panes[current_pane_y][current_pane_x]

  current_pane:draw()

  camera()

  print(settings_pane:formatted_project_file(), 1, 122, 6)

  if current_pane.post_draw ~= nil then
    current_pane:post_draw()
  end

  -- draw mini map
  local map_y_diff = 9*bool_to_num(current_pane_y == 2)
  draw_minimap_square(86+1*9+6, 109+1 + map_y_diff,  current_pane_x == 1, 16+1) -- settings
  draw_minimap_square(86+2*9+6, 109+1,  current_pane_x == 2 and current_pane_y == 1, 16+2) -- sfx overview
  draw_minimap_square(86+2*9+6, 109+10, current_pane_x == 2 and current_pane_y == 2, 2*16+2) -- patterns
  draw_minimap_square(86+3*9+6, 109+1 + map_y_diff,  current_pane_x == 3, 16+3) -- sfx

  message_panel:draw()
end
