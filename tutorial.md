## Overview

> **Q**: Good to see you Mr Bond, things have been awfully dull around
> here...Now you're on this, I hope we're going to have some gratuitous sex and
> violence!<br>
> **James Bond**: I certainly hope so too.

007 is a small language. It has been designed with the purpose of exploring
ASTs, macros, the compiler-runtime barrier, and program structure
introspection.

In terms of language features, it's perhaps easiest to think of 007 as the
secret love child of Perl 6 and Python.

                           |  Perl 6          007             Python
    =======================|========================================
                           |                           :
                    braces |  yes             yes      :      no
                           |                           :
    user-defined operators |  yes             yes      :      no
                           |                           :
     variable declarations |  yes             yes      :      no
                           |                           :
                    macros |  yes             yes      :      no
                           |          .................:
        implicit typecasts |  yes     :       no              no
                           |          :
                    sigils |  yes     :       no              no
                           |          :
                    multis |  yes     :       no              no
                           |          :
          explicit returns |  yes     :       no              no
                           |

## Values

A small number of values in 007 can be expressed using literal syntax.

    123                 Q::Literal::Int
    "Bond."             Q::Literal::Str
    [0, 0, 7]           Q::Literal::Array

Only double quotes are allowed. Strings don't have any form of interpolation.

There's also a singleton type `None`. The value is generated for undeclared
variables calls without a `return`, but there is no literal form to produce it.

## Expressions

> **James Bond**: A gun and a radio. It's not exactly Christmas, is it?<br>
> **Q**: Were you expecting an exploding pen? We don't really go in for that anymore.

You can add integers together, and negate them.

    40 + 2              Q::Infix::Addition
    -42                 Q::Prefix::Minus

Strings can be concatenated.

    "Bo" ~ "nd."        Q::Infix::Concat

Arrays can be indexed. (Strings can't, but there's a builtin for that.)

    ar[3]               Q::Postfix::Index

There's an assignment operator, and a comparison operator. These work on all
types.

    name = "Bond"       Q::Infix::Assignment
    42 == 40 + 2        Q::Infix::Eq

There is no boolean type; comparison yields `1` and `0`. Comparison is strict,
in the sense that `7` and `"7"` are not considered equal under `==`, and an
array is never equal to an int, not even the length of the array.

The only thing that can be assigned to is variables. Arrays are immutable
values, and you can't assign to `ar[3]`, for example.

    ar[3] = "hammer";   # error; can't touch this

Operands don't need to be simple values. Arbitrarily large expressions can be
built. Parentheses can be used to explicitly show evaluation order.

    10 + -(2 + int("3" ~ "4"))

## Variables

In order to be able to read and write a variable, you must first declare it.

    my name;            Q::Statement::My

As part of the declaration, you can also do an assignment.

    my name = "Bond";

Variables are only visible for the rest of the scope they are declared in. All
scopes are delimited by braces, except for the scope delimiting the whole
program.

    {
        my drink = "Dry Martini";
        say(drink);     # works
    }
    say(drink);         # fails, no longer visible

It's fine for a variable in an inner scope to have the same name as one in an
outer scope. The inner variable will then "shadow" the outer until it's no
longer visible.

    var x = 1;
    {
        var x = 2;
        say(x);         # 2
    }
    say(x);             # 1

## Statements

> **Q**: It is to be handled with special care!<br>
> **Bond**: Everything you give me...<br>
> **Q**: ...is treated with equal contempt. Yes, I know.

We've seen two types of statement already: variable declarations, and
expression statements.

    my name = "Bond";   Q::Statement::My
    say(2 + 2);         Q::Statement::Expr

Expression statements are generally used for their side effects, so they tend
to either call some routine or assign to some variable. However, this is not a
requirement, and an expression statement can contain any valid expression.

Besides these simple statements, there are also a few compound statements for
conditionals and loops.

    if 2 + 2 == 4 {}    Q::Statement::If
    for xs -> x {}      Q::Statement::For
    while agent {}      Q::Statement::While

There is also an immediate block statement. Immediate blocks run
unconditionally, as if they were an `if 1 {}` statement.

    { say("hi") }       Q::Statement::Block

## Blocks and subroutines

There is a fourth type of literal: blocks are values, too.

    { say("hi") }       Q::Literal::Block
    -> x { say(x) }     same, but with a parameter

Note that in order not to be treated like an immediate block, a block literal
must not occur first in a statement.

