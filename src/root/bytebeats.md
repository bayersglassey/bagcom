
I was reading about minimalist C code producing 8-bit music:

* <http://viznut.fi/demos/unix/bytebeat_formulas.txt>
* <http://countercomplex.blogspot.com/2011/10/some-deep-analysis-of-one-line-music.html>
* <http://canonical.org/~kragen/bytebeat/>

So for instance, silence is represented by the C expression `0`, and a simple sawtooth wave
of constant tone can be achieved with the C expression `t`.
More complicated C expressions lead to surprisingly complex, and occasionally musical,
series of sounds, e.g. `t&t>>8`.

I wrote a little bash function to make it easier to play with the example snippets on that page.

```shell
compose() {
    echo "#include \"stdio.h\"" >music.c &&
    echo "int main(){for(int t=0;;t++)putchar($1);}" >>music.c &&
    gcc music.c -o music &&
    ./music | aplay
}

# Example usage (compiles a C program, and runs it, piping its output "into
# your speakers" as it were):
compose 't&t>>8'
```

Some examples from [viznut](http://viznut.fi/demos/unix/bytebeat_formulas.txt):

### sawtooth
```bb sawtooth
t
```

### sierpinski harmony
```bb sierpinski
t&t>>8
```

### "the 42 melody"
```bb 42-melody
t*(42&t>>10)
```

### I think this one is my favourite...
```bb favourite
t*(t>>9|t>>13)&16
```
