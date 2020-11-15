
I was reading about minimalist C code producing 8-bit music:

* <http://viznut.fi/demos/unix/bytebeat_formulas.txt>
* <http://countercomplex.blogspot.com/2011/10/some-deep-analysis-of-one-line-music.html>
* <http://canonical.org/~kragen/bytebeat/>

I wrote a little bash function to make it easier to play with the example snippets on that page.

    compose() {
        echo "#include \"stdio.h\"" >music.c &&
        echo "int main(){for(int t=0;;t++)putchar($1);}" >>music.c &&
        gcc music.c -o music &&
        ./music | aplay
    }

Usage examples (based on examples from [viznut](http://viznut.fi/demos/unix/bytebeat_formulas.txt)):

    # sawtooth
    compose 't'

    # sierpinski harmony
    compose 't&t>>8'

    # "the 42 melody"
    compose 't*(42&t>>10)'

    # I think this one is my favourite...
    compose 't*(t>>9|t>>13)&16'
