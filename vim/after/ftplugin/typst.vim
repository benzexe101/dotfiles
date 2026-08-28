if exists('b:typst_preview_loaded') | finish | endif
let b:typst_preview_loaded = 1

function! TypstAutoSave(timer) abort
  if &filetype ==# 'typst' && &modified && !empty(expand('%:p'))
    silent! write
  endif
endfunction

function! TypstPreviewStart() abort
  if empty(expand('%:p')) | echoerr 'Save the file first' | return | endif
  let l:src = expand('%:p')
  let l:pdf = fnamemodify(l:src, ':r') . '.pdf'

  if !filereadable(l:pdf)
    call system('typst compile ' . shellescape(l:src))
    if v:shell_error
      echohl ErrorMsg | echom 'typst compile failed' | echohl None | return
    endif
  endif

  if !exists('b:typst_watch') || job_status(b:typst_watch) !=# 'run'
    let b:typst_watch = job_start(['typst', 'watch', l:src],
          \ {'out_io': 'null', 'err_io': 'null'})
  endif

  if !exists('b:typst_viewer') || job_status(b:typst_viewer) !=# 'run'
    let b:typst_viewer = job_start(['zathura', l:pdf],
          \ {'out_io': 'null', 'err_io': 'null'})
  endif

  if !exists('g:typst_save_timer')
    let g:typst_save_timer = timer_start(700, 'TypstAutoSave', {'repeat': -1})
  endif
endfunction

nnoremap <buffer> <silent> \p :call TypstPreviewStart()<CR>

augroup TypstPreview
  autocmd! * <buffer>
  autocmd BufUnload <buffer> silent! call job_stop(b:typst_watch)
  autocmd BufUnload <buffer> silent! call job_stop(b:typst_viewer)
augroup END
