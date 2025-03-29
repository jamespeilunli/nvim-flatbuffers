# nvim-flatbuffers

Neovim plugin that redirects "go to definition" from FlatBuffers-generated C++ headers to FlatBuffer schemas.

Should work by default for the 971-Robot-Code Bazel codebase. To adapt for other codebases, change the configuration.

## Requirements

- Neovim
- clangd LSP
- nvim-lspconfig plugin (included with LazyVim)

## Installation

### LazyVim

Make a `.lua` file in `~/.config/nvim/lua/plugins`:
```lua
return {
  {
    "jamespeilunli/nvim-flatbuffers",
    event = "LspAttach",
    config = function()
      require("flatbuffers").setup()
    end,
  },
}
```

## Usage

- Open a C++ file that uses functions from a FlatBuffer generated `.h` file
- Use `gd` (go to definition) on a symbol from a FlatBuffer generated header (e.g. a table or a field).
- The plugin will redirect the definition lookup to the corresponding `.fbs` schema file.

## Configuration

Pass an object like this into `setup`. Default options are shown
```lua
require("flatbuffers").setup({
  debug = false,
  path_rules = {
    -- Used to match generated .h filenames to redirect from
    generated_file_pattern = "_generated%.h$",

    -- Used to match the full path of generated .h files
    -- This pattern is very lenient; I personally use "(.*)/%.cache/bazel/.*/bin/(.*)_generated%.h$"
    generated_path_pattern = "(.*)/%.cache/.*/bin/(.*)_generated%.h$",

    -- Represents the full path of the fbs file; substituted from generated_path_pattern
    -- Please use capture groups, e.g. "%1/971-Robot-Code/%2.fbs"
    fbs_substitution = nil, -- defaults to the root of the current git repository
  },
})
```

