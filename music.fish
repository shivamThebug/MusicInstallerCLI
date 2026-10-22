function music --description 'Search YouTube Music, show aligned results, download pick as MP3'
    set -l DOWNLOAD_DIR "$HOME/Downloads/Music"
    mkdir -p $DOWNLOAD_DIR

    if test (count $argv) -eq 0
        echo "Usage: music <search term>"
        return 1
    end

    set -l query (string join "+" $argv)
    echo ""
    echo (set_color cyan)"🔎 Searching: "(set_color normal)(string join " " $argv)
    echo ""

    set -l raw (yt-dlp "https://music.youtube.com/search?q=$query" \
        --flat-playlist \
        --print "%(title)s|||%(channel)s|||%(webpage_url)s" 2>/dev/null)

    if test -z "$raw"
        echo (set_color yellow)"⚠️  No YouTube Music results, falling back to YouTube search..."(set_color normal)
        set raw (yt-dlp "ytsearch10:"(string join " " $argv) \
            --flat-playlist \
            --print "%(title)s|||%(channel)s|||%(webpage_url)s" 2>/dev/null)
    end

    if test -z "$raw"
        echo (set_color red)"❌ No results found."(set_color normal)
        return 1
    end

    set -l lines
    for line in $raw
        set -a lines $line
    end

    # Column widths
    set -l NUM_W 3
    set -l TITLE_W 45
    set -l ARTIST_W 25

    # Header
    printf "  %-*s %-*s %-*s\n" $NUM_W "#" $TITLE_W "TITLE" $ARTIST_W "ARTIST"
    printf "  %s\n" (string repeat -n (math $NUM_W + $TITLE_W + $ARTIST_W + 2) "─")

    set -l i 1
    for line in $lines
        set -l parts (string split "|||" $line)
        set -l title (string sub -l $TITLE_W $parts[1])
        set -l artist (string sub -l $ARTIST_W $parts[2])

        printf "  %-*s %-*s %-*s\n" $NUM_W "$i)" $TITLE_W "$title" $ARTIST_W "$artist"
        set i (math $i + 1)
    end

    echo ""
    echo -n (set_color green)"Pick a number (or 0 to cancel): "(set_color normal)
    read -l choice

    if test "$choice" = "0" -o -z "$choice"
        echo "Cancelled."
        return 0
    end

    set -l selected $lines[$choice]
    if test -z "$selected"
        echo (set_color red)"❌ Invalid choice."(set_color normal)
        return 1
    end

    set -l parts (string split "|||" $selected)
    set -l title $parts[1]
    set -l artist $parts[2]
    set -l url $parts[3]

    echo ""
    echo (set_color cyan)"⬇️  Downloading: "(set_color normal)"$title — $artist"

    yt-dlp -x --audio-format mp3 --audio-quality 0 \
        --embed-thumbnail --add-metadata \
        -o "$DOWNLOAD_DIR/%(title)s - %(channel)s.%(ext)s" \
        "$url"

    echo (set_color green)"✅ Saved to $DOWNLOAD_DIR"(set_color normal)
end
