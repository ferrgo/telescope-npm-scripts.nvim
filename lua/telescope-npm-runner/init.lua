local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local actions = require('telescope.actions')
local actions_state = require('telescope.actions.state')
local utils = require('telescope.previewers.utils')
local config = require('telescope.config').values

local Logger = require('plenary.log'):new()
Logger.level = 'debug'

local M = {}

M.npm_runner = function(opts)
    pickers.new(opts, {
        prompt_title = 'NPM Runner',
        finder = finders.new_async_job({
            command_generator = function()
                return { "jq", "-r", ".scripts|to_entries|map(\"\\(.key)=\\(.value|tostring)\")|.[]", "package.json" }
            end,
            entry_maker = function(entry)
                Logger.debug(vim.split(entry, "="))
                local data = {
                    name = vim.split(entry, "=")[1],
                    command = vim.split(entry, "=")[2]
                }
                return {
                    value = data,
                    display = data.name,
                    ordinal = data.name,
                }
            end
        }),

        sorter = config.generic_sorter(opts),

        previewer = previewers.new_buffer_previewer({
            title = 'NPM Runner',
            define_preview = function(self, entry)
                vim.api.nvim_buf_set_lines(
                    self.state.bufnr,
                    0,
                    0,
                    true,
                    vim.tbl_flatten({
                        "# Script " .. entry.display,
                        "```bash",
                        entry.value.command,
                        "```",
                        "```json",
                        vim.split(vim.inspect(entry.value), "\n"),
                        "```"
                    })
                )
                utils.highlighter(self.state.bufnr, 'markdown')
            end,
        }),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selected = actions_state.get_selected_entry()
                actions.close(prompt_bufnr)
                local npm_run_cmd = "run " .. selected.value.name
                local command = {
                    "edit",
                    "term://npm",
                    npm_run_cmd
                }
                vim.cmd(vim.fn.join(command))
            end)
            return true
        end
    }):find()
end

M.npm_runner()

return M
