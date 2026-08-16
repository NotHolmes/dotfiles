return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,        -- plugin docs: does not support lazy-loading
    build = ":TSUpdate", -- keep parsers in sync with plugin version

    config = function()
      -- Treesitter-based highlighting for Python
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "python" },
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    lazy = false,

    config = function()
      vim.lsp.config("basedpyright", {
        settings = {
          basedpyright = {
            analysis = {
              typeCheckingMode = "recommended",
            },
          },
        },
      })

      vim.lsp.enable("basedpyright")
    end,

    keys = {
      {
        "<leader>d",
        vim.diagnostic.open_float,
        desc = "Show diagnostic",
      },
    },
  }
}
