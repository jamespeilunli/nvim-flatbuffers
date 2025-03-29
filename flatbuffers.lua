-- ~/.config/nvim/lua/plugins/flatbuffers.lua
local M = {}

local DEBUG = false
local LOG_LEVEL = DEBUG and vim.log.levels.DEBUG or vim.log.levels.INFO

local target_symbol = nil -- Internal variable for storing the target symbol

local function log(message, ...)
  if DEBUG then
    vim.notify(("[FB] " .. message):format(...), LOG_LEVEL)
  end
end

local function convert_generated_path_to_fbs(generated_path)
  local fbs_path =
    generated_path:gsub("(.*)/%.cache/bazel/.*/bazel%-out/k8%-opt/bin/(.*)_generated%.h$", "%1/971-Robot-Code/%2.fbs")

  return vim.fn.resolve(fbs_path)
end

local function find_symbol_in_fbs(symbol)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local table_pattern = "table%s+([%w_]+)"
  local field_pattern = ("%s%%s*:"):format(symbol)

  local current_table = nil
  local best_match = nil

  for i, line in ipairs(lines) do
    -- Track current table context
    local table_match = line:match(table_pattern)
    if table_match then
      current_table = table_match
      log("Entering table: %s", current_table)
    end

    -- Look for field definition
    if line:find(field_pattern) then
      log("Found field candidate in table %s at line %d: %s", current_table or "global", i, line)

      -- Prioritize matches in the most specific table context
      if not best_match or current_table then
        best_match = { line = i - 1, col = line:find(symbol) - 1 }
      end
    end
  end

  return best_match or { line = 0, col = 0 }
end

function M.definition_handler(err, result, ctx, config)
  if err or not result then
    return vim.lsp.handlers[ctx.method](err, result, ctx, config)
  end

  result = vim.islist(result) and result or { result }
  local fbs_locations = {}
  local has_generated = false

  for _, loc in ipairs(result) do
    local uri = loc.targetUri or loc.uri
    if uri then
      local file_path = vim.uri_to_fname(uri)
      log("Processing: %s", file_path)
      if file_path:match("_generated%.h$") then
        has_generated = true
        local fbs_path = convert_generated_path_to_fbs(file_path)
        if vim.fn.filereadable(fbs_path) == 1 then
          table.insert(fbs_locations, {
            uri = vim.uri_from_fname(fbs_path),
            range = {
              start = { line = 0, character = 0 },
              ["end"] = { line = 0, character = 0 },
            },
            -- Store symbol for later search.
            _custom_data = { symbol = target_symbol },
          })
          log("Found FBS file: %s", fbs_path)
        else
          log("Missing FBS file: %s", fbs_path)
        end
      else
        table.insert(fbs_locations, loc)
      end
    end
  end

  if has_generated and #fbs_locations > 0 then
    local fbs_uri = fbs_locations[1].uri
    local symbol = fbs_locations[1]._custom_data.symbol

    -- Open the fbs file first
    vim.lsp.util.jump_to_location(fbs_locations[1], ctx.client_id)

    -- Then search for the symbol in the new buffer
    vim.schedule(function()
      local bufnr = vim.uri_to_bufnr(fbs_uri)
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local pos = find_symbol_in_fbs(symbol)
        vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.col })
        log("Jumped to %s:%d:%d", fbs_uri, pos.line, pos.col)
      end
    end)

    return
  end

  return vim.lsp.handlers[ctx.method](err, result, ctx, config)
end

local function go_to_fbs_or_definition()
  target_symbol = vim.fn.expand("<cword>") -- Capture symbol under cursor
  log("Looking for symbol: %s", target_symbol)

  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, "textDocument/definition", params, function(...)
    M.definition_handler(...)
  end)
end

function M.setup()
  require("lspconfig").clangd.setup({
    capabilities = require("lazyvim.util").lsp.capabilities,
    on_attach = function(client, bufnr)
      require("lazyvim.util").lsp.on_attach(client, bufnr)

      if vim.bo[bufnr].filetype == "cpp" then
        vim.keymap.set("n", "gd", go_to_fbs_or_definition, {
          buffer = bufnr,
          desc = "Go to FBS field definition",
        })
        log("Configured for buffer %d", bufnr)
      end
    end,
  })
end

return {
  "neovim/nvim-lspconfig",
  event = "LspAttach",
  config = M.setup,
}
