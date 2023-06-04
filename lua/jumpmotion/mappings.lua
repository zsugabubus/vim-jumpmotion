local M = {}

local X = setmetatable({}, {
	__index = function(_, key)
		X = require 'jumpmotion'
		return X[key]
	end,
})

local function escape(s)
	return string.gsub(s, [[\]], [[\\]])
end

function M.char()
	if pcall(function()
		local s = vim.fn.getcharstr()
		vim.fn.setreg(
			'/',
			(s == '$' and [[\v$|]] or '') ..
			[[\V]] ..
			escape(s)
		)
	end) then
		return X.jump('normal! n', { top = true })
	end
end

function M.sneak()
	if pcall(function()
		vim.fn.setreg(
			'/',
			[[\V]] ..
			escape(vim.fn.getcharstr()) ..
			escape(vim.fn.getcharstr())
		)
	end) then
		return X.jump('normal! n', { top = true })
	end
end

function M.setup(opts)
	if opts.leader then
		vim.keymap.set('', opts.leader, '<Plug>(JumpMotion)')
	end

	function _G._jumpmotion_opfunc()
		return X.jump(function()
			vim.o.opfunc = 'v:lua._jumpmotion_noop'
			vim.api.nvim_command('normal .\n')
			vim.api.nvim_win_set_cursor(0, {
				vim.fn.line("']"),
				vim.fn.col("']"),
			})
		end)
	end

	vim.keymap.set(
		'',
		'<Plug>(JumpMotion)',
		'<Cmd>set opfunc=v:lua._jumpmotion_opfunc<CR>g@v'
	)

	local function map(lhs, rhs)
		vim.keymap.set('n', '<Plug>(JumpMotion)' .. lhs, rhs)
		vim.keymap.set('v', '<Plug>(JumpMotion)' .. lhs, rhs)
	end

	for x in ('jkwbWBnpN(){};,%'):gmatch('.') do
		map(x, function()
			X.jump('normal ' .. x)
		end)
	end

	for x in ('_$'):gmatch('.') do
		map(x, function()
			X.jump('normal! 2' .. x, { above_top = true })
		end)
	end

	for x in ('tTfF'):gmatch('.') do
		map(x, function()
			local ok, char = pcall(vim.fn.getcharstr)
			if ok then
				X.jump('normal ' .. x .. char)
			end
		end)
	end

	for x in ('oO'):gmatch('.') do
		map(x, function()
			if X.jump([[normal! /\m^\s*\zs\S\S]] .. '\n', { top = true }) then
				vim.api.nvim_input(x)
			end
		end)
	end

	for _, x in ipairs({'-', '<C-w>'}) do
		map(x, function()
			X.jump('normal! :\n')
		end)
	end

	for x in ('iI'):gmatch('.') do
		map(x, function()
			if X.jump('normal! 2_', { top = true }) then
				vim.cmd.startinsert()
			end
		end)
	end

	for x in ('aA'):gmatch('.') do
		map(x, function()
			if X.jump('normal! 2$', { top = true }) then
				vim.cmd.startinsert { bang = true }
			end
		end)
	end

	map('c', M.char)
	map('s', M.sneak)

	map('y', function()
		return M.bounce([[normal! /\v^\s*\zs\S]] .. '\n', '%dyy', 'normal p')
	end)

	map('Y', function()
		return M.bounce([[normal! /^\s*\S]] .. '\n', 'yap', 'normal p')
	end)
end

return M
