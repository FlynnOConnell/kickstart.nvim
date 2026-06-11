-- Markdown utilities: image paste, video paste, and code block wrappers
local vault_path = vim.fn.expand '~/repos/docs'
local video_extensions = { 'mp4', 'webm', 'mov', 'avi' }

local M = {}

function M.wrap_python()
  local start_line = vim.fn.line "'<"
  local end_line = vim.fn.line "'>"
  vim.api.nvim_buf_set_lines(0, end_line, end_line, false, { '```' })
  vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, { '```python' })
end

--- check clipboard for a file path pointing to a video
function M.get_clipboard_video()
  local clip = vim.fn.getreg '+'
  if not clip or clip == '' then
    return nil
  end
  -- trim whitespace and quotes
  clip = clip:gsub('^%s+', ''):gsub('%s+$', ''):gsub('^"', ''):gsub('"$', '')
  local ext = clip:match '%.(%w+)$'
  if not ext then
    return nil
  end
  for _, v in ipairs(video_extensions) do
    if ext:lower() == v then
      -- verify file exists
      if vim.fn.filereadable(clip) == 1 then
        return clip
      end
    end
  end
  return nil
end

--- paste video: copy to static/videos and insert obsidian embed
function M.paste_video(src_path)
  local videos_dir = vault_path .. '/static/videos'
  vim.fn.mkdir(videos_dir, 'p')
  local filename = vim.fn.fnamemodify(src_path, ':t')
  local dest = videos_dir .. '/' .. filename
  if vim.fn.filereadable(dest) == 0 then
    vim.fn.system { 'cp', src_path, dest }
  end
  local embed = '![[' .. filename .. ']]'
  vim.api.nvim_put({ embed }, 'l', true, true)
end

--- smart paste: video if clipboard has a video path, otherwise image
function M.smart_paste()
  local video_path = M.get_clipboard_video()
  if video_path then
    M.paste_video(video_path)
  else
    vim.cmd 'PasteImage'
  end
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
      { '<leader>V', function() require('custom.plugins.markdown').smart_paste() end, desc = 'Paste image or [V]ideo from clipboard' },
      { '<leader>C', "<esc><cmd>lua require('custom.plugins.markdown').wrap_python()<cr>", desc = 'Wrap in python [C]ode block', mode = 'v' },
    },
  },
}

return M.spec
