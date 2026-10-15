if vim.g.enable_verilog_ams == false then return end

vim.pack.add { { src = 'https://github.com/nohgo/tree-sitter-verilog-ams', version = 'main' } }
require('verilog_ams').setup {
  -- The existing Tree-sitter FileType callback owns highlighting.
  highlight = false,
  diagnostics = true,
}

local conform = require 'conform'
conform.formatters.vamsfmt = { command = vim.fn.executable 'vamsfmt' == 1 and 'vamsfmt' or vim.fn.expand '~/.cargo/bin/vamsfmt', stdin = true }
conform.formatters_by_ft.verilogams = { 'vamsfmt', lsp_format = 'never' }
