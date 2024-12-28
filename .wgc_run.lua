return {
  run_cmd = {
    'love',
    function(_)
      local found = vim.fs.find('main.lua', {
        path = vim.uv.cwd() })

      if found and #found == 1 then
        return vim.fs.dirname(found[1])
      end
    end,
  },
  run_cwd = vim.uv.cwd(),
}
