local dir = vim.uv.cwd()

return {
  {
    name = 'Love',
    pattern = '*.lua',
    validate = {
      static = {
        exe_exists = 'love',
      },
      runtime = {
        tests = {
          function(_)
            local found = vim.fs.find('main.lua', {
              path = dir,
            })
            return found and #found == 1
          end,
        },
      },
    },
    run_cmd = {
      'love',
      dir,
    },
    run_cwd = dir,
  }
}
