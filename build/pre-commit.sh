path="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$path/developer.env" && swift test
