local utils = require('wgc-run.utils')

local M = {}

local current_job_id = nil

local constants = {
  WINDOW_TITLE = 'WgcRun',
  HEADER_SYM = '━',
  MARGIN = 1,
}

local disp = nil

local function pad(l)
  return utils.string.pad(l, constants.MARGIN)
end

local function tbl_pad(t)
  return vim.tbl_map(pad, t)
end

local function kill_job(f)
  if current_job_id and disp then
    vim.fn.jobstop(current_job_id)
    vim.api.nvim_buf_set_lines(disp.buf, -1, -1, false,
      { pad(string.format("Killed Job [ id = %d ]", current_job_id)) })
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

  local rows = vim.api.nvim_get_option_value('lines', { scope = 'global' })
  local cols = vim.api.nvim_get_option_value('columns', { scope = 'global' })
  local width = math.floor(0.8 * cols)
  local height = math.floor(0.8 * rows)
  local row = math.floor((rows - height) / 2) - 1
  local col = math.floor((cols - width) / 2)

  disp.width = width
  disp.buf = vim.api.nvim_create_buf(false, true)

  disp.win = vim.api.nvim_open_win(disp.buf, true, {
    relative = 'editor',
    row = row,
    col = col,
    width = width,
    height = height - 1,
    style = 'minimal',
    border = 'rounded',
    title = {
      {
        ' ::: [WgcRun] ::: ',
        'FloatBorder',
      },
    },
    title_pos = 'center',
    footer = {
      {
        ' Press <C-c> to kill job, q to close window (and kill job if running) ',
        'FloatBorder',
      },
    },
    footer_pos = 'center',
  })

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
  map('n', '<C-c>', kill_job)

  local noops = { 'a', 'c', 'd', 'i', 'x', 'r', 'o', 'p', }
  for _, l in ipairs(noops) do
    map('', l, '')
    map('', string.upper(l), '')
  end

  vim.api.nvim_buf_set_name(disp.buf, '[WgcRun]')
  callback()
end

local function default_runner(name, cmd, opts)
  local header = tbl_pad({
    name .. ' output ...', ''
  })

  local footer = tbl_pad({
    '',
    '--' .. name .. ' Finished!--',
    '',
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
