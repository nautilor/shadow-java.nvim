-- shadow-java.nvim: Java/Spring/Quarkus workflow on top of nvim-java, nvim-dap and jdtls.

local M = {}

---@class ShadowJavaOpts
local defaults = {
	-- Passed to require("java").setup()
	java = {
		jdk = { auto_install = false },
		lombok = { enabled = true },
		java_test = { enabled = true },
		spring_boot_tools = { enabled = true },
		java_debug_adapter = { enabled = true },
	},

	root_markers = { ".git", "mvnw", "gradlew", "pom.xml", "build.gradle", "build.gradle.kts" },

	-- Runtimes handed to jdtls. Set `path` to match your system.
	runtimes = {
		{ name = "JavaSE-21", path = "/usr/lib/jvm/java-21-openjdk", default = true },
	},

	-- Deep-merged over the default jdtls `settings.java` table.
	jdtls_settings = {},

	-- Extra options for vim.lsp.config("jdtls", ...) (deep-merged).
	jdtls = {},

	dap = {
		keymaps = true, -- F5/F9/F10/F11/F12
		ui = true, -- nvim-dap-ui (<leader>du, <leader>de)
		virtual_text = true, -- nvim-dap-virtual-text
	},

	-- Register the `intellij_java` conform formatter and use it for java.
	formatter = true,
}

local function jdtls_java_settings(opts)
	return vim.tbl_deep_extend("force", {
		autobuild = { enabled = true },
		configuration = {
			updateBuildConfiguration = "automatic",
			runtimes = opts.runtimes,
		},
		import = { gradle = { annotationProcessing = { enabled = true } } },
		symbols = { includeGeneratedCode = true },
		gradle = { downloadSources = true },
		eclipse = { downloadSources = true },
		maven = { downloadSources = true },
	}, opts.jdtls_settings or {})
end

local function setup_jdtls(opts)
	require("java").setup(opts.java)

	vim.lsp.config("jdtls", vim.tbl_deep_extend("force", {
		root_dir = function(bufnr, on_dir)
			local root = vim.fs.root(vim.api.nvim_buf_get_name(bufnr), opts.root_markers)
			if root then
				on_dir(root)
			end
		end,
		settings = { java = jdtls_java_settings(opts) },
	}, opts.jdtls or {}))

	vim.lsp.enable("jdtls")
end

local function setup_dap(opts)
	local ok, dap = pcall(require, "dap")
	if not ok then
		vim.notify("shadow-java: nvim-dap not found", vim.log.levels.WARN)
		return
	end

	dap.adapters.java_attach = function(callback)
		dap.adapters.java(function(adapter)
			adapter = vim.deepcopy(adapter)
			adapter.enrich_config = nil
			callback(adapter)
		end)
	end

	if opts.dap.keymaps then
		local function k(lhs, fn, desc)
			vim.keymap.set("n", lhs, fn, { silent = true, desc = "Debug: " .. desc })
		end
		k("<F5>", dap.continue, "continue")
		k("<F9>", dap.toggle_breakpoint, "toggle breakpoint")
		k("<F10>", dap.step_over, "step over")
		k("<F11>", dap.step_into, "step into")
		k("<F12>", dap.step_out, "step out")
	end

	if opts.dap.ui then
		local ok_ui, dapui = pcall(require, "dapui")
		if ok_ui then
			dapui.setup({ floating = { border = "solid" } })
			dap.listeners.before.attach.dapui = dapui.open
			dap.listeners.before.launch.dapui = dapui.open
			dap.listeners.before.event_terminated.dapui = dapui.close
			dap.listeners.before.event_exited.dapui = dapui.close
			vim.keymap.set("n", "<leader>du", dapui.toggle, { silent = true, desc = "Debug: toggle UI" })
			vim.keymap.set("n", "<leader>de", dapui.eval, { silent = true, desc = "Debug: eval" })
		end
	end

	if opts.dap.virtual_text then
		local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
		if ok_vt then
			vt.setup({})
		end
	end
end

local function setup_formatter()
	local ok, conform = pcall(require, "conform")
	if not ok then
		return
	end

	conform.formatters.intellij_java = {
		inherit = false,
		command = function()
			return vim.fn.exepath("idea") ~= "" and "idea" or "idea.sh"
		end,
		args = { "format", "-allowDefaults", "$FILENAME" },
		stdin = false,
		cwd = function(_, ctx)
			return vim.fs.root(ctx.filename, { ".idea", ".editorconfig", ".git", "mvnw", "gradlew" })
		end,
		require_cwd = false,
		condition = function()
			return vim.fn.executable("idea") == 1 or vim.fn.executable("idea.sh") == 1
		end,
	}
	conform.formatters_by_ft.java = { "intellij_java", lsp_format = "fallback" }
end

function M.setup(opts)
	opts = opts or {}
	local user_runtimes = opts.runtimes
	opts = vim.tbl_deep_extend("force", defaults, opts)
	-- lists must replace, not merge by index
	opts.runtimes = user_runtimes or defaults.runtimes

	setup_jdtls(opts)
	setup_dap(opts)
	if opts.formatter then
		setup_formatter()
	end
	require("shadow_java.core").setup()
end

-- Used by snacks explorer "a" action: Java-aware file creation.
function M.explorer_add(picker)
	require("shadow_java.core").explorer_add(picker)
end

return M
