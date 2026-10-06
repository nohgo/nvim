-- Personal plugins, loaded in order after Kickstart's core plugins.

-- VimTeX reads its settings when the plugin loads.
vim.g.vimtex_view_method = 'skim'
vim.pack.add { 'https://github.com/lervag/vimtex' }

-- Kickstart already sets up mini.icons from mini.nvim for Oil's icons.
vim.pack.add { 'https://github.com/stevearc/oil.nvim' }
require('oil').setup {
  keymaps = {
    ['l'] = { 'actions.select', desc = 'Enter directory' },
    ['h'] = { 'actions.parent', desc = 'Go up a directory' },
  },
}
vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory' })

vim.pack.add { 'https://github.com/notjedi/nvim-rooter.lua' }
require('nvim-rooter').setup {}

-- Slang supplies project-aware HDL diagnostics. A separate single-file Verilator
-- check reports missing modules even when Slang resolves them successfully.
