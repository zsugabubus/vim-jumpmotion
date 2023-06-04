-- XXX: vim.cmd() does not work in all cases. Use api.nvim_command() instead.
local M = {}
local ns = vim.api.nvim_create_namespace('jumpmotion')

local function update_highlights()
	vim.api.nvim_set_hl(0, 'JumpMotionHead', {
		default = true,
		bold = true,
		ctermfg = 196,
		ctermbg = 226,
		fg = '#ff0000',
		bg = '#ffff00',
	})
	vim.api.nvim_set_hl(0, 'JumpMotionTail', {
		default = true,
		ctermfg = 196,
		ctermbg = 226,
		fg = '#ff0000',
		bg = '#ffff00',
	})
end

local function update_extmarks(targets)
	for _, target in ipairs(targets) do
		target.extmark_id = vim.api.nvim_buf_set_extmark(
			target.buf,
			ns,
			target.line - 1,
			target.col,
			{
				id = target.extmark_id,
				virt_text = {
					{string.sub(target.key, 1, 1), 'JumpMotionHead'},
					-- Empty virtual text makes Nvim confused.
					#target.key > 1
						and {string.sub(target.key, 2), 'JumpMotionTail'}
						or nil,
				},
				virt_text_pos = 'overlay',
				priority = 1000 + #targets
			}
		)
	end
end

local function generate_word(n)
	local word = ''
	local a, z = string.byte('a'), string.byte('z')
	local len = z - a + 1
	local k = n
	while k > 0 do
		k = k - 1
		word = string.char(a + k % len) .. word
		k = math.floor(k / len)
	end
	return word
end

local function generate_keys(targets)
	local target_by_key = {}

	local n = 1
	for _, target in ipairs(targets) do
		while true do
			local key = generate_word(n)
			n = n + 1

			local conflict = target_by_key[string.sub(key, 1, -2)]
			if conflict then
				target_by_key[conflict.key] = nil
				conflict.key = key
				target_by_key[conflict.key] = conflict
			else
				target.key = key
				target_by_key[key] = target
				break
			end
		end
	end
end

local function choose_target(targets)
	update_highlights()

	while #targets > 1 do
		update_extmarks(targets)

		vim.api.nvim_echo({
			{
				string.format('jumpmotion (%d targets): ', #targets),
				'Question',
			},
		}, false, {})
		vim.cmd.redraw()

		local ok, nr = pcall(vim.fn.getchar)
		local char = ok and vim.fn.nr2char(nr) or ' '

		vim.api.nvim_echo({
			{'', 'Normal'},
		}, false, {})

		local new_targets = {}
		for _, target in ipairs(targets) do
			if string.sub(target.key, 1, #char) == char then
				target.key = string.sub(target.key, #char + 1)
				table.insert(new_targets, target)
			else
				vim.api.nvim_buf_del_extmark(target.buf, ns, target.extmark_id)
			end
		end
		targets = new_targets
	end

	local target = targets[1]
	if not target then
		vim.api.nvim_echo({
			{'jumpmotion: No matches.', 'ErrorMsg'},
		}, false, {})
		return
	end

	-- Single target will have no extmark set.
	if target.extmark_id ~= nil then
		vim.api.nvim_buf_del_extmark(target.buf, ns, target.extmark_id)
	end

	return target
end

local function generate_targets(cmd, opts)
	if type(cmd) == 'string' then
		local s = 'noautocmd keepjumps keeppattern silent ' .. cmd
		cmd = function()
			return vim.api.nvim_command(s)
		end
	end

	opts = vim.tbl_extend('force', {
		top = false,
		above_top = false,
		tab = true,
	}, opts or {})

	local targets = {}
	local targets_set = {}

	local saved_scrolloff = vim.o.scrolloff
	vim.o.scrolloff = 0

	local cur_win, cur_line, cur_col =
		vim.api.nvim_get_current_win(),
		unpack(vim.api.nvim_win_get_cursor(0))

	local function add_win_targets()
		local view = vim.fn.winsaveview()
		view.bottomline = vim.fn.line('w$')
		view.rightcol = view.leftcol + vim.fn.winwidth(0) - 1

		local opt_wrap = vim.o.wrap

		if opts.top or opts.above_top then
			vim.api.nvim_win_set_cursor(0, {
				math.max(view.topline + (opts.above_top and -1 or 0), 1),
				0,
			})
		end

		local prev_line, prev_col

		while true do
			if not pcall(cmd) then
				break
			end

			local win = vim.api.nvim_get_current_win()
			local buf = vim.api.nvim_win_get_buf(win)
			local line, col = unpack(vim.api.nvim_win_get_cursor(0))

			-- Do not add same target twice. Also to avoid infinite loops.
			local target_id = string.format('%d:%d:%d', buf, line, col)
			if targets_set[target_id] then
				break
			end
			targets_set[target_id] = true

			-- Skip non-visible portion of a line.
			if not opt_wrap then
				if col < view.leftcol then
					if prev_line == line then
						vim.api.nvim_win_set_cursor(0, {
							line,
							prev_col <= col and view.leftcol or 0
						})
					end
					goto continue
				end

				if view.rightcol < col then
					if prev_line == line then
						vim.api.nvim_win_set_cursor(0, {
							line,
							prev_col <= col and 999999 or view.rightcol
						})
					end
					goto continue
				end
			end

			-- Finish when out of the viewport on the top or on the bottom.
			if
				line < view.topline or
				view.bottomline < line
			then
				break
			end

			-- Skip initial cursor position.
			if
				win == cur_win and
				line == cur_line and
				col == cur_col
			then
				goto continue
			end

			table.insert(targets, {
				win = win,
				buf = buf,
				line = line,
				col = col,
			})

			::continue::
			prev_line, prev_col = line, col
		end

		vim.fn.winrestview(view)
	end

	-- Current window first.
	add_win_targets()

	if opts.tab then
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			if win ~= cur_win then
				vim.api.nvim_win_call(win, add_win_targets)
			end
		end
	end

	vim.o.scrolloff = saved_scrolloff

	return targets
end

local last_jump_args
function M.jump(...)
	local mode = vim.fn.mode()

	local targets = generate_targets(...)
	generate_keys(targets)

	vim.cmd.nohlsearch()

	-- Set them after targets have been generated to avoid interfering with ".".
	vim.o.opfunc = 'v:lua._jumpmotion_noop'
	vim.api.nvim_command('silent! normal! g@:\n')
	vim.o.opfunc = 'v:lua._jumpmotion_repeat'
	last_jump_args = {...}

	local target = choose_target(targets)
	if not target then
		return false
	end

	-- Push current location to jumplist.
	vim.api.nvim_command("normal! m'")

	vim.api.nvim_set_current_win(target.win)
	vim.api.nvim_win_set_cursor(target.win, {target.line, target.col})

	if mode == 'v' or mode == 'V' then
		vim.api.nvim_command('normal! m>gv')
	end

	return true
end

function M.bounce(cmd, there, here, opts)
	local count = vim.v.count1
	if M.jump(cmd, opts or { top = true }) then
		vim.api.normal { bang = true, args = { string.format(there, count) } }
		vim.cmd.normal { bang = true, args = { [[\<C-o>]] } }
		vim.api.nvim_command(here)
	end
end

function _G._jumpmotion_noop()
	-- Do nothing. Really.
end

function _G._jumpmotion_repeat()
	M.jump(unpack(last_jump_args))
end

return M
