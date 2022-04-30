path="$(dirname "$(readlink -f $BASH_SOURCE)")"

source "$path/developer.env"
time {
    swift test
    result=$?
}

[[ $result -eq 0 ]] && echo "🤡" || echo "💀"
exit $result
