cdf() { P=$(mktemp -u) && mkfifo $P && exec 3<>$P && rm $P ; ftl ; read -ru 3 d ; [[ "$d" ]] && cd "$(dirname "$d")" ; }

