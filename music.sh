#!/usr/bin/env bash
# music: Search YouTube Music, show aligned results, download pick as MP3
# Usage: music <search term>
# Source this file from your .bashrc (e.g. `source ~/music.sh`) to use it
# as a shell function, or run it directly as a script.

music() {
    # zsh arrays are 1-indexed by default; ksh_arrays makes them 0-indexed
    # like bash, so the rest of this function behaves the same in both shells.
    if [ -n "$ZSH_VERSION" ]; then
        setopt local_options ksh_arrays sh_word_split
    fi

    local DOWNLOAD_DIR="$HOME/Downloads/Music"
    mkdir -p "$DOWNLOAD_DIR"

    if [ "$#" -eq 0 ]; then
        echo "Usage: music <search term>"
        return 1
    fi

    # Colors
    local cyan=$'\033[36m'
    local yellow=$'\033[33m'
    local red=$'\033[31m'
    local green=$'\033[32m'
    local normal=$'\033[0m'

    local query
    query=$(IFS=+; echo "$*")

    echo ""
    echo "${cyan}🔎 Searching: ${normal}$*"
    echo ""

    local raw
    raw=$(yt-dlp "https://music.youtube.com/search?q=${query}" \
        --flat-playlist \
        --print "%(title)s|||%(channel)s|||%(webpage_url)s" 2>/dev/null)

    if [ -z "$raw" ]; then
        echo "${yellow}⚠️  No YouTube Music results, falling back to YouTube search...${normal}"
        raw=$(yt-dlp "ytsearch10:$*" \
            --flat-playlist \
            --print "%(title)s|||%(channel)s|||%(webpage_url)s" 2>/dev/null)
    fi

    if [ -z "$raw" ]; then
        echo "${red}❌ No results found.${normal}"
        return 1
    fi

    # Load lines into an array
    local lines=()
    while IFS= read -r line; do
        [ -n "$line" ] && lines+=("$line")
    done <<< "$raw"

    # Column widths
    local NUM_W=3
    local TITLE_W=45
    local ARTIST_W=25

    # Header
    printf "  %-*s %-*s %-*s\n" "$NUM_W" "#" "$TITLE_W" "TITLE" "$ARTIST_W" "ARTIST"
    printf "  %s\n" "$(printf '─%.0s' $(seq 1 $((NUM_W + TITLE_W + ARTIST_W + 2))))"

    local i=1
    local title artist
    for line in "${lines[@]}"; do
        title="${line%%|||*}"
        local rest="${line#*|||}"
        artist="${rest%%|||*}"

        printf "  %-*s %-*.${TITLE_W}s %-*.${ARTIST_W}s\n" "$NUM_W" "${i})" "$TITLE_W" "$title" "$ARTIST_W" "$artist"
        i=$((i + 1))
    done

    echo ""
    echo -n "${green}Pick a number (or 0 to cancel): ${normal}"
    read -r choice

    if [ "$choice" = "0" ] || [ -z "$choice" ]; then
        echo "Cancelled."
        return 0
    fi

    local idx=$((choice - 1))
    if [ "$idx" -lt 0 ] || [ "$idx" -ge "${#lines[@]}" ]; then
        echo "${red}❌ Invalid choice.${normal}"
        return 1
    fi

    local selected="${lines[$idx]}"
    if [ -z "$selected" ]; then
        echo "${red}❌ Invalid choice.${normal}"
        return 1
    fi

    local sel_title="${selected%%|||*}"
    local sel_rest="${selected#*|||}"
    local sel_artist="${sel_rest%%|||*}"
    local sel_url="${selected##*|||}"

    echo ""
    echo "${cyan}⬇️  Downloading: ${normal}${sel_title} — ${sel_artist}"

    yt-dlp -x --audio-format mp3 --audio-quality 0 \
        --embed-thumbnail --add-metadata \
        -o "$DOWNLOAD_DIR/%(title)s - %(channel)s.%(ext)s" \
        "$sel_url"

    echo "${green}✅ Saved to $DOWNLOAD_DIR${normal}"
}
