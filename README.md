# nvim-flatbuffers

Neovim plugin that redirects "go to definition" from FlatBuffers-generated C++ headers to FlatBuffer schemas.

Made specifically for the 971-Robot-Code Bazel codebase. To adapt for other codebases, modify the path conversion in the `convert_generated_path_to_fbs` function.

## Installation

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
- Use `gd` (go to definition) on a symbol from a FlatBuffer-generated header.
- The plugin will redirect the definition lookup to the corresponding `.fbs` schema file.

## Requirements

- LazyVim
- clangd LSP
- nvim-lspconfig plugin (included with LazyVim)

