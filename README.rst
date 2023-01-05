Buflist Popup
=============

Plugin to display the list of buffers currently open in a
popup window in ``Vim`` or a floating window in ``Neovim``.

.. image:: https://github.com/stemoretti/vim-buflist-popup/raw/github_files/preview.gif

Installation
------------

This plugin can be installed without using any plugin manager.
Just clone the repository in the folder where the editor expects to find
the plugins. See ``:help add-plugin`` for the details.

To make the documentation available to the ``:help`` command see
``:help helptags``.

vim-plug
^^^^^^^^

Add the text below to the configuration file.

    Plug 'stemoretti/vim-buflist-popup'

Then run ``:PlugInstall``.

Usage
-----

The default keybinding to show the list is ``_`` (underscore).
It can be redefined by mapping a key to either ``<Plug>(BuflistPopupShow)``
or the command ``:BuflistPopupShow``.

You can switch directly to a buffer by typing its index number or you can
move the cursor up and down the list using the keys ``j/k`` and then press
``enter`` to load the selected buffer in the current window.

See ``:help vim-buflist-popup`` for more information.
