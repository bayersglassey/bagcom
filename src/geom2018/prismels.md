
## Pixels vs "prismels"

Pixels are tiny squares, each a different colour, arranged in a grid.

The idea behind geom 2018 is to simulate a screen whose "pixels" can be shapes other than squares,
and can be arranged in patterns other than a grid.

In order to differentiate between this freer "pixels" versus the traditional kind, I used the
name "prismels" in my notes, and eventually the name made its way into the code and became official.
Although it doesn't really make sense because it looks like it should mean "prism pixels",
but a prism is a 3d object, while geom 2018's prismels are 2d.
Maybe a better term would have been "polygismels", that is, "polygonal pixels".
But that name sucks, so here we are.

## The basic set

In my notes, I sketch various sets of prismels, but there is a particular set which I love the most:

```fusfig header
prismels.fus fig0 -p -10 10 -s 120 40
```

You can build really nice patterns out of these shapes, of which my favourite is probably the dodecahedron:

```fusfig header
prismels.fus fig1 -s 100 100
```

What I like about them is that you can glue a bunch of them together into a repeating pattern:

```fusfig header
prismels.fus fig2 -s 400 270
```

These basic 3 prismels are called "sq", "tri", and "dia". Here are their definitions:

```fus
    "sq":

        # +---+
        # |   |
        # |   |
        # 0---+

        #     +   +
        # ++ +++ +++ ++   +                             +
        # ++  +   +  ++  +++   +                    +  +++
        # .   .    .   .  + . +++. ++.  +.  X  X+  X++ .+
        #                      +   ++  +++ +++ ++   +
        #                               +   +

        images:
            : ( 0 -2  2) ( 0 -1  2)
            : ( 0 -3  1) (-1 -2  3) ( 0 -1  1)
            : (-1 -3  1) (-2 -2  3) (-1 -1  1)
            : (-2 -2  2) (-2 -1  2)
            : (-2 -2  1) (-3 -1  3) (-2  0  1)
            : (-2 -1  1) (-3  0  3) (-2  1  1)
            : (-2  0  2) (-2  1  2)
            : (-1  0  1) (-2  1  3) (-1  2  1)
            : ( 0  0  1) (-1  1  3) ( 0  2  1)
            : ( 0  0  2) ( 0  1  2)
            : ( 1 -1  1) ( 0  0  3) ( 1  1  1)
            : ( 1 -2  1) ( 0 -1  3) ( 1  0  1)
            :  9
            :  8
            :  7
            :  6
            :  5
            :  4
            :  3
            :  2
            :  1
            :  0
            : 11
            : 10

    "tri":

        #   +
        #   |
        #  / \
        # |   |
        # 0---+

        #
        #    + ++ +
        # ++ +    +  ++  +                   +
        # .  .  .  .   . + . ++. +.  . X X+ .+
            : ( 0 -1  2)
            : ( 0 -2  1) ( 0 -1  1)
            : (-1 -2  2)
            : (-1 -2  1) (-1 -1  1)
            : (-2 -1  2)
            : (-2 -1  1) (-2  0  1)
            : (-2  0  2)
            : (-1  0  1) (-1  1  1)
            : (-1  1  2)
            : ( 0  0  1) ( 0  1  1)
            : ( 0  0  2)
            : ( 1 -1  1) ( 1  0  1)
            : 10
            :  9
            :  8
            :  7
            :  6
            :  5
            :  4
            :  3
            :  2
            :  1
            :  0
            : 11

    "dia":

        #    -+---+
        #   /   /
        # 0---+-

        #       + + +  +
        #      +  + +   +
        #  ++ +          +  ++
        # .   .   .  .    .    . ++ .   +.  . . X   .++
        #                              +   +  +  +
        #                             +    +  +   +

        images:
            : ( 1 -1  2)
            : ( 0 -1  1) ( 1 -2  1) ( 2 -3  1)
            : ( 0 -2  1) ( 0 -3  1)
            : (-1 -2  1) (-1 -3  1)
            : (-1 -1  1) (-2 -2  1) (-3 -3  1)
            : (-3 -1  2)
            : (-3  0  2)
            : (-1  0  1) (-2  1  1) (-3  2  1)
            : (-1  1  1) (-1  2  1)
            : ( 0  1  1) ( 0  2  1)
            : ( 0  0  1) ( 1  1  1) ( 2  2  1)
            : ( 1  0  2)
            : 11
            : 10
            :  9
            :  8
            :  7
            :  6
            :  5
            :  4
            :  3
            :  2
            :  1
            :  0
```

