#!/bin/bash
set -euo pipefail

repeat() {
    # Output a string consisting of $1 copies of character $2
    printf "%${1}s" | tr ' ' "$2"
}

# Binaries from my geom2018 repo live here
GEOMDIR="../geom2018/bin"

# Input & output directories of this script
SITE_INDIR="src"
SITE_OUTDIR="dst"

# Keep a newline around in a variable
NL='
'

# Separator token for "code blocks"
BLOCKSEP='```'

# Command which converts .fus to .html (from geom2018 repo)
LEXERTOOL="$GEOMDIR/lexertool"
fus2html() {
    "$LEXERTOOL" -r --html
}

# Directory containing the .fus files used by blocks of type "fusfig"
# (and related directories...)
FUSFIG_DIR="src/figures"
FUSFIG_OUTDIR="fusfig/dst"
FUSFIG_STATIC="figs"
FUSFIG_STATICDIR="$SITE_OUTDIR/$FUSFIG_STATIC"
FUSFIG_EXT="png"

# The minieditor command from geom2018 repo
MINIEDITOR="$GEOMDIR/minieditor"
minieditor() {
    "$MINIEDITOR" --pal fusfig/pal.fus --font fusfig/font.fus --fonts fusfig/fonts.fus "$@"
}
MINIEDITOR_SCREENSHOT="screen.bmp"

# Name of the website we're building
SITENAME="bayersglassey.com"

# Set up variables so we can easily print horizontal lines
LINEWIDTH=60
THINLINE="$(repeat "$LINEWIDTH" '-')"
THICKLINE="$(repeat "$LINEWIDTH" '#')"


log_depth=0
log() {
    repeat "$log_depth" "  "
    echo "=== $@" >&2
}

do_with_log() {
    log "Executing: $@"
    "$@"
}

print_thinline() {
    echo "$THINLINE" >&2
}

print_thickline() {
    echo "$THICKLINE" >&2
}

require_cmd() {
    command -v "$1" >/dev/null || {
        log "Missing required command: $1"
        exit 1
    }
}

# Markdown parser command, we feed it Markdown and expect HTML back.
# Currently using `apt install markdown`
require_cmd markdown

require_cmd "$LEXERTOOL"
require_cmd "$MINIEDITOR"


#############################################################################

pageurl() {
    # Usage: pageurl OUTFILE
    PAGEURL_FILENAME="`echo "$1" | sed "s@/root/@/@"`"
    echo "/${PAGEURL_FILENAME#$SITE_OUTDIR/}"
}

htmlescape() {
    # Based on: https://stackoverflow.com/a/12873723
    sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e 's/'"'"'/\&#39;/g'
}

chop() {
    # Usage: chop DATA SEPARATOR
    # Chops DATA into two substrings at the first occurrence of SEPARATOR.
    # The substrings are returned in HEAD and TAIL.
    HEAD="${1%%"$2"*}"
    TAIL="${1#*"$2"}"
}

replace() {
    # Usage: replace STR1 STR2 STRING
    # Replaces first occurrence of STR1 with STR2 in STRING.
    # Returns the result in REPLACED.
    chop "$3" "$1"
    REPLACED="$HEAD$2$TAIL"
}

parseblocks() {
    # Usage: parseblocks DATA
    # Parses DATA, replacing blocks with "{BLOCKxxx}" where xxx is a nonnegative integer.
    # The parsed string is returned in PARSED.
    # The data of each block xxx is stored in corresponding variables BLOCKxxx.
    # The type of each block xxx is stored in corresponding variables BLOCKTYPExxx.
    #
    # Example of a block (in this case, the type is "json"):
    #
    #     ```json
    #     {
    #         "a": 1,
    #         "b": 2
    #     }
    #     ```
    #
    # Example of iterating over the blocks:
    #
    #     for i in `seq "$BLOCKNUM"`
    #     do eval "echo \"Block \$i (\$BLOCKTYPE$i): \$BLOCK$i\""
    #     done
    #

    DATA="$1"
    PARSED=""
    BLOCKNUM=0

    while true
    do
        chop "$DATA" "$BLOCKSEP"
        test "$HEAD" != "$DATA" || break

        # BLOCKNUM was initialized to 0 outside the loop.
        # We increment it here *before* using it, so first blocknum is 1.
        # This is so that we can iterate over it using `seq $BLOCKNUM`.
        BLOCKNUM="`expr "$BLOCKNUM" + 1`"

        HEAD0="$HEAD"
        chop "$TAIL" "$NL"
        TYPE="$HEAD"
        chop "$TAIL" "$NL$BLOCKSEP"
        eval "BLOCK$BLOCKNUM=\"\$HEAD\""
        eval "BLOCKTYPE$BLOCKNUM=\"\$TYPE\""
        PARSED="$PARSED$HEAD0{BLOCK$BLOCKNUM}"
        DATA="$TAIL"
    done

    PARSED="$PARSED$DATA"
}

