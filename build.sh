#!/bin/sh
set -euo pipefail

# Input & output directories of this script
SITE_INDIR="src"
SITE_OUTDIR="dst"

# Keep a newline around in a variable
NL='
'

# Name of the website we're building
SITENAME="bayersglassey.com"

# Set up variables so we can easily print horizontal lines
LINEWIDTH=60
LINES="`printf %${LINEWIDTH}s | tr ' ' '-'`"
THICKLINES="`printf %${LINEWIDTH}s | tr ' ' '='`"

# And so it begins.
echo "$THICKLINES" >&2
echo "Building site!" >&2
echo "Source directory: $SITE_INDIR" >&2
echo "Output directory: $SITE_OUTDIR" >&2

# Create output directory
rm -rf "$SITE_OUTDIR"
mkdir -p "$SITE_OUTDIR"

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

    for INFILE in "$INDIR"/*
    do
        BASENAME="`basename -- "$INFILE"`"
        EXT="${BASENAME##*.}"

        # Only process .txt or .html files
        test "$EXT" = "txt" -o "$EXT" = "html" || continue

        OUTFILE="$SITE_OUTDIR/${INFILE#$SITE_INDIR/}"
        OUTFILE="${OUTFILE%.*}.html"
        OUTDIR="`dirname -- "$OUTFILE"`"

        CONFIGFILE="$INFILE.config"

        # Variables which can be set by $CONFIGFILE
        TITLE=""
        CHILDPAGES_DIR=""

        # ...ok, set the variables please
        . "$CONFIGFILE"

        case "$ACTION" in
            list)
                echo "$LINES" >&2
                echo "Listing: $INFILE" >&2
                echo "Output: $OUTFILE" >&2

                # Touch the file so it can be found when generating
                # CHILDPAGES
                mkdir -p "$OUTDIR"
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

    # We use backtick "`" as the separator in sed's "s" operator, which means
    # cannot use it in a page's title!
    PROCESSED_HEADER="` \
        echo "$HEADER" \
        | sed "s@{TITLE}@$TITLE@" \
        | sed "s@{SITENAME}@$SITENAME@" \
    `"

    BODY="`cat "$INFILE"`"

    # Wrap the contents of .txt files in <pre>
    if test "$EXT" = "txt"
    then
        BODY="<pre>$BODY</pre>"
    fi

    # Automatically generate lists of child pages (as directed by the
    # config file)
    if test -n "$CHILDPAGES_DIR"
    then
        BODY="$BODY$NL<ul>$NL"
        for CHILDPAGE_FILE in "$SITE_OUTDIR/$CHILDPAGES_DIR"/*.html
        do
            CHILDPAGE_BASENAME="`basename -- "$CHILDPAGE_FILE"`"
            CHILDPAGE_URL="/${CHILDPAGE_FILE#$SITE_OUTDIR/}"
            CHILDPAGE_TITLE="`cat "$CHILDPAGE_FILE.title"`"
            BODY="$BODY<li><a href=\"$CHILDPAGE_URL\">$CHILDPAGE_TITLE</a>$NL"
        done
        BODY="$BODY</ul>"
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
cp -r style/ "$SITE_OUTDIR/style/"

# Doooone!
echo "$THICKLINES" >&2
echo "Build complete!" >&2
echo "Source directory: $SITE_INDIR" >&2
echo "Output directory: $SITE_OUTDIR" >&2
