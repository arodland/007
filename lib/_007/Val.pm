role Val {
    method truthy {
        True
    }
}

role Val::None does Val {
    method quoted-Str {
        self.Str
    }

    method Str {
        "None"
    }

    method truthy {
        False
    }
}

role Val::Int does Val {
    has Int $.value;

    method quoted-Str {
        self.Str
    }

    method Str {
        $.value.Str
    }

    method truthy {
        ?$.value;
    }
}

role Val::Str does Val {
    has Str $.value;

    method quoted-Str {
        q["] ~ $.value.subst("\\", "\\\\", :g).subst(q["], q[\\"], :g) ~ q["]
    }

    method Str {
        $.value
    }

    method truthy {
        ?$.value;
    }
}

role Val::Array does Val {
    has @.elements;

    method quoted-Str {
        "[" ~ @.elements>>.quoted-Str.join(', ') ~ "]"
    }

    method Str {
        self.quoted-Str
    }

    method truthy {
        ?$.elements
    }
}

role Q::ParameterList { ... }
role Q::StatementList { ... }

role Val::Block does Val {
    has $.parameterlist = Q::ParameterList.new;
    has $.statementlist = Q::StatementList.new;
    has %.static-lexpad;
    has $.outer-frame;

    method quoted-Str {
        self.Str
    }

    method pretty-params {
        sprintf "(%s)", $.parameterlist».name.join(", ");
    }
    method Str { "<block {$.pretty-params}>" }
}

role Val::Sub does Val::Block {
    has $.name;

    method quoted-Str {
        self.Str
    }

    method Str { "<sub {$.name}{$.pretty-params}>" }
}

role Val::Macro does Val::Sub {
    method quoted-Str {
        self.Str
    }

    method Str { "<macro {$.name}{$.pretty-params}>" }
}

role Val::Sub::Builtin does Val::Sub {
    has $.code;

    method new($name, $code) { self.bless(:$name, :$code) }
}
