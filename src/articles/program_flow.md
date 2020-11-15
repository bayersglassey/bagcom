
Consider the programming language Brain****, here referred to as BF
for propriety.

The classic "Hello World" program (which outputs "Hello World" and exits)
may be implemented in BF like this:

    +[-[<<[+[--->]-[<<<]]]>>>-]>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.

For clarity, we might re-indent it like this:

    +
    [
        -
        [
            <<
            [
                +
                [
                    --->
                ]
                -
                [
                    <<<
                ]
            ]
        ]
        >>>-
    ]
    >-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.

This suggests an encoding for BF programs using "significant whitespace".
In this encoding, the "[]" operators are inferred from the relative
indentation of consecutive lines:

    +
        -
            <<
                +
                    --->
                -
                    <<<
        >>>-
    >-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.

With the "[" and "]" characters removed, the program appears to consist
of isolated snippets of code, suggesting an encoding as a graph:

    (+)===(-)===(<<)===(+)===(--->)
    |     |     |      |    /
    |     |     |      |   /
    |     |    /       |  /
    |     |   /  ======(-)===(<<<)
    |     |  /  /            /
    |     | |  / ============
    |     | | | /
    |   ==(>>>-)
    |  /
    (>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.)

Here nodes are indicated by (...), edges by "=", "|", and "/".

Each node represents some loop-free BF code.

Each edge represents a conditional jump instruction: either "jump if true"
or "jump if false".

The edges are directed, though neither direction nor type of conditional
(jump if true/false) are shown, due to the limitations of ASCII representation.

For each "[" in the text encoding, there are 2 edges: a "jump if true" to the
right, and a "jump if false" downwards.

Also, for each "]" in the text encoding, there are 2 edges: a "jump if true"
upwards, and a "jump if false" downwards to the left.

We chose not to include 2 empty nodes above (>>>-): those nodes would have
corresponded to the latter two "]" in "]]]".
Without them, (>>>-) has 4 incoming edges instead of the usual 2.

We could split each node into separate nodes for each of its instructions:

    (>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.)

    ...becomes:

    (>)===(-)===(.)===(-)===(-)===(-)===(    ...etc

Where the edges represent unconditional jumps.

The graph encoding suggests a text encoding using named labels and explicit
conditional jump instructions.
First, let's label the nodes with single characters (a, b, c, etc):

    a: +[
        b: -[
            c: <<[
                d: +[
                e: --->]
                f: -[
                g: <<<]]]
    j: >>>-]
    k: >-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.

Now let's replace "[" and "]" with conditional jumps.

"?x" means: "if true, jump to label x"

"!x" means: "if false, jump to label x"

    a: + !k
    b: - !j
    c: << !j
    d: + !f
    e: ---> ?d
    f: - !j
    g: <<< ?f
    j: >>>- ?a
    k: >-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.

Every "[" becomes a "!", and every "]" becomes a "?".

Now we can write BF programs using "?" and "!", and in fact we can write
programs which could not be written using "[" and "]".

For instance, in BF an infinite loop can be written using a cell with a
"true" value (for instance,1):

    +[]

However, with "!" and "?" we can also write an infinite loop which works
on a cell with a "false" value (that is, 0):

    a: !a

The syntax with named labels is somehow less satisfying than the austerity
of BF's "[" and "]".

We could add support for if/else, for instance using "(", "|", and ")" to
mean "if", "else", and "endif":

    ,(..|++++++++++.)

This program gets one character from the input stream.

If the character was not NUL, the program outputs it back twice.

If the character was NUL, the program outputs a newline (ASCII value 10).

We can actually represent "[" and "]" using this if/else/endif syntax --
if we are allowed to write an infinitely long program:

    [X]Y

    Becomes:

    (X(X(X(X(X(...)|Y)|Y)|Y)|Y)|Y)

We can rewrite this as a recursive definition:

    A
    Where A = (XA|Y)

We can encode our "Hello World" program using the following procedure:

1. Write out the program.

        +[-[<<[+[--->]-[<<<]]]>>>-]>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.

2. Figure out which parts of the program (of the form "[X]Y") will
need recursive definitions:

        +
        A: [-
            B: [<<
                C: [+
                    D: [--->
                    ]-
                    E: [<<<
                    ]
                ]
            ]>>>-
        ]>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.

3. Now write out the definitions:

        +A
        Where:
        A = (-BA|>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.)
        B = (<<CB|>>>-)
        C = (+DC|)
        D = (--->D|-E)
        E = (<<<E|)

This suggests a text encoding of BF consisting of the operators "+-<>,.(|)",
the variables A-Z, and variable definitions.

The first line is the main program; subsequent lines are variable
definitions, starting with A:

    +A                                             # Main program
    (-BA|>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.)      # Definition of A
    (<<CB|>>>-)                                    # Definition of B
    (+DC|)                                         # ...etc
    (--->D|-E)
    (<<<E|)

In this example, all variable values were (...), but that need not be
the case.

For example, here is one way to write a "Hello World" program which uses
no (...) at all:

    ABCCDEFDGCH
    >++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >++++++++++++++++++++++++++++++++.
    >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.
    >++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++.

The idea being that the variables A - H contain programs which move to an
empty cell, then output the following characters:

    A: "H"
    B: "e"
    C: "l"
    D: "o"
    E: " "
    F: "W"
    G: "r"
    H: "d"

The main program then consists of these variables in the order needed to
output "Hello World":

    Hello World
    ABCCDEFDGCH

Now, this idea of a group of programs referring to each other sounds a lot
like a graph.

Taking again this example:

    +A
    Where:
    A = (-BA|>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.)
    B = (<<CB|>>>-)
    C = (+DC|)
    D = (--->D|-E)
    E = (<<<E|)

We might represent it as the following graph:

    NOTE:
    There are multiple kinds of edge, and they are directed.
    Unfortunately none of that is encoded in this ASCII representation.
    The if/else/endif operator is represented by a pair of outgoing edges.
    The other edges represent variable references - these could also be
    thought of as "subroutine calls".
    If we wanted to represent jumps instead of calls, we could do so for
    this example,
    but we would need to add more edges...

       (+)
        |
        |        ====
        |       /    |
    A: (if/else)===(-)===================================
                \                                        \
                 ==(>-.---.>..>.<<<<-.<+.>>>>>.>.<<.<-.)  |
                                                         /
          ===============================================
         /
        /        ============
       |        /            |
    B: (if/else)======(<<<)==
                \          \
                 ==(>>>-)   |
                           /
          =================
         /
        /        =======
       |        /       |
    C: (if/else)===(+)==
                \     \
                 ==()  |
                      /
          ============
         /
        /        ==========
       |        /          |
    D: (if/else)===(--->)==
                \
                 ==(-)==
                        |
          ==============
         /
        /        =========
       |        /         |
    E: (if/else)===(<<<)==
                \
                 ==()

This representation suggests an encoding of a BF program as a set of
connected data structures.

For instance, in C:

    struct bf_node {

        /* code: string of non-looping characters, e.g. "<>-+,." */
        const char *code;
        int code_len;

        /* if_branch: taken if current cell's value is true (nonzero) */
        /* else_branch: taken if if_branch is not taken */
        /* NOTE: if if_branch is NULL, else_branch is always taken (it
        becomes an unconditional branch) */
        struct bf_node *if_branch;
        struct bf_node *else_branch;

    };

