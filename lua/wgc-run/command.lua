local utils = require('wgc-run.utils')
local run = require('wgc-run.run')

local group = vim.api.nvim_create_augroup('WgcRunGroup', { clear = true })

local M = {}

local function validate(runner)
  local is_ok = utils.validate_strings(runner.pattern, function(p)
    return p and string.len(p) > 0
  end)

  if not is_ok then return is_ok end

  local tests = runner.validate and runner.validate.static

  if tests then
    if tests.exe_exists then
      is_ok = utils.validate_strings(tests.exe_exists, function(exe)
        return (vim.fn.executable(exe) == 1)
      end)
    end
    if is_ok then
      if tests.tests then
        is_ok = utils.validate_funcs(tests.tests)
      end
    end
  end

  return is_ok or false
end

local function process_run_file(runner)

end

local function process_cmd(runner)
  local run_cmd = runner and runner.run_cmd
  local is_ok = run_cmd and type(run_cmd) == 'table'

  if is_ok then
    local all_strings = vim.iter(run_cmd):all(function(cmd)
      return type(cmd) == 'string'
    end)
    if all_strings then
      runner.static_cmd = true
    else
      is_ok = vim.iter(run_cmd):all(function(cmd)
        local typ = type(cmd)
        return typ == 'string' or typ == 'function'
      end)
    end
  end

  return is_ok or false
end

M.create_command = function(runner)
  local ok = validate(runner)
  if ok then
    ok = ok and process_cmd(runner)
  end
  print('Ok:', ok)
  if ok then
    vim.api.nvim_create_autocmd('BufEnter', {
      group = group,
      pattern = runner.pattern,
      callback = function(info)
        run.run(info, runner)
      end,
    })
  end
end

return M