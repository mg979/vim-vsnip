let s:uid = 0

"
" vsnip#snippet#node#variable#import
"
function! vsnip#snippet#node#variable#import() abort
  return s:Variable
endfunction

let s:Variable = {}

"
" new.
"
function! s:Variable.new(ast) abort
  let s:uid += 1

  let l:resolver = vsnip#variable#get(a:ast.name)
  let l:node = extend(deepcopy(s:Variable), {
  \   'uid': s:uid,
  \   'type': 'variable',
  \   'name': a:ast.name,
  \   'resolver': l:resolver,
  \   'children': vsnip#snippet#node#create_from_ast(get(a:ast, 'children', [])),
  \ })

  let l:node.unknown = empty(l:resolver) && !s:can_interpolate(a:ast.name)
  return l:node
endfunction

"
" text.
"
function! s:Variable.text() abort
  return join(map(copy(self.children), 'v:val.text()'), '')
endfunction

"
" resolve.
"
function! s:Variable.resolve(context) abort
  if s:can_interpolate(self.name)
    return s:interpolate(self.name)
  elseif !self.unknown
    let l:resolved = self.resolver.func({ 'node': self })
    if l:resolved isnot v:null
      " Fix indent when one variable returns multiple lines
      let l:base_indent = vsnip#indent#get_base_indent(split(a:context.before_text, "\n", v:true)[-1])
      return substitute(l:resolved, "\n\\zs", l:base_indent, 'g')
    endif
  endif
  return v:null
endfunction

"
" to_string
"
function! s:Variable.to_string() abort
  return printf('%s(name=%s, unknown=%s, text=%s)',
  \   self.type,
  \   self.name,
  \   self.unknown ? 'true' : 'false',
  \   self.text()
  \ )
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" User variable interpolation
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

"
" can_interpolate
"
function! s:can_interpolate(variable) abort
  return get(b:vsnip_snippet_variables, toupper(a:variable), '') != ''
endfunction

"
" interpolate
"
function! s:interpolate(variable)
  let l:interpolation = b:vsnip_snippet_variables[toupper(a:variable)]
  let l:type = matchstr(l:interpolation, '^!\w\+')
  let l:expr = substitute(l:interpolation, '^' . l:type . '\s\+', '', '')
  return  l:type ==# '!vim'                  ? eval(l:expr) :
        \ l:type ==# '!lua' && s:has_lua()   ? luaeval(l:expr) :
        \ l:type ==# '!py' && s:has_python() ? has('pythonx') ? pyxeval(l:expr) :
        \                                      has('python3') ? py3eval(l:expr) : pyeval(l:expr) :
        \ l:expr
  endif
endfunction

"
" has_lua
"
function! s:has_lua() abort
  return has('nvim') || has('lua')
endfunction

"
" has_python
"
function! s:has_python() abort
  return has('pythonx') || has('python3') || has('python')
endfunction

