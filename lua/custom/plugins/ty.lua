-- ty.lua: Astral's ty Python type checker and language server
-- https://docs.astral.sh/ty/
--
-- PyCharm-style keybinds for Python LSP:
--   gd  = Go to Definition
--   gi  = Go to Implementation
--   gr  = Rename Element
--   gu  = Show Usages (Find References)
--   gk  = Show Error Description
--   gh  = Show Intention Actions (Code Actions)
--   gn  = Go to Next Error (already in init.lua)
--   gp  = Go to Previous Error (already in init.lua)
--   K   = Hover Documentation
--   <Leader>R = Refactorings (Code Actions)
--   <Leader>h = Show Error Description

-- Configure ty language server using Neovim 0.11+ native API
local function setup_ty()
  -- Only configure if ty is available
  if vim.fn.executable('ty') ~= 1 then
    vim.notify('ty not found in PATH. Install with: uv tool install ty', vim.log.levels.WARN)
    return
  end

  -- Configure ty language server
  vim.lsp.config('ty', {
    cmd = { 'ty', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'uv.lock', '.git' },
    settings = {
      ty = {
        -- Diagnostic settings
        diagnosticMode = 'openFilesOnly', -- or 'workspace' for all files

        -- Inlay hints (show types inline)
        inlayHints = {
          variableTypes = true,
          callArgumentNames = true,
        },

        -- Auto-import in completions
        completions = {
          autoImport = true,
        },
      },
    },
    init_options = {
      logLevel = 'info',
    },
  })

  -- Enable ty for Python files
  vim.lsp.enable('ty')
end

-- PyCharm-style keybinds for Python files (when ty attaches)
local function setup_keybinds()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('ty-python-keybinds', { clear = true }),
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client or client.name ~= 'ty' then
        return
      end

      local map = function(keys, func, desc)
        vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
      end

      -- Navigation (PyCharm style)
      map('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
      map('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
      map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
      map('gt', vim.lsp.buf.type_definition, '[G]oto [T]ype Definition')

      -- Usages and References (PyCharm: gu = ShowUsages)
      map('gu', vim.lsp.buf.references, '[G]oto [U]sages/References')

      -- Rename (PyCharm: gr = RenameElement)
      map('gr', vim.lsp.buf.rename, '[G]oto [R]ename')

      -- Code Actions (PyCharm: gh = ShowIntentionActions)
      map('gh', vim.lsp.buf.code_action, '[G]et [H]elp/Intentions (Code Actions)')
      map('<leader>R', vim.lsp.buf.code_action, '[R]efactorings')
      map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

      -- Diagnostics (PyCharm: gk = ShowErrorDescription)
      map('gk', vim.diagnostic.open_float, 'Show Error [K]')
      map('<leader>h', vim.diagnostic.open_float, 'Show Error [H]elp')

      -- Document Symbols (PyCharm: <Leader>s = FileStructurePopup)
      -- Note: <leader>s conflicts with substitution in init.lua, using <leader>ds instead
      local ok, telescope = pcall(require, 'telescope.builtin')
      if ok then
        map('<leader>ds', telescope.lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>ws', telescope.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
      else
        map('<leader>ds', vim.lsp.buf.document_symbol, '[D]ocument [S]ymbols')
        map('<leader>ws', vim.lsp.buf.workspace_symbol, '[W]orkspace [S]ymbols')
      end

      -- Hover Documentation
      map('K', vim.lsp.buf.hover, 'Hover Documentation')

      -- Signature Help in insert mode
      vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, {
        buffer = event.buf,
        desc = 'LSP: Signature Help',
      })

      -- Toggle inlay hints (if supported)
      if vim.lsp.inlay_hint then
        map('<leader>th', function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end, '[T]oggle Inlay [H]ints')
      end

      -- Document highlight on cursor hold
      if client.server_capabilities.documentHighlightProvider then
        local highlight_augroup = vim.api.nvim_create_augroup('ty-lsp-highlight', { clear = false })
        vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
          buffer = event.buf,
          group = highlight_augroup,
          callback = vim.lsp.buf.clear_references,
        })
      end
    end,
  })
end

-- Run setup immediately when this module is loaded
setup_ty()
setup_keybinds()

-- Return empty table (no lazy.nvim plugin spec needed)
return {}
