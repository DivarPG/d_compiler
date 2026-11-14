%token BOOL INT VOID
%token CHAR STRING
%token CLASS ENUM OVERRIDE PRIVATE PROTECTED PUBLIC
%token STATIC CONST IMPORT
%token IF ELSE
%token WHILE DO FOR
%token CONTINUE BREAK RETURN
%token TRUE FALSE NULL
%token NEW THIS SUPER

%token INT_LITERAL
%token STRING_LITERAL CHAR_LITERAL
%token TRUE_LITERAL FALSE_LITERAL
%token NULL_LITERAL
%token ID

%token ISTRING_BEGIN ISTRING_TEXT ISTRING_END
%token INTERP_BEGIN INTERP_END

%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN
%left '<' '>' LE GE EQ NE
%left '+' '-'
%left '*' '/'
%precedence UNIMINUS NOT
%precedence '.' '(' '['

%start program

%%
/*-------------------GLOBAL-------------------*/
program:
    global_decl_list
    ;

global_decl_list:
    global_decl
    | global_decl_list global_decl
    ;

global_decl:
    function_decl
    | function_def
    | class_decl
    | enum_decl
    | import_decl
    ;

/*-------------------ENUM-------------------*/
enum_decl:
    ENUM ID '{' comma_enum_members_list '}'
    ;

comma_enum_members_list:
    enum_members_list
    | enum_members_list ','
    ;

enum_members_list:
    enum_member
    | enum_members_list ',' enum_member
    ;

enum_member:
    ID
    | ID '=' expr
    ;

/*-------------------STMT-------------------*/
stmt_list_e:
    /*EMPTY*/
    | stmt_list
    ;

stmt_list:
    stmt
    | stmt_list stmt
    ;

stmt:
    block
    | ';'
    | if_stmt
    | for_stmt
    | while_stmt
    | do_while_stmt
    | break_stmt
    | continue_stmt
    | var_decl ';'
    | expr ';'
    | return_stmt
    ;

return_stmt: RETURN ';'
           | RETURN expr ';'
           ;

/*-------------------IF-------------------*/
if_stmt:
    IF '(' expr ')' stmt
    | IF '(' expr ')' stmt ELSE stmt
    ;

/*-------------------LOOPS-------------------*/
while_stmt:
    WHILE '(' expr ')' stmt
    ;

for_stmt:
    FOR '(' for_init_e ';' expr_e ';' expr_e ')' stmt
    ;

for_init_e:
    /*EMPTY*/
    | var_decl
    | expr
    ;

do_while_stmt:
    DO stmt WHILE '(' expr ')' ';'
    ;

continue_stmt:
    CONTINUE ';'
    ;

break_stmt:
    BREAK ';'
    ;

/*-------------------TYPE-------------------*/
type:
    base_type
    | ID
    | base_array_type
    | type_or_expr
    ;

base_array_type:
    base_type '[' ']'
    | ID '[' ']'
    | base_array_type '[' expr ']'
    | base_array_type '[' ']'
    | type_or_expr '[' ']'
    ;

type_or_expr://отвечает только за статические массивы а тайп уже отвечает за динамические (птм что может быть только тайпом)
      ID '[' expr ']'
    | type_or_expr '[' expr ']'
    ;

base_type:
    INT
    | CHAR
    | STRING
    | BOOL
    ;

var_decl:
    type ID
    | type ID '=' expr
    ;

/*-------------------EXPR-------------------*/
expr:
    INT_LITERAL
    | CHAR_LITERAL
    | STRING_LITERAL
    | ID
    | TRUE_LITERAL
    | FALSE_LITERAL
    | NULL_LITERAL
    | expr '=' expr
    | expr ADD_ASSIGN expr
    | expr SUB_ASSIGN expr
    | expr MUL_ASSIGN expr
    | expr DIV_ASSIGN expr
    | expr EQ expr
    | expr NE expr
    | expr '<' expr
    | expr '>' expr
    | expr LE expr
    | expr GE expr
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | '-' expr %prec UNIMINUS
    | '!' expr %prec NOT
    | '[' expr_list_e ']' arr_indices_list_e
    | type_or_expr
    | THIS
    | SUPER
    | '(' expr ')' arr_indices_list_e
    | expr '(' expr_list_e ')' arr_indices_list_e
    | expr '.' ID arr_indices_list_e
    | new_expr
    | interpolated_string
    ;

arr_indices_list_e:
    /*EMPTY*/
    | arr_indices_list_e '[' expr ']'
    ;

expr_e:
    /*EMPTY*/
    | expr
    ;

expr_list_e:
    /*EMPTY*/
    | expr_list
    ;

expr_list:
    expr
    | expr_list ',' expr
    ;

/*-------------------FUNCTION-------------------*/

function_decl: type ID '(' param_list_e ')' ';'
             | VOID ID '(' param_list_e ')' ';'
             ;

function_def: type ID '(' param_list_e ')' block
            | VOID ID '(' param_list_e ')' block
            ;

block: '{' stmt_list_e '}'
     ;

param_list_e: /* EMPTY */
            | param_list
            ;

param_list: param
          | param_list ',' param
          ;

param: type ID
     ;
/*-------------------CLASS-------------------*/ // нужен ли struct

class_decl: CLASS ID base_class_e '{' class_member_list_e '}'
          ;

base_class_e: /* EMPTY */
            | ':' ID
            ;

class_member_list_e: /* EMPTY */
                   | class_member_list
                   ;

class_member_list: class_member
                 | class_member_list class_member
                 ;

class_member: member_decl // посмотреть работу вложенных visibility
            | visibility ':'
            | visibility '{' class_member_list_e '}'
            | visibility member_decl
            ;

member_decl : var_decl ';'
            | function_decl
            | function_def
            | constructor_def
            | destructor_def
            | static_member
            | override_method_def
            ;

visibility  : PUBLIC
            | PROTECTED
            ;

constructor_def: THIS '(' param_list_e ')' block
               ;

destructor_def: '~' THIS '(' ')' block
              ;

static_member: STATIC var_decl ';'//уточнить насчет перемены мест визибилити и статик
             | STATIC function_decl
             | STATIC function_def
             ;

override_method_def: OVERRIDE function_def
                   ;

new_expr: NEW ID '(' expr_list_e ')' // нужно ли реализовывать new int или new Foo
        ;

/*-------------------IMPORT------------------- но нужно ли это для ввода вывода??*/
import_decl: IMPORT module_name ';'
           ;

module_name: ID
           | module_name '.' ID
           ;

/*-------------------INTERPOLATION-------------------*/
interpolated_string: ISTRING_BEGIN interpolated_parts_e ISTRING_END
                   ;

interpolated_parts_e: /* EMPTY */
                    | interpolated_parts
                    ;

interpolated_parts: interpolated_part
                  | interpolated_parts interpolated_part
                  ;

interpolated_part: ISTRING_TEXT
                 | INTERP_BEGIN expr INTERP_END
                 ;
%%