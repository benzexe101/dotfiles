if exists('b:md_preview_loaded') | finish | endif
let b:md_preview_loaded = 1

function! MarkdownPreviewCompile() abort
  let l:src = expand('%:p')
  let l:pdf = fnamemodify(l:src, ':r') . '.pdf'
  let l:tmp = fnamemodify(l:pdf, ':r') . '.tmp.pdf'
  call job_start(['sh', '-c', 'pandoc ' . shellescape(l:src)
        \ . ' --pdf-engine=typst -o ' . shellescape(l:tmp)
        \ . ' && cat ' . shellescape(l:tmp) . ' > ' . shellescape(l:pdf)
        \ . ' && rm -f ' . shellescape(l:tmp)],
        \ {'out_io': 'null', 'err_io': 'null'})
endfunction

function! MarkdownAutoSave(timer) abort
  if &filetype ==# 'markdown' && &modified && !empty(expand('%:p'))
    silent! write
  endif
endfunction

function! MarkdownPreviewStart() abort
  if empty(expand('%:p')) | echoerr 'Save the file first' | return | endif
  let l:pdf = fnamemodify(expand('%:p'), ':r') . '.pdf'

  if !filereadable(l:pdf)
    call system('pandoc ' . shellescape(expand('%:p'))
          \ . ' --pdf-engine=typst -o ' . shellescape(l:pdf))
    if v:shell_error
      echohl ErrorMsg | echom 'pandoc failed' | echohl None | return
    endif
  endif

  if !exists('b:md_viewer') || job_status(b:md_viewer) !=# 'run'
    let b:md_viewer = job_start(['zathura', l:pdf],
          \ {'out_io': 'null', 'err_io': 'null'})
  endif

  if !exists('g:md_save_timer')
    let g:md_save_timer = timer_start(700, 'MarkdownAutoSave', {'repeat': -1})
  endif

  let b:md_preview_active = 1
endfunction

nnoremap <buffer> <silent> \p :call MarkdownPreviewStart()<CR>

augroup MdPreview
  autocmd! * <buffer>
  autocmd BufWritePost <buffer>
        \ if get(b:, 'md_preview_active', 0) | call MarkdownPreviewCompile() | endif
  autocmd BufUnload <buffer> silent! call job_stop(b:md_viewer)
augroup END
