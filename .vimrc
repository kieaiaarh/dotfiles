" カーソルを行頭、行末で止まらないようにする
set whichwrap=b,s,h,l,<,>,[,]

" https://vim-jp.org/vimdoc-ja/options.html#'maxmempattern'
set maxmempattern=2000000
" backspace working
set backspace=indent,eol,start
highlight LineNr ctermfg=darkyellow
" カラースキーマの指定
colorscheme desert
" コマンドラインに使われる画面上の行数
set cmdheight=2
" " エディタウィンドウの末尾から2行目にステータスラインを常時表示させる
set laststatus=2
set binary noeol
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
set softtabstop=2
set incsearch
set hidden
" set list
" タブと行の続きを可視化する
" set listchars=tab:>\ ,extends:<
set listchars=tab:>.,trail:-,eol:$,nbsp:%

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
"#####検索設定#####
set ignorecase "大文字/小文字の区別なく検索する
set smartcase "検索文字列に大文字が含まれている場合は区別して検索する
set wrapscan "検索時に最後まで行ったら最初に戻る
"###### クリップボード有効化
set clipboard+=unnamed
"######コメントをグレーにする
hi Comment ctermfg=gray
"######カーソル位置
set ruler
set cursorline
set listchars=tab:▸\ ,eol:↲,extends:❯,precedes:❮

""""""""""""""""""""""""""""""
" プラグインのセットアップ
""""""""""""""""""""""""""""""
if has('vim_starting')
set nocompatible      " Be iMproved
" Required:
set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

" Required:
call neobundle#begin(expand('~/.vim/bundle/'))

" Let NeoBundle manage NeoBundle
" Required:
NeoBundleFetch 'Shougo/neobundle.vim'

" html 補完
NeoBundle 'mattn/emmet-vim'

NeoBundle 'tpope/vim-endwise'
NeoBundle 'slim-template/vim-slim'

" ファイルオープンを便利に
NeoBundle 'Shougo/unite.vim'
" Unite.vimで最近使ったファイルを表示できるようにする
NeoBundle 'Shougo/neomru.vim'

NeoBundle 'posva/vim-vue'

" シングルクオートとダブルクオートの入れ替え等
NeoBundle 'tpope/vim-surround'

" インデントに色を付けて見やすくする
NeoBundle 'nathanaelkane/vim-indent-guides'

NeoBundle 'Shougo/neocomplcache'
NeoBundle 'Shougo/neocomplete'

" ログファイルを色づけしてくれる
NeoBundle 'vim-scripts/AnsiEsc.vim'

" 行末の半角スペースを可視化
NeoBundle 'bronson/vim-trailing-whitespace'

" Gitを便利に使う
NeoBundle 'tpope/vim-fugitive'
"
" """"""""""""""""""""""""""""""
" ファイルをtree表示してくれる
NeoBundle 'scrooloose/nerdtree'
NeoBundle "tyru/caw.vim.git"
call neobundle#end()

" Required:
" filetype plugin indent on

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
let g:neocomplete#enable_at_startup = 1


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
nnoremap sq :<C-u>q<CR>
nnoremap sQ :<C-u>bd<CR>
nnoremap sb :<C-u>Unite buffer_tab -buffer-name=file<CR>
nnoremap sB :<C-u>Unite buffer -buffer-name=file<CR>

autocmd FileType vue syntax sync fromstart

nnoremap de :<C-u>FixWhitespace<CR>
" tcomment_vim
nmap <C-K> <Plug>(caw:i:toggle)
vmap <C-K> <Plug>(caw:i:toggle)

" continuous indent
vnoremap <silent> > >gv
vnoremap <silent> < <gv

" Jedi is by default automatically initialized for python
let g:jedi#auto_initialization = 0
let g:jedi#use_tabs_not_buffers = 1

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_aggregate_errors = 1

" https://qiita.com/muran001/items/9ce24525b3285678acc3#%E3%81%A1%E3%82%87%E3%81%A3%E3%81%A8%E3%81%A0%E3%81%91%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%9E%E3%82%A4%E3%82%BA
let g:user_emmet_leader_key='<c-t>'

"https://github.com/vim-syntastic/syntastic
execute pathogen#infect()
syntax on
filetype plugin indent on

" 正規表現を普通にする
" https://qiita.com/m-yamashita/items/5755ca2717c8d5be57e4
nmap / /\v

" vueファイルコメントアウト
let g:ft = ''
function! NERDCommenter_before()
  if &ft == 'vue'
    let g:ft = 'vue'
    let stack = synstack(line('.'), col('.'))
    if len(stack) > 0
      let syn = synIDattr((stack)[0], 'name')
      if len(syn) > 0
        exe 'setf ' . substitute(tolower(syn), '^vue_', '', '')
      endif
    endif
  endif
endfunction
function! NERDCommenter_after()
  if g:ft == 'vue'
    setf vue
    let g:ft = ''
  endif
endfunction
