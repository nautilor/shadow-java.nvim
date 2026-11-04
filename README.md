# shadow-java.nvim

Java/Spring/Quarkus workflow for Neovim on top of `nvim-java`, `nvim-dap` and jdtls.

Provides: `:JavaRun`, `:JavaRunSpring`, `:JavaRunQuarkus`, `:JavaRunTests`, `:JavaToggleConsole`,
`:JavaStop`, `:JavaSelectProfile`, `:JavaAttachDebugger`, `:JavaDebugMain`, `:JavaBuildWorkspace`,
`:JavaRefreshMappers`, buffer keymaps (`<leader>j*`, `<leader>d*`), DAP keymaps/UI, MapStruct
auto-rebuild, Java-aware snacks explorer file creation, IntelliJ conform formatter.

## lazy.nvim

```lua
{
  "nautilor/shadow-java.nvim",
  ft = "java",
  cmd = { "JavaRun", "JavaRunSpring", "JavaRunQuarkus", "JavaRunTests" },
  dependencies = {
    "neovim/nvim-lspconfig",
    "nvim-java/nvim-java",
    "MunifTanjim/nui.nvim",
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
    { "JavaHello/spring-boot.nvim", commit = "218c0c26c14d99feca778e4d13f5ec3e8b1b60f0" },
  },
  opts = {
    runtimes = { { name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk", default = true } },
  },
}
```

## Options

See `defaults` in `lua/shadow_java/init.lua`: `java`, `root_markers`, `runtimes`,
`jdtls_settings`, `jdtls`, `dap = { keymaps, ui, virtual_text }`, `formatter`.

Snacks explorer integration: `require("shadow_java").explorer_add(picker)`.