fusfig() {
    # Generate a figure from an rgraph in a .fus file.
    # Writes an <img> tag for the resulting image to stdout.
    FUSFIG_TYPE="$1"
    FUSFIG_FILENAME="$2"
    FUSFIG_RGRAPH="$3"
    shift 3

    FUSFIG_INFILE="$FUSFIG_DIR/$FUSFIG_FILENAME"
    FUSFIG_OUTSUBDIR="$FUSFIG_OUTDIR/${FUSFIG_FILENAME%.fus}"
    do_with_log mkdir -p "$FUSFIG_OUTSUBDIR"
    FUSFIG_OUTFILE="$FUSFIG_OUTSUBDIR/$FUSFIG_RGRAPH.$FUSFIG_EXT"
    FUSFIG_STATICFILE="/$FUSFIG_STATIC/${FUSFIG_FILENAME%.fus}/$FUSFIG_RGRAPH.$FUSFIG_EXT"

    log "Building fus figure: $FUSFIG_OUTFILE"
    do_with_log minieditor -f "$FUSFIG_INFILE" -n "$FUSFIG_RGRAPH" "$@" -q --nocontrols --screenshot
    do_with_log convert "$MINIEDITOR_SCREENSHOT" "$FUSFIG_OUTFILE"

    FUSFIG_FILENAME_OUTFILE_RAW="$SITE_OUTDIR/${FUSFIG_INFILE#$SITE_INDIR/}"
    FUSFIG_FILENAME_OUTFILE="${FUSFIG_FILENAME_OUTFILE_RAW%.*}.html"
    FUSFIG_FILENAME_OUTFILE_URL="`pageurl "$FUSFIG_FILENAME_OUTFILE"`"

    # Ganky "extensions" to the fusfig block type...
    case "$FUSFIG_TYPE" in
    *header*)
        echo "<h4><i>$FUSFIG_RGRAPH</i> (defined in <a href=\"$FUSFIG_FILENAME_OUTFILE_URL\">$FUSFIG_FILENAME</a>)</h4>"
    esac

    echo "<img src=\"$FUSFIG_STATICFILE\">"
}

# And so it begins.
print_thickline
log "Building site!"
log "Source directory: $SITE_INDIR"
log "Output directory: $SITE_OUTDIR"

# Create output directories
do_with_log rm -rf "$SITE_OUTDIR"
do_with_log mkdir -p "$SITE_OUTDIR"
do_with_log rm -rf "$FUSFIG_OUTDIR"
do_with_log mkdir -p "$FUSFIG_OUTDIR"

# Slurp header & footer HTML
HEADERFILE="$SITE_INDIR/header.html"
FOOTERFILE="$SITE_INDIR/footer.html"
HEADER="`cat $HEADERFILE`"
FOOTER="`cat $FOOTERFILE`"
# (Warning: command expansion removes trailing newlines!.. so $HEADER and
# $FOOTER won't have trailing newlines, even if the contents of $HEADERFILE
# and/or $FOOTERFILE do.)


