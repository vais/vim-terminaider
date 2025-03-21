if exists('g:loaded_terminaider')
    finish
endif
let g:loaded_terminaider = 1

" Default window width
if !exists('g:terminaider_width')
    let g:terminaider_width = 80
endif

" Terminal buffer number
let s:term_buf = -1

" Store the arguments used to start aider
let s:current_args = ''

" Aider prompt pattern
let s:aider_prompt_pattern = '^[a-z -]*>\ '

function! s:OpenTerminal(mods, args) abort
    " If terminal buffer exists and is valid
    if s:term_buf != -1 && bufexists(s:term_buf) && term_getstatus(s:term_buf) =~# 'running'
        " Find if terminal window is visible
        let l:win_id = bufwinid(s:term_buf)
        if l:win_id == -1
            " Terminal exists but not visible - open new window
            execute 'vertical botright ' . g:terminaider_width . 'split'
            execute 'buffer ' . s:term_buf
        else
            " Terminal is visible - focus it and resize
            call win_gotoid(l:win_id)
            execute 'vertical resize ' . g:terminaider_width
        endif
        return
    endif

    " Set environment variables for aider theme based on vim background
    let $AIDER_DARK_MODE = &background == 'dark' ? 'true' : 'false'
    let $AIDER_LIGHT_MODE = &background == 'dark' ? 'false' : 'true'
    
    " Create new terminal window
    execute 'vertical botright ' . g:terminaider_width . 'new'
    
    " Store the arguments for potential restart
    let s:current_args = a:args
    
    " Start terminal in current window
    let s:term_buf = term_start(['aider'] + split(a:args), {
                \ 'exit_cb': function('s:OnTermExit'),
                \ 'curwin': 1,
                \ 'term_finish': 'open'
                \ })

    " Set a static termwinsize to work around the issue with vim terminal
    " cutting off scrollback when a vertical split is resized, as well as
    " with Aider sometimes getting confused when terminal width changes
    execute "setlocal termwinsize=" . winheight(0) . "x" . g:terminaider_width

    " Keep window width when windows are equalized
    setlocal winfixwidth

    " We don't want any of these in the terminal buffer - this way when
    " we go from terminal to normal mode, buffer width remains the same
    setlocal nonumber
    setlocal norelativenumber
    setlocal signcolumn=no

    " Make sure buffer doesn't get unloaded when hidden
    setlocal bufhidden=hide

    " Make sure buffer doesn't show up in buffer list
    setlocal nobuflisted

    " Fold on aider prompt pattern
    setlocal foldmethod=expr
    setlocal foldexpr=getline(v:lnum)=~s:aider_prompt_pattern?'>1':1
    setlocal foldtext=foldtext()
    setlocal foldlevel=1

    " Protect buffer from being accidentally replaced by :e
    cnoremap <buffer> e<CR> <CR>

    " Set up autocmd to make content foldable when switching from terminal to normal mode
    augroup TerminaiderFolding
        autocmd! * <buffer>
        autocmd ModeChanged <buffer> if mode() == 'n' | setlocal foldmethod=expr | endif
    augroup END

    " Move to next fold and open it if closed
    nmap <buffer> <C-n> zj:if foldclosed('.') != -1 \| execute 'normal! zmza' \| endif<CR>zt
    
    " Move to previous fold, open it if closed, then go to start of fold
    nmap <buffer> <C-p> zk:if foldclosed('.') != -1 \| execute 'normal! zmza' \| endif<CR>[zzt
endfunction

function! s:OnTermExit(job_id, status) abort
    if a:status == 0
        " If aider exited successfully, close buffer
        execute 'bdelete! ' . s:term_buf
    else
        " If aider exited with error, keep buffer open
        echohl WarningMsg
        echo "Aider exited with status " . a:status
        echohl None

        " Make sure buffer shows up in buffer list now
        setlocal buflisted
    endif
    let s:term_buf = -1
endfunction

function! s:HideTerminal() abort
    if s:term_buf != -1
        let l:win_id = bufwinid(s:term_buf)
        if l:win_id != -1
            " Terminal is visible - hide the window
            call win_execute(l:win_id, 'hide')
        endif
    endif
endfunction

function! s:CheckAiderReady(...)
    let l:silent = a:0 > 0 ? a:1 : 0
    
    " Check if aider is running
    if s:term_buf == -1 || !bufexists(s:term_buf) || term_getstatus(s:term_buf) !~# 'running'
        if !l:silent
            echohl Error
            echo "Aider is not running"
            echohl None
        endif
        return 0
    endif
    
    " Get the last line of terminal output
    let l:last_line = term_getline(s:term_buf, '.')
    
    " Check if the last line matches the aider prompt pattern
    if l:last_line !~# s:aider_prompt_pattern . ' $'
        echohl Error
        echo "Aider appears busy, check the prompt"
        echohl None
        return 0
    endif

    return 1
endfunction

function! s:CheckFileReadable(path) abort
    " Check if file exists and has read permissions before proceeding
    if !filereadable(a:path)
        echohl Error
        echo "File not readable: " . a:path
        echohl None
        return 0
    endif
    return 1
endfunction

function! s:AddCurrentFile() abort
    if !s:CheckAiderReady()
        return
    endif

    " Get absolute path of current buffer
    let l:path = fnamemodify(expand('%:p'), ':p')
    
    if !s:CheckFileReadable(l:path)
        return
    endif

    " Feed the /add command followed by the path
    echo "Adding " . l:path . " to the chat"
    call term_sendkeys(s:term_buf, "/add " . l:path . "\<CR>")
endfunction

function! s:AddCurrentFileReadOnly() abort
    if !s:CheckAiderReady()
        return
    endif

    " Get absolute path of current buffer
    let l:path = fnamemodify(expand('%:p'), ':p')
    
    if !s:CheckFileReadable(l:path)
        return
    endif

    " Feed the /read-only command followed by the path
    echo "Adding " . l:path . " to the chat as read-only"
    call term_sendkeys(s:term_buf, "/read-only " . l:path . "\<CR>")
endfunction

function! s:DropCurrentFile() abort
    if !s:CheckAiderReady()
        return
    endif

    " Get absolute path of current buffer
    let l:path = fnamemodify(expand('%:p'), ':p')
    
    " Feed the /drop command followed by the path
    echo "Dropping " . l:path . " from the chat"
    call term_sendkeys(s:term_buf, "/drop " . l:path . "\<CR>")
endfunction

function! s:ExitAider() abort
    if !s:CheckAiderReady()
        return
    endif

    " Prompt user for confirmation
    let l:choice = confirm("Are you sure you want to exit aider?", "&Yes\n&No", 2)
    
    " If user confirmed (chose "Yes")
    if l:choice == 1
        call term_sendkeys(s:term_buf, "/exit\<CR>")
    endif
endfunction

function! s:ToggleRepoMap() abort
    " Check if AIDER_MAP_TOKENS is set to 0
    if $AIDER_MAP_TOKENS == '0'
        " Actually unset the variable using :unlet
        unlet $AIDER_MAP_TOKENS
        echo "AIDER_MAP_TOKENS is now unset (default behavior)"
    else
        " Set the variable to 0
        let $AIDER_MAP_TOKENS = '0'
        echo "AIDER_MAP_TOKENS is now set to 0 (disabled)"
    endif
    
    " Check if aider is running and ready
    if !s:CheckAiderReady(1)
        " Aider is not running or not ready, just return
        return
    endif
    
    " Ask if user wants to restart aider
    let l:choice = confirm("Restart aider for changes to take effect?", "&Yes\n&No", 1)
    
    if l:choice == 1
        " Send exit command
        call term_sendkeys(s:term_buf, "/exit\<CR>")
        
        " Wait for aider to exit
        echo "Waiting for aider to exit..."
        while s:term_buf != -1
            sleep 100m
        endwhile
        
        " Start aider again with the stored arguments
        call s:OpenTerminal('', s:current_args)
    endif
endfunction

command! -nargs=* Terminaider call s:OpenTerminal(<q-mods>, <q-args>)
command! -nargs=0 TerminaiderHide call s:HideTerminal()
command! -nargs=0 TerminaiderAdd call s:AddCurrentFile()
command! -nargs=0 TerminaiderAddReadOnly call s:AddCurrentFileReadOnly()
command! -nargs=0 TerminaiderDrop call s:DropCurrentFile()
command! -nargs=0 TerminaiderExit call s:ExitAider()
command! -nargs=0 TerminaiderToggleRepoMap call s:ToggleRepoMap()

