" File: bufselect.vim
" Author: Yegappan Lakshmanan (yegappan AT yahoo DOT com)
" Version: 1.1
" Last Modified: Sep 13, 2020
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

" Line continuation used here
let s:cpo_save = &cpo
set cpo&vim

let s:buflist = []
let s:popup_text = []
let s:filter_text = ''
let s:popup_winid = -1

" Edit the buffer selected from the popup menu
func s:editBuffer(id, result) abort
  if a:result <= 0
    return
  endif
  try
    " if selected buffer is already open in a window, jump to it
    let bname = s:popup_text[a:result - 1]
    let winList = win_findbuf(bufnr(bname))
    if len(winList) == 0
      " Not present in any window
      exe "confirm buffer " .. s:popup_text[a:result - 1]
    else
      call win_gotoid(winList[0])
    endif
  catch
    " ignore exceptions
  endtry
endfunc

" Sort two buffer names by the lastused timestamp, so that the latest used
" buffer is at to the top
func s:sortByLastUsed(i1, i2) abort
  let v1 = a:i1.lastused
  let v2 = a:i2.lastused
  return v1 == v2 ? 0 : v1 < v2 ? 1 : -1
endfunc

" Convert each file name in the items List into <filename> (<dirname>) format.
" Make sure the popup does't occupy the entire screen by reducing the width.
func s:makeMenuName(items) abort
  let maxwidth = popup_getpos(s:popup_winid).core_width
  "let maxwidth = &columns - 30

  for i in range(len(a:items))
    let filename = fnamemodify(a:items[i], ':t')
    let flen = len(filename)
    let dirname = fnamemodify(a:items[i], ':h')

    if len(a:items[i]) > maxwidth && flen < maxwidth
      " keep the full file name and reduce directory name length
      " keep some characters at the beginning and end (equally).
      " 6 spaces are used for "..." and " ()"
      let dirsz = (maxwidth - flen - 6) / 2
      let dirname = dirname[:dirsz] .. '...' .. dirname[-dirsz:]
    endif
    let a:items[i] = filename .. ' (' .. dirname .. ')'
  endfor
endfunc

" Handle the keys typed in the popup menu.
" Narrow down the displayed names based on the keys typed so far.
func s:filterNames(id, key) abort
  let update_popup = 0
  let key_handled = 0

  if a:key == "\<BS>"
    " Erase one character from the filter text
    if len(s:filter_text) >= 1
      let s:filter_text = s:filter_text[:-2]
      let update_popup = 1
    endif
    let key_handled = 1
  elseif a:key == "\<C-F>"
        \ || a:key == "\<C-B>"
        \ || a:key == "<PageUp>"
        \ || a:key == "<PageDown>"
        \ || a:key == "<C-Home>"
        \ || a:key == "<C-End>"
    call win_execute(s:popup_winid, 'normal! ' .. a:key)
    let key_handled = 1
  elseif a:key == "\<Up>"
        \ || a:key == "\<Down>"
    " Use native Vim handling of these keys
    let key_handled = 0
  elseif a:key =~ '\f' || a:key == "\<Space>"
    " Filter the names based on the typed key and keys typed before
    " Accept the typed key only if it is present in any of the buffer names
    let newsearch = s:filter_text .. a:key
    let found = 0
    for bname in s:popup_text
      if bname =~# newsearch
        let found = 1
        break
      endif
    endfor
    if found
      let s:filter_text ..= a:key
      let update_popup = 1
    endif
    let key_handled = 1
  endif

  if update_popup
    " Update the popup with the new list of file names

    " Keep the cursor at the current item
    let curLine = line('.', s:popup_winid)
    let prevSelName = s:popup_text[curLine - 1]

    let s:popup_text = filter(copy(s:buflist), 'v:val =~# s:filter_text')
    let items = copy(s:popup_text)
    call s:makeMenuName(items)
    call popup_settext(a:id, items)
    " Update the title to include the filter text
    let title = 'Buffers'
    if len(s:filter_text) > 0
      let title ..= ' (' . s:filter_text .. ')'
    endif
    call popup_setoptions(a:id, {'title' : title})

    " Select the previously selected entry. If not present, seelct first entry
    let idx = index(s:popup_text, prevSelName)
    let idx = idx == -1 ? 1 : idx + 1
    call win_execute(s:popup_winid, idx)
  endif

  if key_handled
    return 1
  endif

  return popup_filter_menu(a:id, a:key)
endfunc

func bufselect#showMenu(pat) abort
  " Get the list of buffer names to display. Use only listed buffers.
  let filter_cmd = 'v:val.name != ""'
  if a:pat != ''
    " Filter the buffer names using the user specified pattern (if any)
    let regex_pat = glob2regpat(a:pat)
    let filter_cmd ..= ' && v:val.name =~# regex_pat'
  endif
  let l = filter(getbufinfo({'buflisted' : 1}), filter_cmd)
  if empty(l)
    echohl Error | echo "No buffers found" | echohl None
    return
  endif

  " Sort the buffer names by last access timestamp
  call sort(l, 's:sortByLastUsed')

  " Expand the file paths and reduce it relative to the home and current
  " directories
  let s:buflist = map(l, 'fnamemodify(v:val.name, ":p:~:.")')

  " Save it for later use
  let s:popup_text = copy(s:buflist)
  let s:filter_text = ''

  " Create the popup menu
  let popupAttr = {}
  let popupAttr.title = 'Buffers'
  let popupAttr.minwidth = 30
  let popupAttr.minheight = 10
  let popupAttr.maxheight = 10
  let popupAttr.maxwidth = 60
  let popupAttr.fixed = 1
  let popupAttr.close = "button"
  let popupAttr.filter = function('s:filterNames')
  let popupAttr.callback = function('s:editBuffer')
  let popupAttr.mapping = 1
  let s:popup_winid = popup_menu([], popupAttr)

  " Populate the popup menu
  " Split the names into file name and directory path.
  let items = copy(s:popup_text)
  call s:makeMenuName(items)
  call popup_settext(s:popup_winid, items)
endfunc

" Toggle (open or close) the bufselect popup menu
func bufselect#toggle() abort
  if empty(popup_getoptions(s:popup_winid))
    " open the buf select popup
    call bufselect#showMenu('')
  else
    " popup window is present. close it.
    call popup_close(s:popup_winid, -2)
  endif
endfunc

" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: shiftwidth=2 sts=2 expandtab
