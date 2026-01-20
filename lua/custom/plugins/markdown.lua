-- Markdown utilities: image paste and code block wrappers
local vault_path = vim.fn.expand '~/repos/docs'

local M = {}

function M.wrap_python()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, { '```' })
  vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, { '```python' })
end

M.spec = {
  {
    'HakonHarnes/img-clip.nvim',
    event = 'VeryLazy',
    opts = {
      default = {
        dir_path = function()
          return vault_path .. '/static/images'
        end,
        relative_to_current_file = false,
        file_name = '%Y-%m-%d-%H-%M-%S',
        extension = 'png',
        prompt_for_file_name = false,
        use_absolute_path = false,
        insert_mode_after_paste = false,
      },
    },
    keys = {
      { '<leader>P', '<cmd>PasteImage<cr>', desc = '[P]aste image from clipboard' },
      { '<leader>C', "<esc><cmd>lua require('custom.plugins.markdown').wrap_python()<cr>", desc = 'Wrap in python [C]ode block', mode = 'v' },
    },
  },
}

return M.spec
