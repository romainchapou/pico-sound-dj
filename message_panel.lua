message_panel = class:new {
  cur_msg = "",
  ttl = 0,
  important = false,

  update = function(_ENV)
    ttl = max(ttl-1)

    if ttl == 0 then important = false end
  end,

  draw = function(_ENV)
    local y_diff = max(10 - ttl)

    if ttl > 0 then
      rectfill(0,
               121+y_diff,
               important and 127 or max(current_pane_y == 2 and 100 or 109, 4*#cur_msg),
               127+y_diff,
               important and 9 or 7)
      print(cur_msg, 1, 122+y_diff, important and 0 or 6)
    end
  end
}

function send_msg(msg, important)
  if important == nil then important = true end

  if important or not message_panel.important then
    message_panel.cur_msg,
    message_panel.ttl,
    message_panel.important = msg,
                              important and 260 or 180,
                              important
  end
end
