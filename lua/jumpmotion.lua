-- XXX: vim.cmd() does not work in all cases. Use api.nvim_command() instead.

local api = vim.api
local ns = api.nvim_create_namespace('jumpmotion')

local function getchar()
	local nr = vim.fn.getchar()
	if nr == 27 then
		error('user interrupted')
	end
	return vim.fn.nr2char(nr)
end

local function update_extmarks(targets)
	for _, target in ipairs(targets) do
		target.extmark_id = api.nvim_buf_set_extmark(
			target.buf,
			ns,
			target.line - 1,
			target.col,
			{
				id = target.extmark_id,
				virt_text = {
					{target.key:sub(1, 1), 'JumpMotionHead'},
					-- Empty virtual text makes Nvim confused.
					1 < #target.key and {target.key:sub(2), 'JumpMotionTail'} or nil,
				},
				virt_text_pos = 'overlay',
				priority = 1000 + #targets
			}
		)
	end
end

local function generate_keys(targets)
	local a, z = string.byte('a'), string.byte('z')
	local n = 1
	for _, target in ipairs(targets) do
		local k = n
		n = n + 1
		target.key = ''
		while 0 < k do
			k = k - 1
			target.key = string.char(a + k % (z - a + 1)) .. target.key
			k = math.floor(k / (z - a + 1))
		end
	end
end

