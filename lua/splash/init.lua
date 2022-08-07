local defaults = {
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

local buf_draw = function(opts)
  local text = opts.text

  local width = opts.vim_width or vim.api.nvim_get_option('columns')
  local textWidth = opts.text_width or #text[1]
  if width >= textWidth then
    local padWidth = math.floor(((width - textWidth) / 2) + 0.5)
    local padstr = ''
    for _ = 1, padWidth do
      padstr = ' ' .. padstr
    end
    for i, _ in ipairs(text) do
      text[i] = padstr .. text[i]
    end
  end

  local height = opts.vim_height or vim.api.nvim_get_option('lines')
  local textHeight = opts.text_height or #text
  local padHeight = math.floor(((height - textHeight) / 2) + 0.5)
  local paddedText = {}
  for _ = 1, padHeight do
    table.insert(paddedText, '')
  end
  for _, v in ipairs(text) do
    table.insert(paddedText, v)
  end
  -- gets rid of ~ in the number column
  -- padding the bottom instead of some weird NonText hl hack
  for _ = 1, padHeight do
    table.insert(paddedText, '')
  end

  local win = vim.api.nvim_get_current_win()
  local winopt_restores = {}
  for k, v in pairs(opts.nvim_opt_overrides.win_opts) do
    winopt_restores[k] = vim.api.nvim_win_get_option(win, k)
    vim.api.nvim_win_set_option(win, k, v)
  end
  local global_restores = {}
  for k, v in pairs(opts.nvim_opt_overrides.global_opts) do
    global_restores[k] = vim.api.nvim_get_option(k)
    vim.api.nvim_set_option(k, v)
  end

  local splashBuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(splashBuf, 'modified', false)
  vim.api.nvim_buf_set_option(splashBuf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(splashBuf, 'buflisted', false)
  vim.api.nvim_buf_set_option(splashBuf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(splashBuf, 'swapfile', false)
  vim.api.nvim_buf_set_option(splashBuf, 'filetype', opts.splash_buf_filetype)

  vim.api.nvim_buf_set_lines(splashBuf, 0, -1, false, paddedText)
  vim.api.nvim_win_set_buf(win, splashBuf)

  local reset_win = function()
    vim.api.nvim_buf_delete(splashBuf, { force = false, unload = false })
    vim.cmd('enew')
    for k, v in pairs(global_restores) do
      vim.api.nvim_set_option(k, v)
    end
    for k, v in pairs(winopt_restores) do
      vim.api.nvim_win_set_option(win, k, v)
    end
  end

  vim.api.nvim_create_autocmd('InsertEnter,WinEnter', {
    pattern = '<buffer>',
    callback = reset_win,
    once = true,
  })
end

local M = {}

M.setup = function(opts)
  if opts then
    for k, v in pairs(opts) do
      defaults[k] = v
    end
  end
  if defaults.splash_condition() then
    buf_draw(defaults)
  end
end

return M
