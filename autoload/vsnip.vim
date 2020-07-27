let s:Session = vsnip#session#import()
let s:TextEdit = vital#vsnip#import('VS.LSP.TextEdit')
let s:Position = vital#vsnip#import('VS.LSP.Position')

let s:session = v:null
let s:selected_text = ''

"
" vsnip#selected_text.
"
function! vsnip#selected_text(...) abort
  if len(a:000) == 1
    let s:selected_text = a:000[0]
  else
    return s:selected_text
  endif
endfunction

"
" vsnip#available.
"
function! vsnip#available(...) abort
  let l:direction = get(a:000, 0, 1)
  let l:expandable = vsnip#expandable()
  let l:jumpable = !empty(s:session) && s:session.jumpable(l:direction)
  return l:expandable || l:jumpable
endfunction

"
" vsnip#expandable.
"
function! vsnip#expandable() abort
  return !empty(vsnip#get_context())
endfunction

"
" vsnip#expand
"
function! vsnip#expand() abort
  let l:context = vsnip#get_context()
  if !empty(l:context)
    let l:position = s:Position.cursor()
    let l:text_edit = {
    \   'range': {
    \     'start': {
    \       'line': l:position.line,
    \       'character': l:position.character - l:context.length
    \     },
    \     'end': l:position
    \   },
    \   'newText': ''
    \ }
    call s:TextEdit.apply(bufnr('%'), [l:text_edit])
    call cursor(s:Position.lsp_to_vim('%', l:text_edit.range.start))
    call vsnip#anonymous(join(l:context.snippet.body, "\n"))
  endif
endfunction

"
" vsnip#anonymous.
"
function! vsnip#anonymous(text) abort
  let l:session = s:Session.new(bufnr('%'), s:Position.cursor(), a:text)
  call vsnip#selected_text('')

  if empty(s:session)
    let s:session = l:session
    call s:session.insert()
  else
    call s:session.on_text_changed()
    if !empty(s:session)
      call s:session.merge(l:session)
    else
      let s:session = l:session
      call s:session.insert()
    endif
  endif

  call s:session.refresh()
  call s:session.jump(1)
endfunction

"
" vsnip#get_session
"
function! vsnip#get_session() abort
  return s:session
endfunction

"
" vsnip#deactivate
"
function! vsnip#deactivate() abort
  let s:session = {}
endfunction

"
" get_context.
"
function! vsnip#get_context() abort
  let l:before_text = getline('.')[0 : col('.') - 2]
  let l:before_text_len = strchars(l:before_text)
  for l:source in vsnip#source#find(&filetype)
    for l:snippet in l:source
      for l:prefix in (l:snippet.prefix + l:snippet.prefix_alias)
        let l:prefix_len = strchars(l:prefix)
        if strcharpart(l:before_text, l:before_text_len - l:prefix_len, l:prefix_len) !=# l:prefix
          continue
        endif

        return {
        \   'length': l:prefix_len,
        \   'snippet': l:snippet
        \ }
      endfor
    endfor
  endfor

  return {}
endfunction

"
" vsnip#get_complete_items
"
function! vsnip#get_complete_items(bufnr) abort
  let l:candidates = []

  for l:source in vsnip#source#find(getbufvar(a:bufnr, '&filetype', ''))
    for l:snippet in l:source
      for l:prefix in l:snippet.prefix
        let l:candidate = {
        \   'word': l:prefix,
        \   'abbr': l:prefix,
        \   'kind': join(['Snippet', l:snippet.label, l:snippet.description], ' '),
        \   'menu': '[v]',
        \   'dup': 1,
        \   'user_data': json_encode({
        \     'vsnip': {
        \       'snippet': l:snippet.body
        \     }
        \   })
        \ }

        if has_key(l:snippet, 'description') && strlen(l:snippet.description) > 0
          let l:candidate.menu .= printf(': %s', l:snippet.description)
        endif

        call add(l:candidates, l:candidate)
      endfor
    endfor
  endfor

  return l:candidates
endfunction

"
" vsnip#debug
"
function! vsnip#debug() abort
  if !empty(s:session)
    call s:session.snippet.debug()
  endif
endfunction
