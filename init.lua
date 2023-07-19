--- Options

-- vim = {}

vim.opt.backup = true
vim.opt.backupdir = os.getenv("HOME") .. "/.local/state/nvim/backups/"
vim.opt.cindent = true
vim.opt.clipboard = "unnamed"
vim.opt.completeopt = { "menu", "longest", "preview" }
vim.opt.encoding = "utf-8"
vim.opt.expandtab = true
vim.opt.ignorecase = true
vim.opt.laststatus = 2
vim.opt.list = true
vim.opt.listchars = "tab: ░,trail:·,nbsp:␣"
vim.opt.matchtime = 2
vim.opt.mouse = "n"
vim.opt.number = true
vim.opt.pumheight = 15
vim.opt.scrolloff = 8
vim.opt.shiftwidth = 4
vim.opt.showmatch = true
vim.opt.smartcase = true
vim.opt.softtabstop = 4
vim.opt.spelllang = en_us
vim.opt.statusline = " %f%m%= %y %{&fileencoding?&fileencoding:&encoding}[%{&fileformat}] %p%% %3.6l:%-4.6c"
vim.opt.tabstop = 4
vim.opt.textwidth = 120
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.wildmode = { "longest:full", "full" }

vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3

--- Keybindings

vim.api.nvim_set_keymap("n", "j", "gj", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "k", "gk", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<leader>s", ":<C-u>:set spell!<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "<C-c>", ":bd<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-j>", ":bn<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-k>", ":bp<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-\\>", ":b#<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<Space>", ":noh<CR>", { silent = true, noremap = true })
vim.api.nvim_set_keymap("c", "%%", "getcmdtype() == ':' ? expand('%:h').'/' : '%%'", { noremap = true, expr = true })
vim.api.nvim_set_keymap("v", "F", "Jgv:s,\\.\\s\\+,\\r,g<CR>:noh<CR>", { noremap = true })

--- Plugin setup

-- Packer

local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
        vim.cmd([[packadd packer.nvim]])
        return true
    end
    return false
end
local packer_bootstrap = ensure_packer()

-- Packer

require("packer").startup(function(use)
    use("wbthomason/packer.nvim")
    use({
        "williamboman/mason.nvim",
        run = ":MasonUpdate",
    })
    use("williamboman/mason-lspconfig.nvim")
    use("neovim/nvim-lspconfig")
    use("Mofiqul/dracula.nvim")
    use("Siphalor/vim-atomified")
    use("tpope/vim-commentary")
    use({
        "nvim-treesitter/nvim-treesitter",
        run = function()
            local ts_update = require("nvim-treesitter.install").update({ with_sync = true })
            ts_update()
        end,
    })
    use("lewis6991/gitsigns.nvim")
    use("hrsh7th/nvim-cmp")
    use('machakann/vim-highlightedyank')
    use("hrsh7th/cmp-nvim-lsp")
    use({
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
            require("null-ls").setup()
        end,
        requires = { "nvim-lua/plenary.nvim" },
    })
    use({
        "glepnir/lspsaga.nvim",
        config = function()
            require("lspsaga").setup()
        end,
        requires = {
            { "nvim-tree/nvim-web-devicons" },
            { "nvim-treesitter/nvim-treesitter" },
        },
    })
    use("WhoIsSethDaniel/toggle-lsp-diagnostics.nvim")
    use({
        "nvim-telescope/telescope-fzf-native.nvim",
        run =
        "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
    })
    use({
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        requires = {
            { "nvim-lua/plenary.nvim" },
        },
    })
    use({
        "jackMort/ChatGPT.nvim",
        config = function()
            require("chatgpt").setup()
        end,
        requires = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
    })

    use("RRethy/vim-illuminate")

    if packer_bootstrap then
        require("packer").sync()
    end
end)

--- Language server configuration

require("illuminate").configure({ delay = 333 })

require("gitsigns").setup()
require("toggle_lsp_diagnostics").init(vim.diagnostic.config())
require("mason").setup()

require("mason-lspconfig").setup({
    ensure_installed = {
        "pyright",
        "jsonls",
        "lua_ls",
        "yamlls",
    },
})

local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
lspconfig["pyright"].setup({ capabilities = capabilities })
lspconfig["jsonls"].setup({ capabilities = capabilities })
lspconfig["lua_ls"].setup({ capabilities = capabilities })
lspconfig["yamlls"].setup({ capabilities = capabilities, settings = { yaml = { keyOrdering = false } } })

require("lspsaga").setup({ request_timeout = 5000 })

local cmp = require("cmp")
cmp.setup({
    mapping = cmp.mapping.preset.insert({
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
    sources = {
        { name = "nvim_lsp" },
    },
})

local null_ls = require("null-ls")
null_ls.setup({
    sources = {
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.isort,
        null_ls.builtins.formatting.jq,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.yamlfmt,
    },
})

require("gitsigns").setup({
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end
    end,
})

--- Language server configuration on attach

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
        --        vim.bo[ev.buf].formatexpr = nil  -- make `gq` work for line wrapping

        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gh", "<cmd>Lspsaga lsp_finder<CR>")
        vim.keymap.set("n", "<space>ca", "<cmd>Lspsaga code_action<CR>")
        vim.keymap.set("n", "gd", "<cmd>Lspsaga goto_definition<CR>")
        vim.keymap.set("n", "<space>o", "<cmd>Lspsaga outline<CR>")
        vim.keymap.set("n", "<space>ci", "<cmd>Lspsaga incoming_calls<CR>")
        vim.keymap.set("n", "<space>co", "<cmd>Lspsaga outgoing_calls<CR>")
        vim.keymap.set("n", "<space><space>", "<cmd>ToggleDiag<CR><cmd>noh<CR>", { silent = true, noremap = true })
        vim.keymap.set({ "n", "t" }, "<space>t", "<cmd>Lspsaga term_toggle<CR>")
        vim.keymap.set("n", "<space>f", function()
            vim.lsp.buf.format({ async = true })
        end, opts)

        local gs = package.loaded.gitsigns
        vim.keymap.set("n", "<space>b", gs.toggle_current_line_blame)
        vim.keymap.set("n", "<space>d", gs.toggle_deleted)
    end,
})

--- Save new backups each time

vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("timestamp_backupext", { clear = true }),
    desc = "Add timestamp to backup extension",
    pattern = "*",
    callback = function()
        vim.opt.backupext = "__" .. vim.fn.strftime("%Y%m%d%H%M%S")
    end,
})

--- Other key bindings

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})

--- Colorscheme

vim.cmd([[
colorscheme atomified
match ErrorMsg '[^\d0-\d127]'
]])
