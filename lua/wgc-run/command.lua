local utils = require('wgc-run.utils')
local run = require('wgc-run.run')

local M = {}

local function validate_static(runner)
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

local function process_cmd(runner)
  local static_cmd = true
  local run_cmd = runner and runner.run_cmd
  local is_ok = run_cmd and type(run_cmd) == 'table'

  if is_ok then
    for i = 1, #run_cmd do
      local typ = type(run_cmd[i])
      if typ == 'function' then
        static_cmd = false
      else
        if typ ~= 'string' then
          is_ok = false
          break
        end
      end
    end
  end

  return is_ok, static_cmd
end

local function validate_runtime(info, runner)
  local is_ok = true
  local tests = runner.validate and runner.validate.runtime

  if tests then
    is_ok = utils.validate_funcs(tests.tests, info)
  end

  return is_ok
end

local function create_run_command(info, runner, static_cmd)
  local ok = validate_runtime(info, runner)
  local buffer_keymaps = utils.get_config().buffer_keymaps

  if ok then
    if buffer_keymaps and type(buffer_keymaps) == 'function' then
      buffer_keymaps(info)
    end

    vim.api.nvim_buf_create_user_command(info.buf, 'WgcRun', function()
        run.run(info, runner, static_cmd)
      end,
      {})
  end
end

M.create_command = function(runner, run_group)
  local static_cmd
  local ok = validate_static(runner)
  if ok then
    ok, static_cmd = process_cmd(runner)
  end
  if ok then
    vim.api.nvim_create_autocmd('BufRead', {
      group = run_group,
      pattern = runner.pattern,
      callback = function(info)
        create_run_command(info, runner, static_cmd)
      end,
    })
  end
end

return M
