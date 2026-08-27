if exists('b:typst_preview_loaded') | finish | endif
let b:typst_preview_loaded = 1

function! s:TypstPreview() abort
  if empty(expand('%:p')) | echoerr 'Save the file first' | return | endif
  let l:src = expand('%:p')
  let l:pdf = fnamemodify(l:src, ':r') . '.pdf'

  if !filereadable(l:pdf)
    call system('typst compile ' . shellescape(l:src))
  endif

  if !exists('b:typst_watch') || job_status(b:typst_watch) !=# 'run'
    let b:typst_watch = job_start(['typst', 'watch', l:src],
          \ {'out_io': 'null', 'err_io': 'null'})
  endif

  if !exists('b:typst_viewer') || job_status(b:typst_viewer) !=# 'run'
    let b:typst_viewer = job_start(['zathura', l:pdf],
          \ {'out_io': 'null', 'err_io': 'null'})
  endif
endfunction

nnoremap <buffer> <silent> \p :call <SID>TypstPreview()<CR>

autocmd BufUnload <buffer> silent! call job_stop(b:typst_watch)
autocmd BufUnload <buffer> silent! call job_stop(b:typst_viewer)

set updatetime=400
augroup TypstAutoSave
  autocmd! * <buffer>
  autocmd CursorHold,CursorHoldI <buffer>
        \ if &modified && !empty(expand('%:p')) | silent write | endif
augroup END
