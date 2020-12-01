#!/bin/sh
set -euo pipefail

# Input & output directories of this script
SITE_INDIR="src"
SITE_OUTDIR="dst"

# Keep a newline around in a variable
NL='
'

# Separator token for "code blocks"
BLOCKSEP='```'

# Markdown parser command, we feed it Markdown and expect HTML back
MARKDOWN="markdown"

# Command which converts .fus to .html (from geom2018 repo)
LEXERTOOL="lexertool"
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
MINIEDITOR="minieditor --pal fusfig/pal.fus --font fusfig/font.fus --fonts fusfig/fonts.fus"
MINIEDITOR_SCREENSHOT="screen.bmp"

# Name of the website we're building
SITENAME="bayersglassey.com"

# Set up variables so we can easily print horizontal lines
LINEWIDTH=60
LINES="`printf %${LINEWIDTH}s | tr ' ' '-'`"
THICKLINES="`printf %${LINEWIDTH}s | tr ' ' '='`"

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
    mkdir -p "$FUSFIG_OUTSUBDIR"
    FUSFIG_OUTFILE="$FUSFIG_OUTSUBDIR/$FUSFIG_RGRAPH.$FUSFIG_EXT"
    FUSFIG_STATICFILE="/$FUSFIG_STATIC/${FUSFIG_FILENAME%.fus}/$FUSFIG_RGRAPH.$FUSFIG_EXT"

    echo "Building fus figure: $FUSFIG_OUTFILE" 1>&2
    echo "  $MINIEDITOR -f \"$FUSFIG_INFILE\" -n \"$FUSFIG_RGRAPH\" $@ --nocontrols" 1>&2

    $MINIEDITOR -f "$FUSFIG_INFILE" -n "$FUSFIG_RGRAPH" "$@" -q --nocontrols --nogui
    convert "$MINIEDITOR_SCREENSHOT" "$FUSFIG_OUTFILE"

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
echo "$THICKLINES" >&2
echo "Building site!" >&2
echo "Source directory: $SITE_INDIR" >&2
echo "Output directory: $SITE_OUTDIR" >&2

# Create output directories
rm -rf "$SITE_OUTDIR"
mkdir -p "$SITE_OUTDIR"
rm -rf "$FUSFIG_OUTDIR"
mkdir -p "$FUSFIG_OUTDIR"

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

    # Variables which can be set by $DIRCONFIGFILE
    PARENTNAME=""
    PARENTURL=""
    CRUMBS=0

    # ...ok, set the variables please
    if test -f "$DIRCONFIGFILE"
    then
        . "$DIRCONFIGFILE"
    else
        echo "...skipping missing dirconfig file: $CONFIGFILE" >&2
    fi

    # Save $CRUMBS for this directory, it will be "inherited" by
    # child pages (though they can override it)
    DIRCRUMBS="$CRUMBS"

    if test "$ACTION" = "list"
    then
        # Create output directory
        mkdir -p "$OUTDIR"

        # Copy static assets (if present)
        test ! -d "$INDIR/img" || cp -r "$INDIR/img" "$OUTDIR/img"
    fi

    for INFILE in "$INDIR"/*
    do
        BASENAME="`basename -- "$INFILE"`"
        EXT="${BASENAME##*.}"

        # Only process files with these extensions
        test "$EXT" = "txt" -o "$EXT" = "html" -o "$EXT" = "md" -o "$EXT" = "fus" || continue

        OUTFILE_RAW="$SITE_OUTDIR/${INFILE#$SITE_INDIR/}"
        OUTFILE="${OUTFILE_RAW%.*}.html"
        OUTFILE_RAW_URL="`pageurl "$OUTFILE_RAW"`"

        # $CONFIGFILE: a file containing metadata about the page whose
        # contents are in $INFILE
        CONFIGFILE="$INFILE.config"

        # Variables which can be set by $CONFIGFILE
        TITLE="${BASENAME/.*}"
        CRUMBS="$DIRCRUMBS"
        CHILDPAGES_DIR=""

        # ...ok, set the variables please
        if test -f "$CONFIGFILE"
        then
            . "$CONFIGFILE"
        else
            echo "...skipping missing config file: $CONFIGFILE" >&2
        fi

        case "$ACTION" in
            list)
                echo "$LINES" >&2
                echo "Listing: $INFILE" >&2
                echo "Output: $OUTFILE" >&2

                # Touch the file so it can be found when generating
                # CHILDPAGES
                touch "$OUTFILE"

                # Store the title somewhere we can find it when
                # generating CHILDPAGES
                echo "$TITLE" >"$OUTFILE.title"
            ;;
            build)
                echo "$LINES" >&2
                echo "Building: $INFILE" >&2
                echo "Output: $OUTFILE" >&2
                bagcom_buildfile
                echo "Done!" >&2
            ;;
            *)
                echo "Unrecognized action: $ACTION" >&2
                exit 1
            ;;
        esac
    done
}

bagcom_buildfile() {

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
    if test "$CRUMBS" -lt 2
    then
        # Remove (with sed's "d" command) lines which start with "{CRUMB2}"
        PROCESSED_HEADER="`echo "$PROCESSED_HEADER" | sed '/^{CRUMB2}/d'`"
    fi
    if test "$CRUMBS" -lt 1
    then
        # Remove (with sed's "d" command) lines which start with "{CRUMB1}"
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
        BODY="`echo "$BODY" | "$MARKDOWN"`"
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
        cp "$INFILE" "$OUTFILE_RAW"
    fi

    # Note the $NL (newlines), which we have to add manually, since
    # $HEADER/$FOOTER/$BODY all got their contents from commend expansion,
    # which removes trailing newlines (which is obnoxious).
    echo -n "$PROCESSED_HEADER$NL$BODY$NL$FOOTER" >"$OUTFILE"
}


# "List" (touch) output files, so we can automatically generate lists
# of them in the HTML content of files which use CHILDPAGES_DIR
echo "$THICKLINES" >&2
echo "Listing files..." >&2
for INDIR in "$SITE_INDIR"/*/
do
    bagcom_builddir list "${INDIR%/}"
done

# Actually build (generate the content of) the output files
echo "$THICKLINES" >&2
echo "Building files..." >&2
for INDIR in "$SITE_INDIR"/*/
do
    bagcom_builddir build "${INDIR%/}"
done

echo "$THICKLINES" >&2
echo "Finishing up..." >&2

# Clean up .title files
for INDIR in "$SITE_INDIR"/*/
do
    OUTDIR="$SITE_OUTDIR/${INDIR#$SITE_INDIR/}"
    rm -f "$OUTDIR"/*.title
done

# Move files from "root" subdirectory to the actual build output root
mv "$SITE_OUTDIR/root"/* "$SITE_OUTDIR/"
rmdir "$SITE_OUTDIR/root"

# Copy static assets
cp -r img/ "$SITE_OUTDIR/img/"
cp -r "$FUSFIG_OUTDIR/" "$FUSFIG_STATICDIR/"
cp -r style/ "$SITE_OUTDIR/style/"

# Doooone!
echo "$THICKLINES" >&2
echo "Build complete!" >&2
echo "Source directory: $SITE_INDIR" >&2
echo "Output directory: $SITE_OUTDIR" >&2
