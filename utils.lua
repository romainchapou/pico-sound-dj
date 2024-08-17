function two_digit_number_str(num)
  return num < 10 and "0" .. tostr(num) or tostr(num)
end
