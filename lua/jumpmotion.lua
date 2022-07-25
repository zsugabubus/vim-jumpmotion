local V = vim.api
local Vcall = V.nvim_call_function
local Vcmd = V.nvim_command
local Vset = V.nvim_set_option
local Vget = V.nvim_get_option
local Vset_cursor = V.nvim_win_set_cursor

local ns = V.nvim_create_namespace('jumpmotion')

local function getchar()
	local nr = Vcall('getchar', {})
	if nr == 27 then
		error('user interrupted')
	end
	return Vcall('nr2char', {nr})
end

local function update_extmarks(targets)
	for _, target in ipairs(targets) do
		target.extmark_id = V.nvim_buf_set_extmark(
			target.buf, ns, target.line - 1, target.col, {
				id=target.extmark_id,
				virt_text={
					{target.key:sub(1, 1), 'JumpMotionHead'},
					-- Empty virtual text makes Nvim confused.
					1 < #target.key
						and {target.key:sub(2), 'JumpMotionTail'}
						or nil,
				},
				virt_text_pos='overlay',
				priority=1000 + #targets
			})
	end
end

local function generate_keys(targets)
	local a, z = string.byte('a'), string.byte('z')
	local n = 1
	for _, target in ipairs(targets) do
		if not target.key then
			local i = n
			target.key = ''
			while 0 < i do
				i = i - 1
				target.key = string.char(a + i % (z - a + 1)) .. target.key
				i = math.floor(i / (z - a + 1))
			end
			n = n + 1
		end
	end
end