local function choose_target(targets)
	while 1 < #targets do
		update_extmarks(targets)
		vim.cmd.echon(('"jumpmotion: (%d targets)"'):format(#targets))
		vim.cmd.redraw()

		local ok, char = pcall(getchar)
		if not ok then
			char = '?'
		end

		vim.cmd.echomsg('""')

		local old_targets = targets
		targets = {}
		for _, target in ipairs(old_targets) do
			if target.key:sub(1, #char) == char then
				target.key = target.key:sub(#char + 1)
				if target.key == '' then
					target.key = ' '
				end
				targets[#targets + 1] = target
			else
				api.nvim_buf_del_extmark(target.buf, ns, target.extmark_id)
			end
		end
	end

	local target = targets[1]
	if not target then
		vim.cmd [[
			echohl ErrorMsg
			echo "jumpmotion: No matches."
			echohl None
		]]
		return
	end

	if target.extmark_id ~= nil then
		api.nvim_buf_del_extmark(target.buf, ns, target.extmark_id)
	end
	return target
end

local function generate_targets(cmd, opts)
	opts = opts or {}
	local targets = {}

	local o_scrolloff = vim.o.scrolloff
	vim.o.scrolloff = 0

	local cur_win, cur_line, cur_col =
		api.nvim_get_current_win(),
		unpack(api.nvim_win_get_cursor(0))

	local target_set = {}

	local function add_win_targets()
		local view = vim.fn.winsaveview()
		view.bottomline = vim.fn.line('w$')
		view.rightcol = view.leftcol + vim.fn.winwidth(0) - 1

		local opt_wrap = api.nvim_win_get_option(0, 'wrap')

		if opts.top or opts.atop then
			api.nvim_win_set_cursor(0, {
				math.max(view.topline + (opts.atop and -1 or 0), 1),
				0,
			})
		end

		local prev_line, prev_col

		while true do
			if type(cmd) == 'string' then
				api.nvim_command('noautocmd keepjumps keeppattern silent ' .. cmd)
			else
				cmd()
			end

			local win = api.nvim_get_current_win()
			local buf = api.nvim_win_get_buf(win)

			-- Target is at the cursor position.
			local line, col = unpack(api.nvim_win_get_cursor(0))

			-- Do not add same target twice. Also to avoid infinite loops.
			local target_id = ('%d:%d:%d'):format(buf, line, col)
			if target_set[target_id] then
				break
			end
			target_set[target_id] = true

			-- Skip non-visible portion of a line.
			if not opt_wrap then
				if col < view.leftcol then
					if prev_line == line then
						api.nvim_win_set_cursor(0, {
							line,
							prev_col <= col and view.leftcol or 0
						})
					end
					goto continue
				end

				if view.rightcol < col then
					if prev_line == line then
						api.nvim_win_set_cursor(0, {
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

			-- Avoid adding initial cursor position.
			if
				win == cur_win and
				line == cur_line and
				col == cur_col
			then
				goto continue
			end

			targets[#targets + 1] = {
				win = win,
				buf = buf,
				line = line,
				col = col,
			}

			::continue::
			prev_line, prev_col = line, col
		end

		vim.fn.winrestview(view)
	end

	-- Ensure current window gets crawled first.
	add_win_targets()

	if opts.windo ~= false then
		for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
			if win ~= cur_win then
				api.nvim_win_call(win, add_win_targets)
			end
		end
	end

	vim.o.scrolloff = o_scrolloff

	return targets
end

local last_jump_args
local function jump(cmd, opts)
	local mode = vim.fn.mode()

	local targets = generate_targets(cmd, opts)
	-- Set them after targets have been generated to avoid interfering with ".".
	vim.o.opfunc = 'v:lua.jumpmotion_noop'
	api.nvim_command('silent! normal! g@:\n')
	vim.o.opfunc = 'v:lua.jumpmotion_repeat'
	last_jump_args = {cmd, opts}

	generate_keys(targets)

	local target = choose_target(targets)
	if not target then
		return false
	end

	-- Push current location to jumplist.
	api.nvim_command("normal! m'")

	api.nvim_set_current_win(target.win)
	api.nvim_win_set_cursor(target.win, {target.line, target.col})

	if mode == 'v' or mode == 'V' then
		api.nvim_command('normal! m>gv')
	end

	return true
end

function _G.jumpmotion_noop()
	-- Do nothing. Really.
end

function _G.jumpmotion_repeat()
	jump(unpack(last_jump_args))
end

function _G.jumpmotion_opfunc()
	jump(function()
		vim.o.opfunc = 'v:lua.jumpmotion_noop'
		api.nvim_command('normal .\n')
		api.nvim_win_set_cursor(0, {
			vim.fn.line("']"),
			vim.fn.col("']"),
		})
	end)
end

local function bounce(cmd, there, here, opts)
	local count = vim.v.count1
	if jump(cmd, opts or { top = true }) then
		api.nvim_command('normal! ' .. there:format(count))
		api.nvim_command([[execute "normal! \<C-o>"]])
		api.nvim_command(here)
	end
end

do

	local function map(lhs, rhs)
		vim.keymap.set('n', '<Plug>(JumpMotion)' .. lhs, rhs)
		vim.keymap.set('v', '<Plug>(JumpMotion)' .. lhs, rhs)
	end

	local function escape(s)
		return s:gsub('\\', '\\\\')
	end

	for x in ('jkwbWBnpN(){};,%'):gmatch('.') do
		map(x, function()
			jump('normal ' .. x)
		end)
	end

	for x in ('_$'):gmatch('.') do
		map(x, function()
			jump('normal! 2' .. x, { atop = true })
		end)
	end

	for x in ('tTfF'):gmatch('.') do
		map(x, function()
			local ok, char = pcall(getchar)
			if ok then
				jump('normal ' .. x .. char)
			end
		end)
	end

	for x in ('oO'):gmatch('.') do
		map(x, function()
			if jump([[normal! /\m^\s*\zs\S\S]] .. '\n', { top = true }) then
				api.nvim_input(x)
			end
		end)
	end

	for _, x in ipairs({'-', '<C-w>'}) do
		map(x, function()
			jump('normal! :\n')
		end)
	end

	for x in ('iI'):gmatch('.') do
		map(x, function()
			if jump('normal! 2_', { top = true }) then
				vim.cmd.startinsert()
			end
		end)
	end

	for x in ('aA'):gmatch('.') do
		map(x, function()
			if jump('normal! 2$', { top = true }) then
				vim.cmd.startinsert { bang = true }
			end
		end)
	end

	map('=', function()
		jump([[normal! /\m[^~<>=]\zs=[=#?]\@!]] .. '\n', { top = true })
	end)

	map("'", function()
		if jump([=[silent! normal! /\v['"]\zs.{-}['"]]=] .. '\n', { top = true }) then
			api.nvim_command([=[keepjumps keeppattern silent! normal! v/\ze.['"]]=] .. '\n')
			api.nvim_command('normal o')
		end
	end)

	map('c', function()
		if pcall(function()
			vim.fn.setreg('/', '\\V' .. escape(getchar()))
		end) then
			jump('normal! n', { top = true })
		end
	end)

	map('s', function()
		if pcall(function()
			vim.fn.setreg('/', '\\V' .. escape(getchar()) .. escape(getchar()))
		end) then
			jump('normal! n', { top = true })
		end
	end)

	map('+', function()
		jump(
			[[normal! /\v%([<>!\-+%*/~&|=,:;(){}[\]"'`.#]{1,3}%(\D|$)|<%(or|and|not|xor)>|<begin|<end)]] .. '\n',
			{ top = true }
		)
	end)

	map('y', function()
		bounce([[normal! /^\v%(\s*\S){3,}]] .. '\n', '%dyy', 'normal p')
	end)

	map('Y', function()
		bounce([[normal! /^\s*\S]] .. '\n', 'yap', 'normal p')
	end)

end

return {
	jump = jump,
	bounce = bounce,
}