bagcom_builddir() {
    ACTION="$1"
    INDIR="$2"

    OUTDIR="$SITE_OUTDIR/${INDIR#$SITE_INDIR/}"

    # $DIRCONFIGFILE: a file containing metadata about the pages in
    # $INDIR (for instance, about their "parent" page)
    DIRCONFIGFILE="$INDIR/dir.config"

    print_thinline
    log "Building dir (action=$ACTION): $INDIR -> $OUTDIR"

    # Variables which can be set by $DIRCONFIGFILE
    PARENTNAME=""
    PARENTURL=""

    # ...ok, set the variables please
    if test -f "$DIRCONFIGFILE"
    then
        log "Using dirconfig file: $DIRCONFIGFILE"
        . "$DIRCONFIGFILE"
    else
        log "...skipping missing dirconfig file: $DIRCONFIGFILE"
    fi

    log "PARENTNAME=$PARENTNAME"
    log "PARENTURL=$PARENTURL"

    if test "$ACTION" = "list"
    then
        # Create output directory
        do_with_log mkdir -p "$OUTDIR"

        # Copy static assets (if present)
        test ! -d "$INDIR/img" || do_with_log cp -r "$INDIR/img" "$OUTDIR/img"
    fi

    : $(( log_depth++ ))
    for INFILE in "$INDIR"/*
    do
        BASENAME="`basename -- "$INFILE"`"
        EXT="${BASENAME##*.}"

        # Only process files with these extensions
        test "$EXT" = "txt" -o "$EXT" = "html" -o "$EXT" = "md" -o "$EXT" = "fus" || continue

        OUTFILE_RAW="$SITE_OUTDIR/${INFILE#$SITE_INDIR/}"
        OUTFILE="${OUTFILE_RAW%.*}.html"
        OUTFILE_RAW_URL="`pageurl "$OUTFILE_RAW"`"

        print_thinline
        log "Processing file (action=$ACTION): $INFILE -> $OUTFILE"

        # $CONFIGFILE: a file containing metadata about the page whose
        # contents are in $INFILE
        CONFIGFILE="$INFILE.config"

        # Variables which can be set by $CONFIGFILE
        TITLE="${BASENAME/.*}"
        CHILDPAGES_DIR=""

        # ...ok, set the variables please
        if test -f "$CONFIGFILE"
        then
            log "Using config file: $CONFIGFILE"
            . "$CONFIGFILE"
        else
            log "...skipping missing config file: $CONFIGFILE"
        fi

        log "TITLE=$TITLE"
        log "CHILDPAGES_DIR=$CHILDPAGES_DIR"

        case "$ACTION" in
            list)
                log "Listing: $INFILE"
                log "Output: $OUTFILE"

                # Touch the file so it can be found when generating
                # CHILDPAGES
                do_with_log touch "$OUTFILE"

                # Store the title somewhere we can find it when
                # generating CHILDPAGES
                echo "$TITLE" >"$OUTFILE.title"
            ;;
            build)
                log "Building: $INFILE"
                log "Output: $OUTFILE"
                bagcom_buildfile
                log "Done!"
            ;;
            *)
                "Unrecognized action: $ACTION"
                exit 1
            ;;
        esac
    done
    : $(( log_depth-- ))
}

bagcom_buildfile() {
    log "Building file: $OUTFILE..."

    # NOTE: We use "@" as the separator in sed's "s" operator, which means
    # we can't use that character in a page's title!
    PROCESSED_HEADER="`echo "$HEADER" | sed \
        -e "s@{TITLE}@$TITLE@" \
        -e "s@{SITENAME}@$SITENAME@" \
        -e "s@{PARENTNAME}@$PARENTNAME@" \
        -e "s@{PARENTURL}@$PARENTURL@" \
    `"

    if test "$OUTFILE_RAW" != "$OUTFILE"
    then
        PROCESSED_HEADER="`echo "$PROCESSED_HEADER" | sed \
            -e "s@{RAWFILE}@$OUTFILE_RAW_URL@" \
        `"
    else
        # Remove (with sed's "d" command) lines which contain "{RAWFILE}"
        PROCESSED_HEADER="`echo "$PROCESSED_HEADER" | sed '/{RAWFILE}/d'`"
    fi

    # Remove any unneeded (according to this page's .config file)
    # breadcrumbs from header
    if test "$PARENTURL" = "/"
    then
        # Remove (with sed's "d" command) lines which start with "{CRUMB2}"
        log "*** REMOVING CRUMB2!"
        PROCESSED_HEADER="`echo "$PROCESSED_HEADER" | sed '/^{CRUMB2}/d'`"
    fi
    if test "$OUTFILE" = "dst/root/index.html"
    then
        # Remove (with sed's "d" command) lines which start with "{CRUMB1}"
        log "*** REMOVING CRUMB1!"
        PROCESSED_HEADER="`echo "$PROCESSED_HEADER" | sed '/^{CRUMB1}/d'`"
    fi

    # Remove "{CRUMB1}", "{CRUMB2}" markers
    PROCESSED_HEADER="`echo "$PROCESSED_HEADER" | sed 's/{CRUMB[12]}//'`"

    # Slurp page contents
    BODY="`cat "$INFILE"`"

    # Parse blocks, removing them from BODY.
    # We will put them back in after BODY has been otherwise processed.
    # This lets us implement e.g. custom syntax highlighting in
    # Markdown pages: after BODY is processed as Markdown into HTML, we
    # will put the processed blocks back in.
    parseblocks "$BODY"
    BODY="$PARSED"

    # Wrap the contents of .txt files in <pre>
    if test "$EXT" = "txt"
    then
        BODY="<pre>$BODY</pre>"
    fi

    # Process .md files as markdown
    # (Will fail, obviously, if you don't have a markdown parser installed)
    if test "$EXT" = "md"
    then
        BODY="`echo "$BODY" | markdown`"
    fi

    # Process .fus files
    if test "$EXT" = "fus"
    then
        BODY="<pre class=\"fus\">`echo "$BODY" | fus2html`</pre>"
    fi

    # Automatically generate lists of child pages (as directed by the
    # config file)
    if test -n "$CHILDPAGES_DIR"
    then
        BODY="$BODY$NL<ul>$NL"
        for CHILDPAGE_FILE in "$SITE_OUTDIR/$CHILDPAGES_DIR"/*.html
        do
            CHILDPAGE_BASENAME="`basename -- "$CHILDPAGE_FILE"`"
            CHILDPAGE_URL="`pageurl "$CHILDPAGE_FILE"`"
            CHILDPAGE_TITLE="`cat "$CHILDPAGE_FILE.title"`"
            BODY="$BODY<li><a href=\"$CHILDPAGE_URL\">$CHILDPAGE_TITLE</a>$NL"
        done
        BODY="$BODY</ul>"
    fi

    # Put blocks back in, possibly processing them first.
    for i in `seq "$BLOCKNUM"`
    do
        eval "TYPE=\$BLOCKTYPE$i"
        eval "BLOCK=\$BLOCK$i"
        case "$TYPE" in
            fus)
                BLOCK="<pre class=\"fus\">`echo "$BLOCK" | fus2html`</pre>"
            ;;
            fusfig*)
                BLOCK="`fusfig "$TYPE" $BLOCK`"
            ;;
            *)
                BLOCK="<pre class=\"block-$TYPE\">`echo "$BLOCK" | htmlescape`</pre>"
            ;;
        esac
        replace "{BLOCK$i}" "$BLOCK" "$BODY"
        BODY="$REPLACED"
    done

    # Copy the raw input file over, so OUTFILE can include a link to it
    # (But don't do it if INFILE is already .html, that is, if OUTFILE and
    # OUTFILE_RAW are the same.)
    if test "$OUTFILE_RAW" != "$OUTFILE"
    then
        do_with_log cp "$INFILE" "$OUTFILE_RAW"
    fi

    # Note the $NL (newlines), which we have to add manually, since
    # $HEADER/$FOOTER/$BODY all got their contents from commend expansion,
    # which removes trailing newlines (which is obnoxious).
    log "Writing to $OUTFILE..."
    echo -n "$PROCESSED_HEADER$NL$BODY$NL$FOOTER" >"$OUTFILE"
}


# "List" (touch) output files, so we can automatically generate lists
# of them in the HTML content of files which use CHILDPAGES_DIR
print_thickline
log "Listing files..."
for INDIR in "$SITE_INDIR"/*/
do
    : $(( log_depth++ ))
    bagcom_builddir list "${INDIR%/}"
    : $(( log_depth-- ))
done

# Actually build (generate the content of) the output files
print_thickline
log "Building files..."
for INDIR in "$SITE_INDIR"/*/
do
    : $(( log_depth++ ))
    bagcom_builddir build "${INDIR%/}"
    : $(( log_depth-- ))
done

print_thickline
log "Finishing up..."

# Clean up .title files
for INDIR in "$SITE_INDIR"/*/
do
    OUTDIR="$SITE_OUTDIR/${INDIR#$SITE_INDIR/}"
    do_with_log rm -f "$OUTDIR"/*.title
done

# Move files from "root" subdirectory to the actual build output root
do_with_log mv "$SITE_OUTDIR/root"/* "$SITE_OUTDIR/"
do_with_log rmdir "$SITE_OUTDIR/root"

# Copy static assets
do_with_log cp -r img/ "$SITE_OUTDIR/img/"
do_with_log cp -r "$FUSFIG_OUTDIR/" "$FUSFIG_STATICDIR/"
do_with_log cp -r style/ "$SITE_OUTDIR/style/"

# Doooone!
print_thickline
log "Build complete!"
log "Source directory: $SITE_INDIR"
log "Output directory: $SITE_OUTDIR"
