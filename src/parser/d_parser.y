%token BOOL INT FLOAT DOUBLE VOID
%token CHAR STRING
%token CLASS ENUM OVERRIDE PRIVATE PROTECTED PUBLIC
%token STATIC CONST IMPORT
%token IF ELSE SWITCH CASE DEFAULT
%token WHILE DO FOR
%token CONTINUE BREAK RETURN
%token TRY CATCH FINALLY THROW
%token TRUE FALSE NULL
%token NEW THIS SUPER

%token INT_LITERAL FLOAT_LITERAL  DOUBLE_LITERAL
%token STRING_LITERAL CHAR_LITERAL
%token TRUE_LITERAL FALSE_LITERAL
%token NULL_LITERAL
%token ID

%token ISTRING_BEGIN ISTRING_TEXT ISTRING_END
%token INTERP_BEGIN INTERP_END

%right '=' ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN
%left OR
%left AND
%left '<' '>' LE GE EQ NE
%left '+' '-'
%left '*' '/' '%'
%right UNIMINUS NOT
%left '.' '(' '['

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
  ENUM ID '{' enum_members_list '}'
  ;

enum_members_list:
  enum_member
  | enum_members_list ',' enum_member
  | enum_members_list ','
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
  | switch_stmt
  | for_stmt
  | while_stmt
  | do_while_stmt
  | var_decl ';'
  | expr ';'
  | return_stmt
  | try_stmt
  | throw_stmt
  ;

return_stmt: RETURN ';'
           | RETURN expr ';'
           ;

/*-------------------IF-------------------*/
if_stmt:
    if
    | if ELSE stmt
    ;

if:
    IF '(' expr ')' stmt
    ;

switch_stmt:
    SWITCH '(' expr ')' '{' case_list '}'
    ;

case_list:
    case
    | case_list case
    ;

case:
    CASE expr_list ':' stmt_list_e
    | DEFAULT ':' stmt_list_e
    ;

/*-------------------LOOPS-------------------*/
while_stmt:
  WHILE '(' expr ')' stmt
  ;

for_stmt:
  FOR '(' var_decl ';' expr_e ';' expr_e ')' stmt
      ;

do_while_stmt:
  DO stmt WHILE '(' expr ')' ';'
  ;

/*-------------------TYPE-------------------*/
type:
  base_type
  | ID
  | type '[' ']'
  | type '[' expr ']'
  ;

base_type:
  INT
  | FLOAT
  | DOUBLE
  | CHAR
  | STRING
  | BOOL
  ;

var_decl:
  type ID var_init
  ;

var_init:
  /*EMPTY*/
  | '=' expr
  ;

/*-------------------EXPR-------------------*/
expr:
    INT_LITERAL
    | FLOAT_LITERAL
    | CHAR_LITERAL
    | STRING_LITERAL
    | DOUBLE_LITERAL
    | ID
    | TRUE_LITERAL
    | FALSE_LITERAL
    | NULL_LITERAL
    | expr '=' expr
    | expr ADD_ASSIGN expr
    | expr SUB_ASSIGN expr
    | expr MUL_ASSIGN expr
    | expr DIV_ASSIGN expr
    | expr MOD_ASSIGN expr
    | expr OR expr
    | expr AND expr
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
    | expr '%' expr
    | UNIMINUS expr %prec UNIMINUS
    | NOT expr %prec NOT
    | '[' expr_list_e ']'
    | expr '[' expr ']'
    | THIS
    | SUPER
    | '(' expr ')'
    | expr '(' expr_list_e ')'
    | expr '.' ID
    | new_expr
    | interpolated_string
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

class_member: member_decl
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

static_member: STATIC var_decl ';'
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

/*-------------------EXCEPTION-------------------*/
try_stmt: TRY block catch_list
        | TRY block catch_list_e FINALLY block
        ;

catch_list_e: /* EMPTY */
            | catch_list
            ;

catch_list: catch_item
          | catch_list catch_item
          ;

catch_item: CATCH '(' catch_param ')' block
          ;

catch_param: param | type
           ;

throw_stmt: THROW expr ';' // может быть expr как пример bool proceed = ready || throw new Exception("не готово"); но надо ли
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