return {
  {
    'NeogitOrg/neogit',
    dependencies = { 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
    keys = { { '<leader>g', function() require('neogit').open() end, desc = 'Neogit' } },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufWinEnter',
    opts = { 
      current_line_blame = true,-- who last touched this line
    },
    keys = {
      {
        '<leader>hi',
        function()
          require('gitsigns').preview_hunk_inline()
        end,
        desc = 'Preview git hunk inline',
      },
      {
        '<leader>hp',
        function()
          require('gitsigns').preview_hunk()
        end,
        desc = 'Popup diff',
      },
    },
  }
}
