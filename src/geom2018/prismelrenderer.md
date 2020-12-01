...it's the thing which renders your [prismels](prismels.html).

As of this writing, its definition is:
```c
typedef struct prismelrenderer {
    bool cache_bitmaps;
    vecspace_t *space;
    stringstore_t stringstore;
    ARRAY_DECL(struct font*, fonts)
    ARRAY_DECL(struct geomfont*, geomfonts)
    ARRAY_DECL(struct prismel*, prismels)
    ARRAY_DECL(struct rendergraph*, rendergraphs)
    ARRAY_DECL(struct prismelmapper*, mappers)
    ARRAY_DECL(struct palettemapper*, palmappers)
} prismelrenderer_t;
```

From C, one generally uses it by loading a .fus file with `prismelrenderer_load`.

The syntax is:

```fus
import FILENAME

prismels:
    ...

shapes:
    ...

mappers:
    ...

palmappers:
    ...

geomfonts:
    ...
```

You can think of it as defining several different "namespaces", one for each type of object.

* My standard set of [prismels](prismels.html) includes "sq", "tri", and "dia".

* The "shapes" namespace is actually for [rendergraphs](rendergraphs.html)
