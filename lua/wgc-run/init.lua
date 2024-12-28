local utils = require('wgc-run.utils')
local command = require('wgc-run.command')

local M = {}

M.setup = function(opts)
  utils.apply_config(opts)
  local cfg = utils.get_config()
  for i = 1, #cfg.runners do
    command.create_command(cfg.runners[i])
  end
end

return M
