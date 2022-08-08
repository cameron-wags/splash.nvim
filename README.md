# splash.nvim

Neovim intro message customization, no extras included.

## Installation

With packer:

```lua
use 'cameron-wags/splash.nvim'
```

Somewhere in your neovim configuration:

```lua
require 'splash'.setup()
```

## Configuration

### Quick Start

This is how to customize the text. In this example, `text_width` is required to
center the text correctly. Why doesn't splash calculate this? [It's
complicated](http://lua-users.org/wiki/LuaUnicode).

```lua
require 'splash'.setup {
  text = {
    '╔══════════════════════════════════════╗',
    '║                                      ║',
    '║                                      ║',
    '║         splash.nvim was here         ║',
    '║                                      ║',
    '║                                      ║',
    '╚══════════════════════════════════════╝'
  },
  text_width = 40,
}
```

### Advanced Configuration

```lua
require 'splash'.setup {
  -- List of lines splash will display. These lines should be the same length,
  -- if not: set text_width to the length of the longest line.
  text = {
    'boop',
    'beep',
    'brrp',
  },

  -- Override the text height for padding calculations.
  -- text_height = 14,

  -- Override text width for padding calculations. If your text array has
  -- different row lengths, or contains UTF-8 characters: set this to the
  -- longest string's length.
  -- text_width = 14,

  -- Overrides the value of vim.api.nvim_get_option('lines') for padding
  -- calculations.
  -- vim_height = 30

  -- Overrides the value of vim.api.nvim_get_option('columns') for padding
  -- calculations.
  -- vim_width = 80

  -- Splash will display only if this function returns true at the time
  -- splash.setup() is invoked.
  splash_condition = function()
    return vim.fn.argc() == 0 or vim.fn.line2byte('$') ~= 1 and not vim.opt.insertmode
  end,

  -- Used to display options(e.g.: line numbers, statusline) temporarily so the
  -- splash display looks cleaner. The overwritten settings will be restored
  -- when splash exits.
  nvim_opt_overrides = {
    -- Window option overrides
    win_opts = {
      wrap = false,
      relativenumber = false,
      number = false,
    },

    -- Global option overrides. Neovim shows these on startup by default, but
    -- these make splash look squeaky clean.
    global_opts = {
      -- laststatus = 0,
      -- ruler = false
    },
  },

  -- Sets custom buffer filetype option, default: 'SplashScreen'. Exclude this
  -- filetype from plugins that change the appearance of buffers, like
  -- indent-blankline.
  splash_buf_filetype = 'SplashScreen',
}
```

## Inspiration

- [alpha-nvim](https://github.com/goolord/alpha-nvim)
- [dashboard-nvim](https://github.com/glepnir/dashboard-nvim)
- [startup.nvim](https://github.com/startup-nvim/startup.nvim)