If the optional arrow (`->`) is specified, the block can declare parameters.
These are bound to arguments passed in when a block is called.

    my g = -> name { say("Greetings, " ~ name) };
    g("Mr. Bond");

The parentheses in the call are mandatory. There is no `g "Mr. Bond";` listop
form.

Subroutines are similar to blocks, but they are declared with a name and a
(non-optional) parameter list.

    sub f(x) {}         Q::Statement::Sub

When calling a subroutine or a block, the number of arguments must equal the
number of parameters.

On the face of it, there isn't much difference between putting a block in a
variable, and declaring a sub:

    my f1 = -> name { say(name) };
    sub f2(name) {
        say(name);
    }

    f1("James Bond");
    f2("James Bond");

There is a difference, though: subroutines can return values, and blocks can't.

    return 42;          Q::Statement::Return

A return statement finds the lexically surrounding subroutine, and returns from
it. Blocks are transparent to this process; a `return` simply doesn't see
blocks.

    sub outer() {
        my inner = {
            return 42;
        }
        inner();
        say("not printed");
    }
    say(outer());

## `BEGIN` and constants

`BEGIN` blocks are blocks of code that run as soon as the parser has parsed the
ending brace (`}`) of the block.

    BEGIN {}            Q::Statement::BEGIN

There is no statement form of `BEGIN`: you must put in the braces.

There's also a `constant` declaration statement:

    constant pi = 3;    Q::Statement::Constant

The right-hand side of the `constant` declaration is evaluated at parse time,
making it functionally similar to using a BEGIN block to do the assignment:

    my pi;
    BEGIN {
        pi = 3;
    }

Constants cannot be assigned to after their declaration. Because of this, the
assignment in the `constant` declaration is mandatory.

## Setting

There's a scope outside the program scope, containing a utility subroutines.
These should be fairly self-explanatory.

    say(o)
    type(o)
    str(o)
    int(o)

    abs(n)
    min(n)
    max(n)
    chr(n)

    ord(c)
    chars(s)
    uc(s)
    lc(s)
    trim(s)
    split(s, sep)
    index(s, substr)
    charat(s, pos)
    substr(s, pos, chars?)

    elems(a)
    reversed(a)
    sorted(a)
    join(a, sep)
    grep(fn, a)
    map(fn, a)

There are also constructor methods for creating program elements.

    Q::Literal::Int(int)
    Q::Literal::Str(str)
    Q::Literal::Array(array)
    Q::Literal::Block(params, stmts)
    Q::Identifier(array)
    Q::Statements(array)
    Q::Parameters(array)
    Q::Arguments(array)
    Q::Prefix::Minus(expr)
    Q::Infix::Addition(lhs, expr)
    Q::Infix::Concat(lhs, expr)
    Q::Infix::Assignment(lhs, expr)
    Q::Infix::Eq(lhs, expr)
    Q::Postfix::Call(lhs, args)
    Q::Postfix::Index(lhs, rhs)
    Q::Statement::My(ident, assign?)
    Q::Statement::Constant(ident, assign)
    Q::Statement::Expr(expr)
    Q::Statement::If(expr, block)
    Q::Statement::Block(block)
    Q::Statement::Sub(ident, params, block)
    Q::Statement::Macro(ident, params, block)
    Q::Statement::Return(expr?)
    Q::Statement::For(expr, block)
    Q::Statement::While(expr, block)
    Q::Statement::BEGIN(block)

If you put an expression into a `Q::Statement::Expr` by passing it to its
constructor, you can get it out of the resulting Q object by calling the
destructor `expr(q)`. All the parameter names above are also represented
as destructors in the setting.

## Macros

> **Q**: Now, look...<br>
> **Bond**: So where is this cutting edge stuff?<br>
> **Q**: I'm trying to get to it!

Macros are a form of routine, just like subs.

    macro m(q) {}       Q::Statement::Macro

When a call to a macro is seen in the source code, the compiler will call the
macro, and then install whatever code the macro said to return.

    macro greet() {
        return Q::Expr::Call::Sub(
            Q::Identifier("say"),
            Q::Arguments([Q::Literal::Str("Mr Bond!")]));
    }

    greet();    # prints "Mr Bond!" when run

## Quasis

> **Q**: Right. Now pay attention, 007. I want you to take great care of this
> equipment. There are one or two rather special accessories...<br>
> **James Bond**: Q, have I ever let you down?
> **Q**: Frequently.

