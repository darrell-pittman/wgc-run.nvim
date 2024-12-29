local utils = require('wgc-run.utils')
local command = require('wgc-run.command')

local run_group = vim.api.nvim_create_augroup('WgcRunGroup', { clear = true })
local cd_group = vim.api.nvim_create_augroup('WgcCdGroup', { clear = true })

local M = {}

local function get_project_runners()
  local found = vim.fs.find(
    utils.get_config().project_run_file,
    { path = vim.uv.cwd() }
  )

  if found and #found == 1 then
    local m, err = loadfile(found[1])
    if m then
      return m()
    else
      vim.notify(
        string.format('Error processing "%s" file: %s', err),
        vim.log.levels.ERROR)
    end
  end
end

local function create_commands()
  utils.delete_autocmds(run_group)
  local runners = get_project_runners()
  runners = runners or utils.get_config().runners
  for i = 1, #runners do
    command.create_command(runners[i], run_group)
  end
end

M.setup = function(opts)
  utils.apply_config(opts)
  create_commands()

  vim.api.nvim_create_autocmd('DirChanged', {
    group = cd_group,
    pattern = '*',
    callback = create_commands
  })
end

return M
