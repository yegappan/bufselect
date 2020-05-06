
The Buffer Selector plugin provides an easy access to jump to a buffer from
the Vim buffer list.

This plugin needs Vim 8.2 and above and will work on all the platforms where
Vim is supported. This plugin will work in both console and GUI Vim.

The command :Bufselect opens a popup menu with a list of names of buffers in
the Vim buffer list (|:buffers|). When you press <Enter> on a buffer name, the
buffer is opened. If the selected buffer is already opened in a window, the
cursor will move to that window.  If the buffer it not present in any of the
windows, then the selected buffer will be opened in the current window.  You
can use the up and down arrow keys to move the currently selected entry in the
popup menu.

In the popup menu, you can type a series of characters to narrow down the list
of displayed buffer names. The characters entered so far is displayed in the
popup menu title. You can press backspace to erase the previously entered set
of characters. The popup menu displays all the buffer names containing the
series of typed characters.

You can close the popup menu by pressing the escape key or by pressing CTRL-C.

In the popup menu, the complete directory path to a buffer is displayed in
parenthesis after the buffer name. If this is too long, then the path is
shortened and an abbreviated path is displayed.
