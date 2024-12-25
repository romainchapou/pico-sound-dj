function make_btn_state_seq(btn_v1, btn_v2)
  return class:new {
    v1_hold_time = 0,
    v2_hold_time = 0,
    between_time = 0,
    seq_registered = false,

    s = 0,

    update = function(_ENV)
      local function inct(v)
        return min(32000, v+1)
      end

      if s == 0 then
        -- waiting for input state

        -- reset all
        v1_hold_time = 0
        v2_hold_time = 0
        between_time = 0
        seq_registered = false

        if btnp(btn_v1) and not key_handler.last_frame_btn[btn_v1] then
          s += 1
        end
      elseif s == 1 then
        -- hold of v1

        if btn() == shl(1, btn_v1) then
          v1_hold_time = inct(v1_hold_time)
        elseif btn() ~= 0 then
          s = 0
        else
          s = v1_hold_time < 10 and s+1 or 0
        end
      elseif s == 2 then
        -- between presses

        if btn() == 0 then
          between_time = inct(between_time)
        elseif btn() ~= shl(1, btn_v2) then
          s = 0
        else
          s = between_time < 20 and s+1 or 0
        end
      elseif s == 3 then
        -- hold of v2

        if btn() == shl(1, btn_v2) then
          v2_hold_time = inct(v2_hold_time)
        elseif btn() ~= 0 then
          s = 0
        else
          -- launch sequence registered
          seq_registered = v2_hold_time < 10
          s = 0
        end
      end
    end
  }
end

key_handler = class:new {
  last_frame_btn = {},
  scheduled_reset = false,

  states = {
    [4] = {[4] = make_btn_state_seq(4, 4), [5] = make_btn_state_seq(4, 5)},
    [5] = {[4] = make_btn_state_seq(5, 4), [5] = make_btn_state_seq(5, 5)}
  },

  update = function(_ENV)
    for i=4,5 do
      for j=4,5 do
        local state = states[i][j]

        if scheduled_reset then
          state.s = 0
          state.seq_registered = false
        else
          state:update()
        end
      end
    end

    scheduled_reset = false

    for v=0,6 do
      last_frame_btn[v] = btn(v)
    end
  end
}

function btnp_once(val, dont_reset_sequence)
  local ret = btn(val) and not key_handler.last_frame_btn[val]

  if ret and not dont_reset_sequence then
    key_handler.scheduled_reset = true
  end

  return ret
end

-- return true when the sequence "btn(v1) -> btn(v2)" is quickly inputed
-- v1 must be 4 or 5
function btnp_seq(v1, v2)
  local ret = key_handler.states[v1][v2].seq_registered

  if ret then
    key_handler.scheduled_reset = true
  end

  return ret
end
