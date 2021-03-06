%globals <%=js
    var level = 0;
%>

WS: [ \t\r\n]+ -> skip;

LINE_COMMENT: '//' [^\r\n]* '\r'? '\n' -> skip;
BLOCK_COMMENT: '/*' .*? '*/' -> skip;

ID: [$_A-Za-z][$_A-Za-z0-9]*;

'}';
'{';

%mode body {
    WS: [ \t\r\n]+ -> skip;
    LINE_COMMENT: '//' [^\r\n]* '\r'? '\n' -> skip;
    BLOCK_COMMENT: '/*' .*? '*/' -> skip;
    '{' -> <%
        level++;
    %>, skip;
    '}' -> <%
        if (!level) {
            this.pop_mode();
            this.enqueue_token($token);
        } else {
            level--;
        }
    %>, skip;
    . -> skip;
}

module
    : package_spec class_def <%
        $$ = {
            'package': $1,
            'class': $2
        };
        $2.package = $1.name;
        $2.canonical_name = $1.name + "." + $2.name;
    %>
    ;

package_spec
    : 'package' package_name ';' <%
        $$ = {
            name: $2.join('.')
        };
    %>
    ;

package_name
    : ID <%
        $$ = [$1.value];
    %>
    | package_name '.' ID <%
        $$ = $1;
        $$.push($3.value);
    %>
    ;

class_def
    : class_modifiers 'class' ID '{' class_body '}' <%
        $$ = $5;
        $$.name = $3.value;
        $$.access = $1;
    %>
    ;

class_modifiers
    :               <% $$ = 'package_private'; %>
    | 'public'      <% $$ = 'public'; %>
    | 'protected'   <% $$ = 'protected'; %>
    | 'private'     <% $$ = 'private'; %>
    ;

class_body
    : <%
        $$ = {
            name: null,
            package: null,
            canonical_name: null,
            access: null,
            members: [],
        };
    %>
    | class_body member_def <%
        $$ = $1;
        $$.members.push($2);
    %>
    ;

type_ref
    : 'double' <%
        $$ = 'double';
    %>
    | 'int' <%
        $$ = 'int';
    %>
    | 'String' <%
        $$ = 'String';
    %>
    | type_ref '[' ']' <%
        $$ = $1 + '[]';
    %>
    ;

member_modifiers
    : <%
        $$ = {
            access: 'package_private',
            static: false,
            final: false
        };
    %>
    | member_modifiers member_modifier <%
        $$ = $1;
        if ($2 === 'static') {
            $$.static = true;
        } else if ($2 === 'final') {
            $$.final = true;
        } else {
            $$.access = $2;
        }
    %>
    ;

member_modifier
    : 'public'      <% $$ = 'public'; %>
    | 'protected'   <% $$ = 'protected'; %>
    | 'private'     <% $$ = 'private'; %>
    | 'static'      <% $$ = 'static'; %>
    | 'final'       <% $$ = 'final'; %>
    ;

member_def
    : member_modifiers type_ref ID ';' <%
        $$ = {
            kind: 'field',
            name: $3.value,
            type: $2,
            modifiers: $1
        };
    %>
    | member_modifiers type_ref ID '(' method_args ')' method_body <%
        $$ = {
            kind: 'method',
            name: $3.value,
            return_type: $2,
            modifiers: $1,
            arguments: $5
        };
    %>
    | member_modifiers 'void' ID '(' method_args ')' method_body <%
        $$ = {
            kind: 'method',
            name: $3.value,
            return_type: 'void',
            modifiers: $1,
            arguments: $5
        };
    %>
    | member_modifiers ID '(' method_args ')' method_body <%
        $$ = {
            kind: 'constructor',
            name: $2.value,
            modifiers: $1,
            arguments: $4
        };
    %>
    ;

method_args
    : <%
        $$ = [];
    %>
    | method_arg_list <%
        $$ = $1;
    %>
    ;

method_arg_list
    : type_ref ID <%
        $$ = [{
            name: $2.value,
            type: $1
        }];
    %>
    | method_arg_list ',' type_ref ID <%
        $$ = $1;
        $$.push({
            name: $4.value,
            type: $3
        });
    %>
    ;

method_body
    : method_body_before '{' '}'
    ;

method_body_before
    : <%
        this.push_mode('body');
    %>
    ;

