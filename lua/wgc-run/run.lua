local utils = require('wgc-run.utils')

local M = {}

vim.cmd('highlight link WgcRunHeader Title')
vim.cmd('highlight link WgcRunSubHeader Function')

local current_job_id = nil

local constants = {
  WINDOW_TITLE = 'WgcRun',
  WINDOW_WIDTH = 65,
  HEADER_SYM = '━',
  MARGIN = 1,
}

local function pad(l)
  return utils.string.pad(l, constants.MARGIN)
end

local function center(l)
  return utils.string.center(l, constants.WINDOW_WIDTH)
end

local function tbl_pad(t)
  return vim.tbl_map(pad, t)
end


local disp = nil

local function kill_job(f)
  if current_job_id and disp then
    vim.fn.jobstop(current_job_id)
    vim.api.nvim_buf_set_lines(disp.buf, -1, -1, false, { pad(string.format("Killed Job [ id = %d ]", current_job_id)) })
    current_job_id = nil
  end
  if f then f() end
end

local function close_window()
  kill_job(function()
    disp = nil
    current_job_id = nil
    vim.cmd [[bwipeout]]
  end)
end

local function open_window(callback)
  if disp then
    if vim.api.nvim_win_is_valid(disp.win) then
      vim.api.nvim_win_close(disp.win, true)
    end
    disp = nil
  end
  disp = {}
  vim.cmd(('%svnew'):format(constants.WINDOW_WIDTH))
  disp.buf = vim.api.nvim_get_current_buf()
  disp.win = vim.api.nvim_get_current_win()

  vim.cmd('setlocal buftype=nofile bufhidden=wipe nobuflisted' ..
    ' nolist noswapfile nowrap nospell nonumber norelativenumber' ..
    ' nofoldenable signcolumn=no')

  local map = (function()
    local defaults = {
      buffer = disp.buf,
      silent = true,
      nowait = true,
    }

    return function(mode, lhs, rhs, opts)
      opts = opts or {}
      opts = vim.tbl_extend('keep', opts, defaults)
      vim.keymap.set(mode, lhs, rhs, opts)
    end
  end)()

  map('n', 'q', close_window)
  map('n', '<esc>', close_window)
  map('n', '<C-c>', kill_job)

  local noops = { 'a', 'c', 'd', 'i', 'x', 'r', 'o', 'p', }
  for _, l in ipairs(noops) do
    map('', l, '')
    map('', string.upper(l), '')
  end

  vim.api.nvim_buf_set_name(disp.buf, '[WgcRun]')
  vim.api.nvim_buf_set_lines(disp.buf, 0, -1, false, {
    center(constants.WINDOW_TITLE),
    center('::: press [q] or <esc> to close (<C-c> to kill job) :::'),
    pad(string.rep(constants.HEADER_SYM, constants.WINDOW_WIDTH - 2 * constants.MARGIN)),
    '',
  })
  vim.api.nvim_buf_add_highlight(disp.buf, -1, 'WgcRunHeader', 0, constants.MARGIN, -1)
  vim.api.nvim_buf_add_highlight(disp.buf, -1, 'WgcRunSubHeader', 1, constants.MARGIN, -1)
  callback()
end

local function default_runner(name, cmd, opts)
  local header = tbl_pad({
    name .. ' output ...', ''
  })

  local footer = tbl_pad({
    '',
    '--' .. name .. ' Finished!--',
  })


  local default_handler = function(_, data)
    if data then
      data = vim.tbl_filter(utils.string.is_not_empty, data)
      if #data > 0 then
        data = tbl_pad(data)
        if disp then
          vim.api.nvim_buf_set_lines(disp.buf, -1, -1, false, data)
          vim.cmd [[normal G0]]
        end
      end
    end
  end

  opts.on_stdout = default_handler
  opts.on_stderr = default_handler

  opts.on_exit = function()
    if disp then
      vim.api.nvim_buf_set_lines(disp.buf, -1, -1, false, footer)
      vim.cmd [[normal G0]]
    end
    current_job_id = nil
  end

  return function()
    kill_job()
    if disp then
      vim.api.nvim_buf_set_lines(disp.buf, -1, -1, false, header)
    end
    current_job_id = vim.fn.jobstart(cmd, opts)
    if disp then
      vim.api.nvim_buf_set_lines(disp.buf, -1, -1, false,
        { pad(string.format("Started Job [ id = %d ]", current_job_id)) })
    end
  end
end

local function process_cmd(info, runner)
  local cmd = vim.iter(runner.run_cmd):map(function(v)
    local typ = type(v)
    if typ == 'string' then
      return v
    elseif typ == 'function' then
      return v(info)
    end
  end):totable()

  return cmd
end

local function process_cwd(info, runner)
  local cwd = runner.run_cwd
  if type(cwd) == 'function' then
    cwd = cwd(info)
  end

  if type(cwd) == 'string' and string.len(cwd) > 0 then
    return cwd
  end
end

M.run = function(info, runner, static_cmd)
  local cmd = runner.run_cmd
  local opts = {
    stdout_bufferd = false,
  }
  local cwd = process_cwd(info, runner)
  if cwd then opts.cwd = cwd end

  if not static_cmd then
    cmd = process_cmd(info, runner)
  end
  open_window(default_runner(runner.name, cmd, opts))
end

return M
