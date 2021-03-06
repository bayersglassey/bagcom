
A common problem when designing a programming language or other text format
is references.

For instance, here is some pseudocode with line numbers:

    00: var x = 3
    01:
    02: fun f(x){
    03:     print x + 1
    04: }
    05:
    06: fun g(){
    07:     print f(x * 2)
    08: }

Let's say the intended references are:

    "x" on line 03 refers to "x" on line 02
    "x" on line 07 refers to "x" on line 00
    "f" on line 07 refers to "f" on line 02

Now let's go further and posit inter-file references:

    "print" on lines 03, 07 refer to "print" on line 231 in file "io.src"

A "file" need not be an actual file living in a filesystem on an operating
system.

It could be something more abstract; let's call it a "module".

For instance, in many languages a module is specified by a dotted path A.B.C.
That might represent an actual file A/B/C.src, or it might represent a
dynamically loaded module, etc.

In any case, let's say we can uniquely specify any token by (file, line,
offset, length).

That is, a filename, a line number (starting at 0), an offset within that line,
and a token length.

We could just use (file, offset, length) using an offset within the file, but
it's nicer to see line numbers.

Now a useful system would be one which allows all references within it to be
resolved, with a minimum of parsing.

So, we might define a language (not a programming language) which allows
definition of and references to names, including within files.

    00: from "file1.src" import a, b, c
    01:
    02: var x, y
    03:
    04: private var z = bla bla a etc
    05:
    06: fun f(x, y){
    07:     bla bla x c bla
    08:     lambda(x, y){ bla bla z }
    09: }
    10:
    11: private fun g(x){
    12:     etc etc etc x y
    13: }

Now, the tokens "bla", "etc", etc need not be given any meaning, but the
structure of definitions and references is hopefully clear.

The "private" vars and funs are invisible to other files (can't be imported).

There are some scoping rules in effect, so that the "x" on line 07 refers to
the "x" on line 06, not that on line 02.

However, much of the text can be ignored (such as "bla", "etc").

A parser for this language would build the following data structures:

* A set of definitions (file, line, offset, length)
* A set of references (file, line, offset, length, definition)

This parser could be used as part of an implementation of more complicated
languages designed on top of the simple definition/reference language.

Can we implement a parser like this, and reuse it in multiple projects?

In order to implement scoping rules, the parser will need to be able to
recognize scopes.

So the parser would need to be modified (or given a syntax specification)
for each language we wanted to parse.

The question is just how much can be implemented in a generic way.

Let's start with data structures.
(If we were really serious, we would start with how text is being encoded.
But for simplicity's sake let's assume ASCII for now.)

    file

        filename

    definition

        canonical name (e.g. "fully-qualified name", "dotted path",
            depending on the language - for simple languages, can be
            e.g. "filename:token")

        token (file, line, offset, length)

    reference

        token (file, line, offset, length)

        definition

    set (methods: add, lookup, iterate)

Let's say that files will be looked up by filename, definitions by canonical
name.

(unfinished)
