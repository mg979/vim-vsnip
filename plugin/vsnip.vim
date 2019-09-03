if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

let g:vsnip_snippet_dir = expand('~/.vsnip')
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = 100
let g:vsnip_namespace = 'snip_'
let g:vsnip_verbose = get(g:, 'snip_verbose', v:false)

inoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>
snoremap <silent> <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>

command! VsnipEdit
      \ call vsnip#command#edit#call(&filetype)
command! -range=% VsnipAdd
      \ call vsnip#command#add#call(&filetype)

augroup vsnip
  autocmd!
  autocmd! vsnip TextChanged * call s:on_text_changed()
  autocmd! vsnip TextChangedI * call s:on_text_changed_i()
  autocmd! vsnip TextChangedP * call s:on_text_changed_p()
  autocmd! vsnip InsertLeave * call s:on_insert_leave()
  autocmd! vsnip TextYankPost * call s:on_text_yank_post()
  autocmd! vsnip BufWritePre * call s:on_buf_write_pre()
augroup END

function! s:on_text_changed()
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_text_changed_i()
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_text_changed_p()
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:on_text_yank_post()
  " Currently `vsnip` uses recently yanked text to $TM_SELECTED_TEXT.
  if v:operator == 'y'
    call vsnip#select(getreg(v:register))
  endif
endfunction

function! s:on_insert_leave()
  " To ignore `<Esc>` during snippet expanding.
  call timer_start(500, { -> vsnip#select('') }, { 'repeat': 1 })
endfunction

function! s:on_buf_write_pre()
  call vsnip#snippet#invalidate(fnamemodify(bufname('%'), ':p'))
endfunction

