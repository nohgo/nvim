-- This plugin runs xmvlog; xrun or CDSHOME alone cannot supply its checks.
vim.g.enable_cadence = vim.g.enable_cadence ~= false and vim.fn.executable 'xmvlog' == 1
if not vim.g.enable_cadence then return end

vim.pack.add { { src = 'https://github.com/nohgo/cadence.nvim', version = 'main' } }
require('cadence').setup {}
