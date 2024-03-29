let s:workspace = {}

function! graphql_client#workspace#new(workspaces, curl) abort
  return s:workspace.new(a:workspaces, a:curl)
endfunction

function! s:workspace.new(workspaces, curl) abort
  let s:workspace = copy(s:workspace)
  let s:workspace.buffer_name = 'gqlui'
  let s:workspace.workspaces = a:workspaces
  let s:workspace.curl = a:curl
  let s:workspace.current_workspace_key = len(a:workspaces) > 0 ? keys(a:workspaces)[0] : ''
  let s:workspace.icons = g:graphql_client_icons
  call s:workspace.set_current_workspace_from_key(s:workspace.current_workspace_key)
  return s:workspace
endfunction

function! s:workspace.show() abort
  call self.open_buffer()
  call self.setup_buffer()
endfunction

function! s:workspace.open_buffer() abort
  let buffer_win = bufwinid(self.buffer_name)
  if buffer_win > -1
    call win_gotoid(buffer_win)
  else
    execute "topleft vnew " . self.buffer_name
  endif
endfunction

function! s:workspace.setup_buffer() abort
  vertical-resize 40
  setlocal filetype=gqlui
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal hidden

  nnoremap <silent><buffer> <CR> :call <sid>method('set_current_workspace')<CR>
  nnoremap <silent><buffer> ? :call <sid>method('show_workspace_info')<CR>

  call self.redraw()
  setlocal nomodifiable
endfunction

function! s:workspace.redraw() abort
  setlocal modifiable
  " clear file
  silent 1,$delete _

  " write workspaces
  call setline(1, '" Press Enter for set endpoint')
  call setline(2, '')

  let i = 3
  for k in keys(self.workspaces)
    let workspace_name = k
    if self.current_workspace_key == k
      let workspace_name = k.' '.self.icons.current_workspace
    endif
    call setline(i, workspace_name)

    let i += 1
  endfor

  setlocal nomodifiable
endfunction

function! s:workspace.show_workspace_info() abort
  let content = matchstr(getline('.'), '\S\+')
  echo self.get_workspace_info(content)
endfunction

function! s:workspace.get_workspace_info(key) abort
  if !has_key(self.workspaces, a:key)
    return 'not found workspace info'
  endif
  return self.workspaces[a:key]
endfunction

function! s:workspace.set_current_workspace() abort
  let content = matchstr(getline('.'), '\S\+')
  call self.set_current_workspace_from_key(content)
endfunction

function! s:workspace.set_current_workspace_from_key(key) abort
  for k in keys(self.workspaces)
    if a:key == k
      let self.current_workspace_key = k
      let workspace_info = self.get_workspace_info(k)
      let g:graphql_client_endpoint = workspace_info.endpoint
      call self.curl.set_headers(workspace_info.headers)

      call self.redraw()
      echo 'set '.self.current_workspace_key.' workspace'
      return
    endif
  endfor
endfunction

function! s:method(method_name) abort
  return s:workspace[a:method_name]()
endfunction
