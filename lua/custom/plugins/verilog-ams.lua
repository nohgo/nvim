if vim.g.enable_verilog_ams == false then return end

local ams_lsp = require 'custom.plugins.vams-lsp'
vim.pack.add { { src = 'https://github.com/nohgo/tree-sitter-verilog-ams', version = 'main' } }
require('verilog_ams').setup {
  -- The existing Tree-sitter FileType callback owns highlighting.
  highlight = false,
  -- One syntax diagnostic owner; retain the grammar fallback without the LSP.
  diagnostics = not ams_lsp.available(),
}

local conform = require 'conform'
conform.formatters.vamsfmt = { command = vim.fn.executable 'vamsfmt' == 1 and 'vamsfmt' or vim.fn.expand '~/.cargo/bin/vamsfmt', stdin = true }
conform.formatters_by_ft.verilogams = { 'vamsfmt', lsp_format = 'never' }
ams_lsp.setup()
