# rc.nvim

Forked from [modular kickstart.nvim](https://github.com/dam9000/kickstart-modular.nvim).

## Deploying

```sh
git clone https://github.com/JosBritton/rc.nvim.git ~/.config/nvim
```

For linters see:
    `lua/josbritton/plugins/lint.lua`

For formatters see:
    `lua/josbritton/plugins/conform.lua`

For LSPs see:
    `lua/josbritton/plugins/lspconfig.lua`

## Requirements

- 64-bit operating system[^2]

Dependencies:

- markdownlint
- yamllint
- make[^1][^2]
- stylua
- gopls
- shellcheck
- yarn[^3]
- rust-analyzer
- ripgrep/rg[^4]
- gcc *OR* clang[^1]
- fd[^5]
- npm (optional)[^6]

## Forking

- Rename your lua prefix (`lua/josbritton`) and edit `init.lua` to reference
your own prefix, you may also keep mine in-place as a reference as long as you
modify `init.lua` to include only your relevant config
- You can edit the colors for the included *Juliana* theme under
`./colors/juliana.lua` or install a theme as a plugin and change the theme under
`lua/josbritton/theme.lua`, this will disregard the included Juliana
- Of interest is `lua/josbritton/plugins/lspconfig.lua`, some of the LSPs I use
may not be useful to you or may require dependencies that you don't care to
install, you can disable them there

[^1]: For compiling native fzf C-port for telescope
[^2]: For building lua snippets
[^3]: For building markdown preview
[^4]: For telescope's grep functionality
[^5]: For telescope's find functionality
[^6]: For LSPs installed via Mason in `lua/josbritton/plugins/lspconfig.lua`
