# FFmpeg utilities

ffmpeg-stereo-downmix() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: ffmpeg-stereo-downmix <input> <output>"
        return 1
    fi
    
    local input="$1"
    local output="$2"
    
    # Detect channel layout
    local channels=$(ffprobe -v quiet -select_streams a:0 -show_entries stream=channels -of csv=p=0 "$input")
    
    local filter=""
    case $channels in
        6)
            # 5.1 surround - Dave750 algorithm as found in Jellyfin
            filter="pan=stereo|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3"
            ;;
        8)
            # 7.1 surround - first downmix to 5.1 using AC-4, then to stereo using Dave750 algorithm as found in Jellyfin
            filter="pan=5.1(side)|c0=c0|c1=c1|c2=c2|c3=c3|c4=0.707*c4+0.707*c6|c5=0.707*c5+0.707*c7,pan=stereo|c0=0.5*c2+0.707*c0+0.707*c4+0.5*c3|c1=0.5*c2+0.707*c1+0.707*c5+0.5*c3"
            ;;
        *)
            # Default stereo downmix for other configurations
            filter="pan=stereo|c0=0.707*c0+0.707*c2|c1=0.707*c1+0.707*c2"
            ;;
    esac
    
    ffmpeg -i "$input" -af "$filter" "$output"
}