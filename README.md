# Navi

> Simple plugin (with 'complex' config) which helps to jump to next or previous of a specific chosen context all with the same keybinds.

## Example

- I am working on code, creating new entries. Im using gitsigns to jump from one entry to the next with M-j and M-k.
- Suddendly I have to debug somthing in that code, I switch context to DAPDEBUG and jump through the code with M-j and M-k.
- I need to search for occurences of all `const test`. Open fzf and add all matches to my quickfix list, switch context to the quickfix list and jump from one to the other with M-j and M-k.

## Pro

- Jump to prev/next occurence with the same keymaps, for as many context as preffered.
- M-j and M-k are ergonomical, and jumping between prev and next
- Depending on the plugins you like, you can create as many contexts as you want and use fuzzy finder to switch.

## Con

- Jumping around might not be your style and regular `[x` and `]x` combo's are native to vim.
- Switching context takes a couple of keystrokes extra compared to `[x` and `]x`.

## Example config (lazy)

```lua
{

    ----------
    -- NAVI --
    ----------

    "mattiasbonte/navi.nvim",

    --

    cmd = "Navi",
    event = "BufRead",
    config = function()
        -- focus scrolling to zz, zt or zb after an action
        local function DeferScrollAction(action, scrollType, timeMs)
            timeMs = timeMs or 8
            scrollType = scrollType or "zz"

            if type(action) == "function" then
                action()
            end

            if scrollType == nil then
                return
            end
            vim.defer_fn(function()
                vim.cmd("normal! " .. scrollType)
            end, timeMs)
        end

        -- notify user
        local function notifyUser(message, icon, title, logLevel, timeout)
            local notify = require("notify")

            local vimLogLevel
            if logLevel == "ERROR" then
                vimLogLevel = vim.log.levels.ERROR
            elseif logLevel == "WARN" then
                vimLogLevel = vim.log.levels.WARN
            elseif logLevel == "DEBUG" then
                vimLogLevel = vim.log.levels.DEBUG
            elseif logLevel == "TRACE" then
                vimLogLevel = vim.log.levels.TRACE
            else
                vimLogLevel = vim.log.levels.INFO
            end

            notify.dismiss()
            notify(message, vimLogLevel, {
                title = title,
                icon = icon,
                timeout = timeout or 5000,
                hide_from_history = true,
            })
        end

        -- Execute a quickfix or location list vim command
        local function execListCommand(type, command)
            local title, icon
            if type == "quickfix" then
                title = "Fix"
                icon = "🐇"
                if vim.tbl_isempty(vim.fn.getqflist()) then
                    -- notifyUser("No quickfix list", icon, title, "INFO", 250)
                    return
                end
            elseif type == "location" then
                title = "Loc"
                icon = ""
                if vim.tbl_isempty(vim.fn.getloclist(0)) then
                    -- notifyUser("No locations", icon, title, "INFO", 250)
                    return
                end
            end

            local success, err = pcall(vim.api.nvim_command, command)
            if not success then
                notifyUser(err, icon, title, "INFO", 250)
            end
        end

        -- get file name and last part of the folder
        local function getFileShortPath()
            local full_path = vim.fn.expand("%")
            local filename = vim.fn.fnamemodify(full_path, ":t")
            local last_folder = vim.fn.fnamemodify(full_path, ":p:h:t")

            return last_folder .. "/" .. filename
        end

        local gitHunks = "GITHUNKS 擄"
        local gitConflicts = "GITCONFLICTS 💣"
        local quickfixList = "QUICKFIX 🐇"
        local locationList = "LOCATION  "
        local dap = "DEBUGDAP  "
        local harpoon = "HARPOON ﯠ"
        local diagnostics = "DIAGNOSTICS 🩹"

        require("navi").setup({
            persistContext = false, -- save context between sessions
            enableTriggers = true, -- enable trigger key

            mappings = {
                next = "<M-j>",
                prev = "<M-k>",
                alt1 = "<M-h>",
                alt2 = "<M-l>",
            },

            active = {
                gitHunks,
                harpoon,
                quickfixList,
                dap,
                diagnostics,
                gitConflicts,
                locationList,
                -- ["lsp_references"] = true,
            },

            triggers = {
                ["d"] = diagnostics,
                ["h"] = gitHunks,
                ["H"] = harpoon,
                ["q"] = quickfixList,
                ["l"] = locationList,
                ["c"] = gitConflicts,
                ["n"] = dap,
            },

            contexts = {
                [quickfixList] = {
                    next = function()
                        execListCommand("quickfix", "cnext")
                    end,
                    prev = function()
                        execListCommand("quickfix", "cprev")
                    end,
                    alt1 = function()
                        execListCommand("quickfix", "colder")
                    end,
                    alt2 = function()
                        execListCommand("quickfix", "cnewer")
                    end,
                },
                [locationList] = {
                    next = function()
                        execListCommand("location", "lnext")
                    end,
                    prev = function()
                        execListCommand("location", "lprev")
                    end,
                    alt1 = function()
                        execListCommand("location", "lolder")
                    end,
                    alt2 = function()
                        execListCommand("location", "lnewer")
                    end,
                },
                [gitHunks] = {
                    next = function()
                        DeferScrollAction(require("gitsigns").next_hunk(), "zz")
                    end,
                    prev = function()
                        DeferScrollAction(require("gitsigns").prev_hunk(), "zz")
                    end,
                    alt1 = function()
                        require("gitsigns").undo_stage_hunk()
                    end,
                    alt2 = function()
                        require("gitsigns").stage_hunk()
                    end,
                },
                [diagnostics] = {
                    next = function()
                        DeferScrollAction(vim.diagnostic.goto_next(), "zz")
                    end,
                    prev = function()
                        DeferScrollAction(vim.diagnostic.goto_prev(), "zz")
                    end,
                    alt1 = function()
                        vim.lsp.buf.code_action()
                    end,
                    alt2 = function()
                        vim.lsp.buf.code_action()
                    end,
                },
                [gitConflicts] = {
                    next = function()
                        DeferScrollAction(require("diffview.actions").next_conflict(), "zz")
                        notifyUser("Next Conflict", "", "Git", "INFO", 500)
                    end,
                    prev = function()
                        DeferScrollAction(require("diffview.actions").prev_conflict(), "zz")
                        notifyUser("Prev Conflict", "", "Git", "INFO", 500)
                    end,
                    alt1 = function()
                        require("diffview.actions").conflict_choose("ours")
                        notifyUser("Chose OURS", "", "Git", "INFO", 500)
                    end,
                    alt2 = function()
                        require("diffview.actions").conflict_choose("theirs")
                        notifyUser("Chose THEIRS", "", "Git", "INFO", 500)
                    end,
                },
                [harpoon] = {
                    next = function()
                        require("harpoon.ui").nav_next()
                        notifyUser(getFileShortPath(), "ﯠ", "👇", "INFO", 500)
                    end,
                    prev = function()
                        require("harpoon.ui").nav_prev()
                        notifyUser(getFileShortPath(), "ﯠ", "👆", "INFO", 500)
                    end,
                    alt1 = function()
                        local Mark = require("harpoon.mark")
                        local filePath = vim.fn.expand("%:p")
                        local fileName = vim.fn.expand("%:t")

                        require("harpoon.mark").add_file()

                        -- notify
                        local succuss, index = pcall(Mark.get_index_of, filePath)
                        if succuss and index and index > 0 then
                            notifyUser("#" .. index .. " - " .. fileName, "ﯠ", "Mark", "INFO")
                        end
                    end,
                    alt2 = function()
                        require("harpoon.ui").toggle_quick_menu()
                    end,
                },
                [dap] = {
                    next = function()
                        DeferScrollAction(require("dap").step_over(), "zz")
                    end,
                    prev = function()
                        DeferScrollAction(require("dap").step_into(), "zz")
                    end,
                    alt1 = function()
                        require("dap.ui.widgets").hover()
                    end,
                    alt2 = function()
                        require("dap.ui.widgets").hover()
                    end,
                },
            },
        })
    end,
    keys = {
        {
            "<M-e>",
            mode = { "n" },
            function()
                require("navi").select()
            end,
        },
    },
},
,
```
