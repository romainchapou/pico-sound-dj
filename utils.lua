function two_digit_number_str(num)
  return num < 10 and "0" .. tostr(num) or tostr(num)
end

function bool_to_num(bool)
  return bool and 1 or 0
end

function is_in_range(v, a, b)
  return v >= a and v <= b
end

-- TODO minmax function to save some tokens
