local defaults = require('splash.config')

local M = {
  _open = false,
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
  if opts.nvim_opt_overrides and opts.nvim_opt_overrides.win_opts then
    for k, v in pairs(opts.nvim_opt_overrides.win_opts) do
      winopt_restores[k] = vim.api.nvim_win_get_option(win, k)
      vim.api.nvim_win_set_option(win, k, v)
    end
  end
  local global_restores = {}
  if opts.nvim_opt_overrides and opts.nvim_opt_overrides.global_opts then
    for k, v in pairs(opts.nvim_opt_overrides.global_opts) do
      global_restores[k] = vim.api.nvim_get_option(k)
      vim.api.nvim_set_option(k, v)
    end
  end

  local splashBuf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(splashBuf, 'modified', false)
  vim.api.nvim_buf_set_option(splashBuf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(splashBuf, 'buflisted', false)
  vim.api.nvim_buf_set_option(splashBuf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(splashBuf, 'swapfile', false)
  vim.api.nvim_buf_set_option(splashBuf, 'filetype', opts.splash_buf_filetype)

  vim.api.nvim_buf_set_lines(splashBuf, 0, -1, false, paddedText)
  vim.api.nvim_win_set_buf(win, splashBuf)
  M._open = true

  local splash_exit = function(arg)
    if not M._open then
      vim.api.nvim_del_autocmd(arg.id)
    end

    if M._open and arg.buf == splashBuf then
      M._open = false
      vim.api.nvim_del_autocmd(arg.id)

      if arg.event == 'InsertEnter' or arg.event == 'StdinReadPre' then
        vim.api.nvim_buf_delete(splashBuf, { force = false, unload = false })
      end

      for k, v in pairs(global_restores) do
        vim.api.nvim_set_option(k, v)
      end
      for k, v in pairs(winopt_restores) do
        vim.api.nvim_win_set_option(win, k, v)
      end
    end
  end

  vim.api.nvim_create_autocmd({ 'InsertEnter', 'BufUnload', 'StdinReadPre' }, {
    callback = splash_exit,
  })
end

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
