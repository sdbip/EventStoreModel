path="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$path/developer.env" && echo "swift test"
