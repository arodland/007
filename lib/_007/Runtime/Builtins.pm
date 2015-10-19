use _007::Val;
use _007::Q;

class _007::Runtime::Builtins {
    method get-builtins($runtime) {
        sub escape($_) {
            return (~$_).subst("\\", "\\\\", :g).subst(q["], q[\\"], :g);
        }

        sub stringify-inside-array($_) {
            when Val::Str {
                return q["] ~ escape(.value) ~ q["]
            }
            when Val::Array {
                return '[%s]'.&sprintf(.elements>>.&stringify-inside-array.join(', '));
            }
            when Q {
                return .Str;
            }
            return .value.Str;
        }

        sub _007ize(&fn) {
            sub wrap($_) {
                when Val | Q { $_ }
                when Nil { Val::None.new }
                when Str { Val::Str.new(:value($_)) }
                when Int { Val::Int.new(:value($_)) }
                when Array | Seq { Val::Array.new(:elements(.map(&wrap))) }
                default { die "Got some unknown value of type ", .^name }
            }

            return sub (|c) { wrap &fn(|c) };
        }

        return my % = map { .key => _007ize(.value) }, my %builtins =
            say      => -> $arg {
                $runtime.output.say($arg ~~ Val::Array ?? %builtins<str>($arg).Str !! ~$arg);
                Nil;
            },
            type     => -> $arg {
                $arg ~~ Val::Sub
                    ?? "Sub"
                    !! $arg.^name.substr('Val::'.chars);
            },
            str => sub ($_) {
                when Val::Array {
                    return stringify-inside-array($_);
                }
                when Val::None { return .Str }
                when Val { return .value.Str }
                die X::TypeCheck.new(
                    :operation<str()>,
                    :got($_),
                    :expected("something that can be converted to a string"));
            },
            int => sub ($_) {
                when Val::Str {
                    return .value.Int
                        if .value ~~ /^ '-'? \d+ $/;
                    proceed;
                }
                when Val::Int {
                    return .value;
                }
                die X::TypeCheck.new(
                    :operation<int()>,
                    :got($_),
                    :expected("something that can be converted to an int"));
            },
            abs      => -> $arg { $arg.value.abs },
            min      => -> $a, $b { min($a.value, $b.value) },
            max      => -> $a, $b { max($a.value, $b.value) },
            chr      => -> $arg { $arg.value.chr },
            ord      => -> $arg { $arg.value.ord },
            chars    => -> $arg { $arg.value.Str.chars },
            uc       => -> $arg { $arg.value.uc },
            lc       => -> $arg { $arg.value.lc },
            trim     => -> $arg { $arg.value.trim },
            elems    => -> $arg { $arg.elements.elems },
            reversed => -> $arg { $arg.elements.reverse },
            sorted   => -> $arg { $arg.elements>>.value.sort },
            join     => -> $a, $sep { $a.elements.join($sep.value.Str) },
            split    => -> $s, $sep { $s.value.split($sep.value) },
            index    => -> $s, $substr { $s.value.index($substr.value) // -1 },
            substr   => sub ($s, $pos, $chars?) { $s.value.substr($pos.value, $chars.defined ?? $chars.value !! $s.value.chars) },
            charat   => -> $s, $pos { $s.value.comb[$pos.value] // die X::Subscript::TooLarge.new },
            filter   => -> $fn, $a { $a.elements.grep({ $runtime.call($fn, [$_]).truthy }) },
            map      => -> $fn, $a { $a.elements.map({ $runtime.call($fn, [$_]) }) },
            'infix:<+>' => -> $lhs, $rhs { #`[not implemented here] },
            'prefix:<->' => -> $lhs, $rhs { #`[not implemented here] },

            'Q::Literal::Int' => -> $int { Q::Literal::Int.new($int.value) },
            'Q::Literal::Str' => -> $str { Q::Literal::Str.new($str.value) },
            'Q::Literal::Array' => -> $array { Q::Literal::Array.new($array.value) },
            'Q::Literal::None' => -> { Q::Literal::None.new },
            'Q::Block' => -> $params, $stmts { Q::Block.new($params, $stmts) },
            'Q::Identifier' => -> $name { Q::Identifier.new($name.value) },
            'Q::Statements' => -> $array { Q::Statements.new($array.value) },
            'Q::Parameters' => -> $array { Q::Parameters.new($array.value) },
            'Q::Arguments' => -> $array { Q::Arguments.new($array.elements) },
            'Q::Prefix::Minus' => -> $expr { Q::Prefix::Minus.new($expr) },
            'Q::Infix::Addition' => -> $lhs, $rhs { Q::Infix::Addition.new($lhs, $rhs) },
            'Q::Infix::Concat' => -> $lhs, $rhs { Q::Infix::Concat.new($lhs, $rhs) },
            'Q::Infix::Assignment' => -> $lhs, $rhs { Q::Infix::Assignment.new($lhs, $rhs) },
            'Q::Infix::Eq' => -> $lhs, $rhs { Q::Infix::Eq.new($lhs, $rhs) },
            'Q::Postfix::Call' => -> $expr, $args { Q::Postfix::Call.new($expr, $args) },
            'Q::Postfix::Index' => -> $expr, $pos { Q::Postfix::Index.new($expr, $pos) },
            'Q::Statement::My' => -> $ident, $assign = Empty { Q::Statement::My.new($ident, |$assign) },
            'Q::Statement::Constant' => -> $ident, $assign { Q::Statement::Constant.new($ident, $assign) },
            'Q::Statement::Expr' => -> $expr { Q::Statement::Expr.new($expr) },
            'Q::Statement::If' => -> $expr, $block { Q::Statement::If.new($expr, $block) },
            'Q::Statement::Block' => -> $block { Q::Statement::Block.new($block) },
            'Q::Statement::Sub' => -> $ident, $params, $block { Q::Statement::Sub.new($ident, $params, $block) },
            'Q::Statement::Macro' => -> $ident, $params, $block { Q::Statement::Macro.new($ident, $params, $block) },
            'Q::Statement::Return' => -> $expr = Empty { Q::Statement::Return.new(|$expr) },
            'Q::Statement::For' => -> $expr, $block { Q::Statement::For.new($expr, $block) },
            'Q::Statement::While' => -> $expr, $block { Q::Statement::While.new($expr, $block) },
            'Q::Statement::BEGIN' => -> $block { Q::Statement::BEGIN.new($block) },

            value => sub ($_) {
                when Q::Literal::None {
                    return Val::None.new;
                }
                when Q::Literal::Array {
                    return Val::Array.new(:elements(.elements.map(%builtins<value>)));
                }
                when Q::Literal {
                    return .value;
                }
                die X::TypeCheck.new(
                    :operation<value()>,
                    :got($_),
                    :expected("a Q::Literal type that has a value()"));
            },
            params => sub ($_) {
                # XXX: typecheck
                return .parameters;
            },
            stmts => sub ($_) {
                # XXX: typecheck
                return .statements;
            },
            expr => sub ($_) {
                # XXX: typecheck
                return .expr;
            },
            lhs => sub ($_) {
                # XXX: typecheck
                return .lhs;
            },
            rhs => sub ($_) {
                # XXX: typecheck
                return .rhs;
            },
            pos => sub ($_) {
                # XXX: typecheck
                return .index;
            },
            args => sub ($_) {
                # XXX: typecheck
                return .arguments;
            },
            ident => sub ($_) {
                # XXX: typecheck
                return .ident;
            },
            assign => sub ($_) {
                # XXX: typecheck
                return .assignment;
            },
            block => sub ($_) {
                # XXX: typecheck
                return .block;
            },
        ;
    }
}
