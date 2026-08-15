function run --description 'build and run current cmake project'
    set -l name (basename $PWD)
    cmake --build build; and ./build/$name
end
