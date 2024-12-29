local utils = require('wgc-run.utils')

local M = {}

local function validate(info, runner)
  local is_ok = true
  local tests = runner.validate and runner.validate.runtime

  if tests then
    is_ok = utils.validate_funcs(tests.tests, info.file)
  end

  return is_ok
end

M.run = function(info, runner)
  local ok = validate(info, runner)
  print('Run Ok: ', ok, ', Running... ', vim.inspect(runner.run_cmd))
end

return M
