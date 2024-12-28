local runners = {
  {
    name = 'Love',
    pattern = '*.lua',
    validate = {
      static = {
        exe_exists = { 'love' },
        tests = { function() return true end },
      },
      runtime = {
        file_exists = { 'main.lua' },
        tests = {
          function(_)
            local found = vim.fs.find('main.lua', {
              path = vim.uv.cwd(),
            })
            return found and #found == 1
          end,
        },
      },
    },
    run_cmd = {
      'love',
      function(_)
        local found = vim.fs.find('main.lua', {
          path = vim.uv.cwd(),
        })
        if found and #found == 1 then
          return vim.fs.dirname(found[1])
        end
      end,
    },
    run_cwd = function(_)
      return vim.uv.cwd()
    end,
  },
  {
    name = 'Cargo',
    pattern = '*.rs',
    validate = {
      static = {
        exe_exists = { 'cargo' },
        file_exists = { 'Cargo.toml' },
      },
    },
    run_command = {
      'cargo',
      'run'
    }
  }
}

print(runners)
