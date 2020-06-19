" File: bufselect.vim
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 1.1
" Last Modified: June 19, 2020
"
" Plugin to display the list of buffers in a popup menu
"
" License:   Permission is hereby granted to use and distribute this code,
"            with or without modifications, provided that this copyright
"            notice is copied with it. Like anything else that's free,
"            bufselect plugin is provided *as is* and comes with no warranty
"            of any kind, either expressed or implied. In no event will the
"            copyright holder be liable for any damages resulting from the use
"            of this software.
"
" =========================================================================

" Popup window support needs Vim 8.2 and higher
if v:version < 802
  finish
endif

" User command to open the buffer select popup menu
command! -nargs=* Bufselect call bufselect#showMenu(<q-args>)

" key mapping to toggle the buffer select popup menu
nnoremap <expr> <silent> <Plug>Bufselect_Toggle bufselect#toggle()

" vim: shiftwidth=2 sts=2 expandtab
