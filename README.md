# wgc-run

A neovim plugin to run programs. Can be used to run things like
'cargo run' for a rust project or 'love <root_dir>' for a love project.

## Configuration
The setup function for this plugin receives a table that can have the
following keys:

* buffer_keymaps (optional)
* project_run_file (optional, defaults to .wgc_run.lua)
* runners (optional)

### buffer_keymaps
This entry is a function that takes in the autocmd BufRead info object and
creates any keymaps desired for the current buffer. Here we can map
keystrokes to the WgcRun command for the current buffer.

### project_run_file
This is the name of the project root runner definition file.

### runners
Runners is an optional entry in the plugin config. Runners defined here
will be fallback runners for neovim. Config runners can be overridden
by runners defined in a file called .wgc_run.lua in a 'project' root dir.
A project root dir is the current working directory of vim.

runners is a table of runner definitions that describe how to run
a program when in a buffer. For example if we are in a rust file and
want to run 'cargo run' for your project the runner definiton gives
neovim the info required to do this and will create a User command called
:WgcRun which will run the program and open a window which will show the
output of the program.

A runner definition is a table the following keys:
* name (required) - The name of the runner
* pattern (required) - A string|string[] that specifies the file pattern to match
for this runner. This is the same as the pattern used for autocmds in neovim.
If the file you open matches this autopat the :WgcRun command will be created
for your buffer (assuming validation tests pass).
* validate (optional)- A list of tests that will be run when
you open a file that matchs autopat. All these tests must pass or the WgcRun
command will not be created for your buffer. The 'validate' table can have
any of the following keys:

    * static (optional) - A table of tests that can be run on startup be any
    matching file is opened. These tests can be used for things like testing
    that the cargo exe exists or the cargo.toml file exists. This static table
    can have the following keys:
        * exe_exists (optional) - a string|string[] that lists executables
        that vim must be able to find.
        * tests (optional) - an array of functions that take no args
        return true if test passed,

    * runtime (optional) - An array of functions that holds validation
    functions that take in the BufRead info object and return true if
    validation passes. These functions will be called on BufRead for files
    that match the pattern.

* run_cmd (required) - A list of strings or functions that return strings. The
functions will receive the BufRead info object. Once processed, the run_cmd
command will be an array of strings that are passed to vim.fn.jobstart() as
the cmd.

* run_cwd (optional) - A string or a function that returns a string. The
function will receive the BufRead info object.  Once processed the run_cwd
will be a string representing the current working directory for the
vim.fn.jobstart() call. If not provided then the neovim current working
directory will be used.

## Example Config.
(Note: It is more flexible to define runners in a .wgc_run.lua file in your project)

```lua

require('wgc-run').setup {
    buffer_keymaps = function(info)
-- Note: Use buffer = info.buf to make a buffer local key mapping
vim.keymap.set('n', '<leader>w', ':WgcRun<cr>', { buffer = info.buf, silent = true })
end,
runners = {
 -- This runner works to run the 'love' game engine
 -- from any lua file in a the love project.
 -- Note: to run a love project you call 'love <root_dir>'
 -- where <root_dir> is the folder containing the main.lua
 -- file. So we define the run_cmd with the string arg 'love'
 -- and the neovim cwd.
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
                              path = vim.uv.cwd(),
                              })
                  return found and #found == 1
                      end,
              },
          },
      },
      run_cmd = {
          'love',
          vim.uv.cwd(),
      }
  },
  -- This runner works to run 'cargo run' for rust
  -- projects. It validates that cargo exe can be found
  -- and the Cargo.toml can be found in cwd.
  {
      name = 'Cargo',
      pattern = '*.rs',
      validate = {
          static = {
              exe_exists = 'cargo',
              tests = {
                  function()
                      local found = vim.fs.find('Cargo.toml', { path = vim.uv.cwd() })
                      return found and #found == 1
                      end,
              },
          },
      },
      run_cmd = {
          'cargo',
          'run'
      }
  }
}
```


## Example .wgc_run.lua file for a love project (preferred method)

```lua
local dir = '/home/darrell/projects/love/shooter'

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
             }
    }
}
```
