local opts = {
  project_run_file = '.wgc_run.lua',
}

local M = {}

M.apply_config = function(new_opts)
  opts = vim.tbl_extend('force', opts, new_opts)
end

M.get_config = function()
  return opts
end

local validate = function(vals, val_typ, f)
  if not vals then return false end

  local ok = true
  local typ = type(vals)
  if typ == val_typ then
    ok = ok and f(vals)
  elseif typ == 'table' then
    ok = ok and vim.iter(vals):all(function(val)
      return type(val) == val_typ and f(val)
    end)
  else
    ok = false
  end
  return ok
end

M.validate_strings = function(vals, f)
  return validate(vals, 'string', f)
end

M.validate_funcs = function(vals, ...)
  local t = { ... }
  return validate(vals, 'function', function(f)
    return f(unpack(t))
  end)
end

M.delete_autocmds = function(group)
  local cmds = vim.api.nvim_get_autocmds({ group = group })
  vim.iter(cmds):each(function(cmd)
    vim.api.nvim_del_autocmd(cmd.id)
  end)
end

M.string = {
  center = function(str, width)
    local padding = math.floor((width - string.len(str)) / 2)
    return M.string.pad(str, padding)
  end,
  pad = function(str, n)
    return string.rep(' ', n) .. str
  end,
  is_empty = function(s)
    return (not s) or (string.len(s) == 0)
  end,
  is_not_empty = function(s)
    return not M.string.is_empty(s)
  end,
  empty_val = function(s, v)
    return M.string.is_empty(s) and v or s
  end,
}

return M
