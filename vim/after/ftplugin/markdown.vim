if exists('b:md_preview_loaded') | finish | endif
let b:md_preview_loaded = 1

function! s:MdCompile() abort
  let l:src = expand('%:p')
  let l:pdf = fnamemodify(l:src, ':r') . '.pdf'
  call job_start(['pandoc', l:src, '--pdf-engine=typst', '-o', l:pdf],
        \ {'out_io': 'null', 'err_io': 'null'})
endfunction

function! s:MdPreview() abort
  if empty(expand('%:p')) | echoerr 'Save the file first' | return | endif
  let l:pdf = fnamemodify(expand('%:p'), ':r') . '.pdf'

  if !filereadable(l:pdf)
    call system('pandoc ' . shellescape(expand('%:p'))
          \ . ' --pdf-engine=typst -o ' . shellescape(l:pdf))
  endif
  if v:shell_error
    echohl ErrorMsg | echom 'pandoc failed' | echohl None | return
  endif

  if !exists('b:md_viewer') || job_status(b:md_viewer) !=# 'run'
    let b:md_viewer = job_start(['zathura', l:pdf],
          \ {'out_io': 'null', 'err_io': 'null'})
  endif

  let b:md_preview_active = 1
endfunction

nnoremap <buffer> <silent> \p :call <SID>MdPreview()<CR>

set updatetime=400
augroup MdPreview
  autocmd! * <buffer>
  autocmd CursorHold,CursorHoldI <buffer>
        \ if &modified && !empty(expand('%:p')) | silent write | endif
  autocmd BufWritePost <buffer>
        \ if get(b:, 'md_preview_active', 0) | call <SID>MdCompile() | endif
  autocmd BufUnload <buffer> silent! call job_stop(b:md_viewer)
augroup END