local function jump(targets)
	generate_keys(targets)

	while 1 < #targets do
		update_extmarks(targets)
		Vcmd(('echon "jumpmotion: (%d targets)"')
			:format(#targets))
		Vcmd('redraw')

		local ok, char = pcall(getchar)
		if not ok then
			char = ' '
		end

		Vcmd('echomsg ""')

		local tmp_targets = {}
		for _, target in ipairs(targets) do
			if target.key:sub(1, #char) == char then
				target.key = target.key:sub(#char + 1)
				if target.key == '' then
					target.key = ' '
				end
				tmp_targets[#tmp_targets + 1] = target
			else
				V.nvim_buf_del_extmark(target.buf, ns, target.extmark_id)
			end
		end
		targets = tmp_targets
	end

	local target = targets[1]
	if not target then
		Vcmd('echohl ErrorMsg|echo "jumpmotion: No matches."|echohl None')
		return false
	end

	if target.extmark_id then
		V.nvim_buf_del_extmark(target.buf, ns, target.extmark_id)
	end

	-- Push current location to jumplist.
	Vcmd("normal! m'")

	V.nvim_set_current_win(target.win)
	Vset_cursor(target.win, {
		target.line,
		target.col,
	})

	return true
end

local function generate_targets(cmd, flags)
	local targets = {}

	local saved_so = Vget('scrolloff')
	Vset('scrolloff', 0)

	local cur_win, cur_line, cur_col =
		V.nvim_get_current_win(),
		unpack(V.nvim_win_get_cursor(0))

	local target_set = {}

	local function add_win_targets()
		local win = V.nvim_get_current_win()
		local buf = V.nvim_win_get_buf(0)

		local view = Vcall('winsaveview', {})
		view.bottomline = Vcall('line', {'w$'})
		view.rightcol = view.leftcol + Vcall('winwidth', {0}) - 1

		if flags:find('0') then
			Vset_cursor(0, {
				math.max(view.topline + (flags:find('2') and -1 or 0), 1),
				0,
			})
		end

		while true do
			if type(cmd) == 'string' then
				Vcmd('noautocmd keepjumps keeppattern silent normal ' .. cmd)
			else
				cmd()
			end

			-- Get target at the cursor position.
			local line, col = unpack(V.nvim_win_get_cursor(0))
			local target = {
				win=win,
				buf=buf,
				line=line,
				col=col,
			}

			-- Do not add same target twice.
			local target_id = ('%d:%d:%d')
				:format(buf, target.line, target.col)
			if target_set[target_id] then
				break
			end
			target_set[target_id] = true

			-- Avoid scanning remaining line when out of the viewport on the left or
			-- on the right sides.
			if
				target.col < view.leftcol
			then
				Vset_cursor(0, {target.line, 0})
				goto continue
			end

			if
				view.rightcol < target.col
			then
				Vset_cursor(0, {target.line, 999999})
				goto continue
			end

			-- Top scanning when out of the viewport on the top or on the bottom.
			if
				target.line < view.topline or
				view.bottomline < target.line
			then
				break
			end

			-- Do not add initial cursor position to the target list.
			if
				target.win == cur_win and
				target.line == cur_line and
				target.col == cur_col
			then
				goto continue
			end

			targets[#targets + 1] = target

			::continue::
		end

		Vcall('winrestview', {view})
	end

	-- Ensure current window gets crawled first.
	add_win_targets()

	if flags:find('t') then
		for _, win in ipairs(V.nvim_tabpage_list_wins(0)) do
			if win ~= cur_win then
				V.nvim_win_call(win, add_win_targets)
			end
		end
	end

	Vset('scrolloff', saved_so)

	return targets
end

local last_args

local function JumpMotion(cmd, flags)
	flags = flags or ''

	local mode = Vcall('mode', {})

	local targets = generate_targets(cmd, flags)

	-- Set them after targets have been generated to avoid interfering with ".".
	Vset('opfunc', 'v:lua.jumpmotion_noop')
	Vcmd('silent! normal! g@:\n')
	Vset('opfunc', 'v:lua.jumpmotion_repeat')
	last_args = {cmd, flags}

	if not jump(targets) then
		return false
	end

	if mode == 'v' or mode == 'V' then
		Vcmd('normal! m>gv')
	end

	return true
end

function _G.jumpmotion_noop()
	-- Do nothing. Really.
end

function _G.jumpmotion_repeat()
	JumpMotion(unpack(last_args))
end

---- snip ----

-- Probably should be inside my init.vim.
local mappings = {}

function _G.jumpmotion_map_trampoline(lhs)
	mappings[lhs]()
end

local function map(lhs, fn)
	mappings[lhs] = fn

	local rhs = ([[<Cmd>call v:lua.jumpmotion_map_trampoline("%s")<CR>]])
		:format(lhs:gsub('<', '<lt>'))
	local lhs = '<Plug>(JumpMotion)' .. lhs

	for _, mode in ipairs({'n', 'v', 'o'}) do
		vim.api.nvim_set_keymap(mode, lhs, rhs, {noremap = false})
	end
end

function _G.jumpmotion_opfunc()
	JumpMotion(function()
		Vset('opfunc', 'v:lua.jumpmotion_noop')
		Vcmd('normal .\n')
		Vset_cursor(0, {
			Vcall('line', {"']"}),
			Vcall('col', {"']"}),
		})
	end)
end

local function escape(s)
	return s:gsub('\\', '\\\\')
end

for x in ('jkwbWBnpN(){};,%'):gmatch('.') do
	map(x, function()
		JumpMotion(x)
	end)
end

for x in ('_$'):gmatch('.') do
	map(x, function()
		JumpMotion('2' .. x, '02t')
	end)
end

for x in ('tTfF'):gmatch('.') do
	map(x, function()
		local ok, cmd = pcall(function()
			return x .. getchar()
		end)
		if ok then
			JumpMotion(cmd)
		end
	end)
end

for x in ('oO'):gmatch('.') do
	map(x, function()
		if JumpMotion([[/\m^\s*\zs\S\S]] .. '\n', '0') then
			V.nvim_input(x)
		end
	end)
end

for _, x in ipairs({'-', '<C-w>'}) do
	map(x, function()
		JumpMotion(':\n', 't')
	end)
end

for x in ('iI'):gmatch('.') do
	map(x, function()
		if JumpMotion('2_', '0t') then
			Vcmd('startinsert')
		end
	end)
end

for x in ('aA'):gmatch('.') do
	map(x, function()
		if JumpMotion('2$', '0t') then
			Vcmd('startinsert!')
		end
	end)
end

map('=', function()
	JumpMotion([[/\m[^~<>=]\zs=[=#?]\@!]] .. '\n', '0t')
end)

map("'", function()
	if JumpMotion([=[/\v['"]\zs.{-}['"]]=] .. '\n', '0t') then
		Vcmd([=[keepjumps keeppattern normal v/\ze.['"]]=] .. '\n')
		Vcmd('normal o')
	end
end)

map('c', function()
	if pcall(function()
		Vcall('setreg', {'/', '\\V' .. escape(getchar())})
	end) then
		JumpMotion('n', '0')
	end
end)

map('s', function()
	if pcall(function()
		Vcall('setreg', {'/', '\\V' .. escape(getchar()) .. escape(getchar())})
	end) then
		JumpMotion('n', '0')
	end
end)

map('+', function()
	JumpMotion([[/\v%([<>!\-+%*/~&|=,:;(){}[\]"'`.#]{1,3}%(\D|$)|<%(or|and|not|xor)>|<begin|<end)]] .. '\n', '0')
end)

map('@', function()
	JumpMotion('n', '0t')
end)

map('y', function()
	if JumpMotion([[/^\v%(\s*\S){3,}]] .. '\n', '0t') then
		Vcmd('normal yy``P')
	end
end)

return {
	JumpMotion=JumpMotion,
}
