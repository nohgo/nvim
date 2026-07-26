-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'lervag/vimtex',
    lazy = false, -- we don't want to lazy load VimTeX
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = 'skim'
    end,
  },

  {
    'stevearc/oil.nvim',
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      -- These are your internal Oil keymaps
      keymaps = {
        ['l'] = { 'actions.select', desc = 'Enter directory' },
        ['h'] = { 'actions.parent', desc = 'Go up a directory' },
      },
    },
    -- Optional dependencies
    dependencies = { { 'nvim-mini/mini.icons', opts = {} } },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    keys = {
      -- This is your global keymap to open Oil
      { '-', '<CMD>Oil<CR>', desc = 'Open parent directory' },
    },
  },
  { -- Asynchronous Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      lint.linters_by_ft = {
        verilog = { 'verilator' },
        systemverilog = { 'verilator' },
      }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
  {
    'notjedi/nvim-rooter.lua',
    lazy = false, -- Explicitly disabled as recommended by the author
    config = function()
      require('nvim-rooter').setup {
        -- Your configuration options go here
      }
    end,
  },
}
