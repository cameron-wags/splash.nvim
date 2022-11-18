local defaults = require('splash.config')

local M = {
  _open = false,
  _splashBuf = nil,
  _opts = nil,
}

local pad_text = function(opts)
  local text = {}

  local width = opts.vim_width or vim.api.nvim_win_get_width(0)
  local textWidth = opts.text_width or #opts.text[1]
  if width >= textWidth then
    local padWidth = math.floor(((width - textWidth) / 2) + 0.5)
    local padstr = ''
    for _ = 1, padWidth do
      padstr = ' ' .. padstr
    end
    for i, _ in ipairs(opts.text) do
      table.insert(text, padstr .. opts.text[i])
    end
  end

  local height = opts.vim_height or vim.api.nvim_win_get_height(0)
  local textHeight = opts.text_height or #opts.text
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

  return paddedText
end

local redraw_buf = function(arg)
  if M._open then
    vim.api.nvim_buf_set_lines(M._splashBuf, 0, -1, false, pad_text(M._opts))
  else
    vim.api.nvim_del_autocmd(arg.id)
  end
end

local splash_open = function(opts)
  local paddedText = pad_text(opts)

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
  M._splashBuf = splashBuf
  M._opts = opts
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

  if opts.resize_with_window then
    vim.api.nvim_create_autocmd('VimResized', {
      callback = redraw_buf
    })
  end
end

M.setup = function(opts)
  if opts then
    for k, v in pairs(opts) do
      defaults[k] = v
    end
  end
  if defaults.splash_condition() then
    splash_open(defaults)
  end
end

return M
