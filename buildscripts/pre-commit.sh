path="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$path/developer.env"
time {
    swift test && echo "🤡" || echo "💀"
}
