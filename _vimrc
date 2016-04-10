set encoding=utf-8
set fileencodings=utf-8,euc-jp,iso-2022-jp,sjis
" 改行コード
set fileformats=unix,dos,mac
" カーソルを行頭、行末で止まらないようにする
set whichwrap=b,s,h,l,<,>,[,]
" backspace working
set backspace=indent,eol,start
highlight LineNr ctermfg=darkyellow
" カラースキーマの指定
colorscheme desert
" コマンドラインに使われる画面上の行数
set cmdheight=2
" " エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
set laststatus=2
" "
" ステータス行に表示させる情報の指定(どこからかコピペしたので細かい意味はわかっていない)
set statusline=%<%f\%m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,%c%V%8P

" " ステータス行に現在のgitブランチを表示する
set statusline+=%{fugitive#statusline()}
" " ウインドウのタイトルバーにファイルのパス情報等を表示する
set title
" " コマンドラインモードで<Tab>キーによるファイル名補完を有効にする
set wildmenu
" " 入力中のコマンドを表示する
set showcmd
" バッファで開いているファイルのディレクトリでエクスクローラを開始する(でもエクスプローラって使ってない)
set browsedir=buffer
set expandtab
set incsearch
set hidden
set list
" タブと行の続きを可視化する
set listchars=tab:>\ ,extends:<

set noswapfile
set number "行番号を表示する
set title "編集中のファイル名を表示
set showmatch "括弧入力時の対応する括弧を表示
syntax on "コードの色分け
set tabstop=2 "インデントをスペース2つ分に設定
set smartindent "オートインデント

" Vimが挿入するインデントの幅
set shiftwidth=2
set smarttab
set hlsearch
" python indent
autocmd FileType python setl autoindent
autocmd FileType python setl smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
autocmd FileType python setl tabstop=8 expandtab shiftwidth=4 softtabstop=4

"#####検索設定#####
set ignorecase "大文字/小文字の区別なく検索する
set smartcase "検索文字列に大文字が含まれている場合は区別して検索する
set wrapscan "検索時に最後まで行ったら最初に戻る
"###### クリップボード有効化
set clipboard=unnamed
"######コメントをグレーにする
hi Comment ctermfg=gray
"######カーソル位置
set ruler
set cursorline
"set listchars=tab:▸\ ,eol:↲,extends:❯,precedes:❮

"####連続インデント↲
vnoremap <silent> > >gv
vnoremap <silent> < <gv

""""""""""""""""""""""""""""""
" プラグインのセットアップ
""""""""""""""""""""""""""""""
if has('vim_starting')
set nocompatible      " Be iMproved
filetype off
" Required:
set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" Required:
call neobundle#begin(expand('~/.vim/bundle/'))
call neobundle#load_cache()
" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

NeoBundle 'junegunn/vim-easy-align'

"for rails
NeoBundle 'tpope/vim-rails'
NeoBundle 'tpope/vim-endwise'

"autoclose"
NeoBundle 'Townk/vim-autoclose'

" シングルクオートとダブルクオートの入れ替え等
NeoBundle 'tpope/vim-surround'
"vimshell
NeoBundle 'Shougo/vimshell'
NeoBundle 'Shougo/vimproc.vim', {
      \ 'build' : {
      \     'windows' : 'tools\\update-dll-mingw',
      \     'cygwin' : 'make -f make_cygwin.mak',
      \     'mac' : 'make -f make_mac.mak',
      \     'linux' : 'make',
      \     'unix' : 'gmake',
      \    },
      \ }
" ファイルオープンを便利に
NeoBundle 'Shougo/unite.vim'
" Unite.vimで最近使ったファイルを表示できるようにする
NeoBundle 'Shougo/neomru.vim'

" シングルクオートとダブルクオートの入れ替え等
NeoBundle 'tpope/vim-surround'

" インデントに色を付けて見やすくする
NeoBundle 'nathanaelkane/vim-indent-guides'

" ログファイルを色づけしてくれる
NeoBundle 'vim-scripts/AnsiEsc.vim'

" 行末の半角スペースを可視化
NeoBundle 'bronson/vim-trailing-whitespace'

" Gitを便利に使う
NeoBundle 'tpope/vim-fugitive'

NeoBundle 'mattn/emmet-vim'

"neocomplcache
NeoBundle 'Shougo/neocomplcache'
" 一括コメントアウト
NeoBundle "tyru/caw.vim.git"
"
" """"""""""""""""""""""""""""""
" ファイルをtree表示してくれる
NeoBundle 'scrooloose/nerdtree'
NeoBundle 'tomtom/tcomment_vim'

NeoBundle 'grep.vim'

NeoBundleSaveCache
call neobundle#end()

" Required:
filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck

" """"""""""""""""""""""""""""""
" " Unit.vimの設定
" """"""""""""""""""""""""""""""
" " 入力モードで開始する
let g:unite_enable_start_insert=1
" " バッファ一覧
noremap <C-P> :Unite buffer<CR>
" " ファイル一覧
noremap <C-N> :Unite -buffer-name=file file<CR>
" " 最近使ったファイルの一覧
noremap <C-Z> :Unite file_mru<CR>
" " sourcesを「今開いているファイルのディレクトリ」とする
noremap :uff :<C-u>UniteWithBufferDir file -buffer-name=file<CR>
" " ウィンドウを分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-J>
"unite#do_action('split')
au FileType unite inoremap <silent> <buffer> <expr> <C-J>
"unite#do_action('split')
" " ウィンドウを縦に分割して開く
au FileType unite nnoremap <silent> <buffer> <expr> <C-K>
"unite#do_action('vsplit')
au FileType unite inoremap <silent> <buffer> <expr> <C-K>
"unite#do_action('vsplit')
" " ESCキーを2回押すと終了する
au FileType unite nnoremap <silent> <buffer> <ESC><ESC> :q<CR>
au FileType unite inoremap <silent> <buffer> <ESC><ESC> <ESC>:q<CR>

" Easy Align
" Start interactive EasyAlign in visual mode (e.g. vip<Enter>)
vmap <Enter> <Plug>(EasyAlign)
" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

function! ZenkakuSpace()
    highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=darkgray
endfunction
"全角スペース表示
if has('syntax')
	augroup ZenkakuSpace
	autocmd!
	autocmd ColorScheme * call ZenkakuSpace()
	autocmd VimEnter,WinEnter,BufRead * let w:m1=matchadd('ZenkakuSpace', '　')
	augroup END
	call ZenkakuSpace()
endif

"挿入モード表示

let g:hi_insert = 'highlight StatusLine guifg=darkblue guibg=darkyellow gui=none ctermfg=blue ctermbg=yellow cterm=none'

if has('syntax')
augroup InsertHook
autocmd!
autocmd InsertEnter * call s:StatusLine('Enter')
autocmd InsertLeave * call s:StatusLine('Leave')
augroup END
endif

let s:slhlcmd = ''
function! s:StatusLine(mode)
if a:mode == 'Enter'
  silent! let s:slhlcmd = 'highlight ' . s:GetHighlight('StatusLine')
  silent exec g:hi_insert
else
  highlight clear StatusLine
  silent exec s:slhlcmd
endif
endfunction

function! s:GetHighlight(hi)
  redir => hl
  exec 'highlight '.a:hi
  redir END
  let hl = substitute(hl, '[\r\n]', '', 'g')
	let hl = substitute(hl, 'xxx', '', '')
	return hl
endfunction" コメントON/OFFを手軽に実行

" vimを立ち上げたときに、自動的にvim-indent-guidesをオンにする
let g:indent_guides_enable_on_vim_startup = 1


" grep検索の実行後にQuickFix Listを表示する
autocmd QuickFixCmdPost *grep* cwindow



"キーマッピング
nnoremap s <Nop>
nnoremap sj <C-w>j
nnoremap sk <C-w>k
nnoremap sl <C-w>l
nnoremap sh <C-w>h
nnoremap sJ <C-w>J
nnoremap sK <C-w>K
nnoremap sL <C-w>L
nnoremap sH <C-w>H
nnoremap sn gt
nnoremap sp gT
nnoremap sr <C-w>r
nnoremap s= <C-w>=
nnoremap sw <C-w>w
nnoremap so <C-w>_<C-w>|
nnoremap sO <C-w>=
nnoremap sN :<C-u>bn<CR>
nnoremap sP :<C-u>bp<CR>
nnoremap st :<C-u>tabnew<CR>
nnoremap sT :<C-u>Unite tab<CR>
nnoremap ss :<C-u>sp<CR>
nnoremap sv :<C-u>vs<CR>
nnoremap sq :<C-u>q!<CR>
nnoremap sQ :<C-u>bd<CR>
nnoremap sb :<C-u>Unite buffer_tab -buffer-name=file<CR>
nnoremap sB :<C-u>Unite buffer -buffer-name=file<CR>
nnoremap <silent><C-e> :NERDTreeToggle<CR>
noremap!  

" vimshell setting
let g:vimshell_interactive_update_time = 10
let g:vimshell_prompt = "$ "
let g:vimshell_user_prompt = 'getcwd()'

" vimshell map
nnoremap <silent> vs :VimShell<CR>
nnoremap <silent> vsc :VimShellCreate<CR>
nnoremap <silent> vp :VimShellPop<CR>
" delete Space
nnoremap <silent> dw :FixWhitespace<CR>
" rails server start/stop
nnoremap <silent> rs  :Rserver -b 192.168.33.16<CR>
nnoremap <silent> rt :Rserver! -b 192.168.33.16<CR>

" commentout
nmap <C-K> <Plug>(caw:i:toggle)
vmap <C-K> <Plug>(caw:i:toggle)

let g:user_emmet_leader_key='<c-t>'
let g:user_emmet_settings = {
    \    'variables': {
    \      'lang': "ja"
    \    },
    \   'indentation': '  '
    \ }


"" php syntax check
augroup PHP
  autocmd!
  autocmd FileType php set makeprg=php\ -l\ %
  " php -lの構文チェックでエラーがなければ「No syntax errors」の一行だけ出力される
  autocmd BufWritePost *.php silent make | if len(getqflist()) != 1 | copen | else | cclose | endif
augroup END
syntax on

"neocompelte
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplcache.
let g:neocomplcache_enable_at_startup = 1
" Use smartcase.
let g:neocomplcache_enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplcache_dictionary_filetype_lists = {
    \ 'default' : ''
\ }
"
" Plugin key-mappings.
inoremap <expr><C-g>     neocomplcache#undo_completion()
inoremap <expr><C-l>     neocomplcache#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
" inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
" function! s:my_cr_function()
"   return neocomplcache#smart_close_popup() . "\<CR>"
" endfunction
" "<TAB>: completion.
" inoremap <expr><TAB>  pumvisible() ? "\<C-n>: "\<TAB>"
" "<C-h>, <BS>: close popup and delete backword char.
" inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
" inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
" inoremap <expr><C-y>  neocomplcache#close_popup()
" inoremap <expr><C-e>  neocomplcache#cancel_popup()

" stop insert mode
inoremap <silent> kk <ESC>
