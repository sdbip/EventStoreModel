builddir="$(readlink -f build)"
symlink=.git/hooks/pre-commit

[ -e build/developer.env ] || touch build/developer.env

## Add Git Pre-Commit hook
[ -h .git/hooks/pre-commit ] || ln -s "$builddir/pre-commit.sh" $symlink
source $symlink
