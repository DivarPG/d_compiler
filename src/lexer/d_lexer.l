%option noyywrap never-interactive yylineno stack
%x ML_COMMENT
%x COMMENT
%x NESTED_COMMENT
%x STRING
%x CHARACTER
%x STRING_INTERP
%s INTERPOLATION

%{
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <string>
#include <algorithm>
#include <vector>
#include <unordered_map>

void append_utf8(std::string& s, unsigned long cp);
bool is_valid_unicode(unsigned long cp);
bool resolve_html_code(const std::string& name, std::string& out);

void printIdentifier(const char* identifier);
void printIntegerLiteral(const char* literal);
void printFloatLiteral(const char* literal);

void printTypeDefinitionKeyword(const char* keyword);
void printModificatorKeyword(const char* keyword);
void printMembersDeclarationKeyword(const char* keyword);
void printControlStructureKeyword(const char* keyword);
void printInheritKeyword(const char* keyword);
void printObjectDefinitionKeyword(const char* keyword);
void printContextKeyword(const char* keyword);
void printConstantKeyword(const char* keyword);
void printOperator(const char* oper);
void printSyntaxToken(const char* token);

std::string remove_underscore(const char* text);
long long to_int(const char* text, int base = 10);
double to_double(const char* text);
void add_character_value();

std::string str = "";
std::string comment = "";
std::string string_buffer = "";
int comment_depth = 0;
std::vector<int> interp_depth_stack;
bool string_with_error = false;
bool char_found = false;
%}
whitespace [ \t\f\v]
decdigits [0-9][0-9_]*
hexdigits [0-9a-fA-F][0-9a-fA-F_]*
bindigits [01][01_]*
intsuffix (L|u|U|Lu|LU|uL|UL)
floatsuffix (f|F|L)?
exponent [eE][+-]?[0-9][0-9_]*

%%
"//" {
    comment.clear();
    comment.append(yytext);
    yy_push_state(COMMENT);
}

<COMMENT>[^\r\n]+ {
    comment.append(yytext);
}

<COMMENT>\r\n {
    comment.append(yytext);
    std::cout << "[COMMENT]: " << comment << std::endl;
    comment.clear();
    yy_pop_state();
}

<COMMENT>\r|\n {
    comment.append(yytext);
    std::cout << "[COMMENT]: " << comment << std::endl;
    comment.clear();
    yy_pop_state();
}

<COMMENT><<EOF>> {
    std::cout << "[COMMENT]: " << comment << std::endl;
    comment.clear();
    yy_pop_state();
}

"/*" { comment.clear(); comment.append(yytext); comment_depth = 1;
       yy_push_state(ML_COMMENT);}
<ML_COMMENT>"/*" {comment.append(yytext); ++comment_depth; }
<ML_COMMENT>"*/" { comment.append(yytext); --comment_depth;
                    if (comment_depth == 0) {std::cout <<  "[C0MMENT]: " << comment << std::endl;
                    comment.clear();
                    yy_pop_state();}}
<ML_COMMENT>\n {comment.append(yytext); }
<ML_COMMENT>[^*\n]+ {comment.append(yytext); }
<ML_COMMENT>"*" {comment.append(yytext); }
<ML_COMMENT><<EOF>> { std::cerr << "ERROR - unterminated comment\n"; return 1; }

"/+" { comment.clear(); comment.append(yytext); comment_depth = 1;
       yy_push_state(NESTED_COMMENT);}
<NESTED_COMMENT>"/+" {comment.append(yytext); ++comment_depth; }
<NESTED_COMMENT>"+/" { comment.append(yytext); --comment_depth;
                        if (comment_depth == 0) {
                        std::cout <<  "[COMMENT]: " << comment << std::endl;
                        comment.clear();
                        yy_pop_state();}}
<NESTED_COMMENT>\n {comment.append(yytext); }
<NESTED_COMMENT>[^+/\n]+ {comment.append(yytext); }
<NESTED_COMMENT>"+" {comment.append(yytext); }
<NESTED_COMMENT>"/" {comment.append(yytext); }
<NESTED_COMMENT><<EOF>> { std::cerr << "ERROR - unterminated nested comment\n"; return 1; }

\" {string_with_error = false; yy_push_state(STRING); str="";}
<STRING,STRING_INTERP,CHARACTER>\\\' { str.append(1, '\''); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\\? { str.append(1, '\?'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\0 { str.append(1, '\0'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\a { str.append(1, '\a'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\n { str.append(1, '\n'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\r { str.append(1, '\r'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\t { str.append(1, '\t'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\f { str.append(1, '\f'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\b { str.append(1, '\b'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\v { str.append(1, '\v'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\\" { str.append(1, '\"'); add_character_value();}
<STRING,STRING_INTERP,CHARACTER>\\{2} {str.append(1, '\\'); add_character_value();}

<STRING,STRING_INTERP,CHARACTER>\\[0-7]{1,3} {
        long v = strtol(yytext + 1, NULL, 8);
        if (v > 0xFF) {
            std::cerr << "ERROR - octal escape is greater than \\377: " << yytext << std::endl;;
            string_with_error = true;
            }
        else {
            str += (char)v;
            add_character_value();
        }
    }

<STRING,STRING_INTERP,CHARACTER>\\x[0-9a-fA-F]{2} { unsigned long ch = strtoul(yytext + 2, NULL, 16); add_character_value(); str.append(1, ch); }

<STRING,STRING_INTERP,CHARACTER>\\u[0-9a-fA-F]{4} {
        unsigned long ch = strtoul(yytext + 2, NULL, 16);
        if (!is_valid_unicode(ch)) {
            std::cerr << "ERROR - invalid code point: " << yytext << std::endl;
            string_with_error = true;
        }
        else {
            append_utf8(str, ch);
            add_character_value();
        }
    }
<STRING,STRING_INTERP,CHARACTER>\\U[0-9a-fA-F]{8} {
        unsigned long ch = strtoul(yytext + 2, NULL, 16);
        if (!is_valid_unicode(ch)) {
            std::cerr << "ERROR - invalid code point: " << yytext << std::endl;
            string_with_error = true;
        }
        else {
            append_utf8(str, ch);
            add_character_value();
        }
    }
<STRING,STRING_INTERP,CHARACTER>\\&[A-Za-z0-9]+;   {
        std::string name(yytext + 2, yyleng - 3), out;
        if (resolve_html_code(name, out)) {
            if (YY_START == STRING_INTERP)
                string_buffer += out;
            else {
                str += out;
                add_character_value();
            }
        }
        else {
            std::cerr << "ERROR - unknown named entity: " << yytext << std::endl;
            string_with_error = true; }
    }
<STRING,STRING_INTERP,CHARACTER>\\& { std::cerr << "ERROR - unknown named entity, expected \\&name;" << std::endl; string_with_error = true; }

<STRING>\n {std::cerr << "ERROR - EOL in string\n" << std::endl; string_with_error = true;}
<STRING>\\\n {}
<STRING,CHARACTER>\\. { std::cerr << "ERROR - unknown escape sequence: " << yytext << "\n"; string_with_error = true; }
<STRING>[^\n\r\\\"]+ { str.append(yytext); }
<STRING>\" {
        if(!string_with_error)
            std::cout << "[STRING LITERAL]: " << str << std::endl;
        yy_pop_state();
    }
<STRING><<EOF>> {std::cerr << "ERROR - unclosed quote" << std::endl; string_with_error = true; yy_pop_state(); }

\' {string_with_error = false; char_found = false; yy_push_state(CHARACTER); str="";}
<CHARACTER>[^'\\\n\r] { str.append(yytext); add_character_value();}
<CHARACTER>\' {if(!string_with_error) std::cout << "[CHARACTER LITERAL]: " << str << std::endl; yy_pop_state();}
<CHARACTER>\n {std::cerr << "ERROR - EOL in character literal\n" << std::endl; string_with_error = true; yy_pop_state();}
<CHARACTER><<EOF>> {std::cerr << "ERROR - unclosed character literal\n"; string_with_error = true; yy_pop_state();}

i\" {
    yy_push_state(STRING_INTERP);
    string_buffer.clear();
    std::cout << "[INTERPOLATED STRING START]" << std::endl;
}

<STRING_INTERP>[^\\\"\$]+ { string_buffer.append(yytext); }

<STRING_INTERP>\\\$  { string_buffer.append("$"); }
<STRING_INTERP>\\\"  { string_buffer.append("\""); }
<STRING_INTERP>\\n   { string_buffer.append("\n"); }
<STRING_INTERP>\\t   { string_buffer.append("\t"); }
<STRING_INTERP>\\r   { string_buffer.append("\r"); }
<STRING_INTERP>\\\\  { string_buffer.append("\\"); }
<STRING_INTERP>\\(.|\n) { string_buffer.append(yytext); }

<STRING_INTERP>\$ { string_buffer.append("$"); }

<STRING_INTERP>\$\( {
    if (!string_buffer.empty()) {
        std::cout << "[STRING PART]: " << string_buffer << std::endl;
        string_buffer.clear();
    }
    std::cout << "[INTERPOLATION START]: $(" << std::endl;
    interp_depth_stack.push_back(1);
    yy_push_state(INTERPOLATION);
}

<INTERPOLATION>\( {
    ++interp_depth_stack.back();
    printOperator(yytext);
}


<INTERPOLATION>\) {
    if (--interp_depth_stack.back() == 0) {
        interp_depth_stack.pop_back();
        std::cout << "[INTERPOLATION END]: )" << std::endl;
        yy_pop_state();
    } else {
        printOperator(yytext);
    }
}

<STRING_INTERP>\" {
    if (!string_buffer.empty()) {
        std::cout << "[STRING PART]: " << string_buffer << std::endl;
        string_buffer.clear();
    }
    std::cout << "[INTERPOLATED STRING END]" << std::endl;
    yy_pop_state();
}

<STRING_INTERP><<EOF>> {
    std::cerr << "ERROR: unclosed interpolated string" << std::endl;
    yy_pop_state();
}

<INTERPOLATION><<EOF>> {
    std::cerr << "ERROR: unclosed interpolation $()" << std::endl;
    if (!interp_depth_stack.empty()) interp_depth_stack.pop_back();
    yy_pop_state();
}

"bool" { printTypeDefinitionKeyword(yytext); }
"byte" { printTypeDefinitionKeyword(yytext); }
"ubyte" { printTypeDefinitionKeyword(yytext); }
"short" { printTypeDefinitionKeyword(yytext); }
"ushort" { printTypeDefinitionKeyword(yytext); }
"int" { printTypeDefinitionKeyword(yytext); }
"uint" { printTypeDefinitionKeyword(yytext); }
"long" { printTypeDefinitionKeyword(yytext); }
"ulong" { printTypeDefinitionKeyword(yytext); }
"template" { printTypeDefinitionKeyword(yytext); }
"__vector" { printTypeDefinitionKeyword(yytext); }

"char" { printTypeDefinitionKeyword(yytext); }
"wchar" { printTypeDefinitionKeyword(yytext); }
"dchar" { printTypeDefinitionKeyword(yytext); }
"float" { printTypeDefinitionKeyword(yytext); }
"double" { printTypeDefinitionKeyword(yytext); }
"real" { printTypeDefinitionKeyword(yytext); }
"void" { printTypeDefinitionKeyword(yytext); }

"class" { printTypeDefinitionKeyword(yytext); }
"interface" { printTypeDefinitionKeyword(yytext); }
"struct" { printTypeDefinitionKeyword(yytext); }
"union" { printTypeDefinitionKeyword(yytext); }
"enum" { printTypeDefinitionKeyword(yytext); }

"abstract" { printModificatorKeyword(yytext); }
"final" { printModificatorKeyword(yytext); }
"override" { printModificatorKeyword(yytext); }
"private" { printModificatorKeyword(yytext); }
"protected" { printModificatorKeyword(yytext); }
"public" { printModificatorKeyword(yytext); }

"deprecated" { printModificatorKeyword(yytext); }
"extern" { printModificatorKeyword(yytext); }
"export" { printModificatorKeyword(yytext); }
"static" { printModificatorKeyword(yytext); }
"synchronized" { printModificatorKeyword(yytext); }

"const" { printModificatorKeyword(yytext); }
"immutable" { printModificatorKeyword(yytext); }
"inout" { printModificatorKeyword(yytext); }
"shared" { printModificatorKeyword(yytext); }
"pure" { printModificatorKeyword(yytext); }
"nothrow" { printModificatorKeyword(yytext); }

"ref" { printModificatorKeyword(yytext); }
"scope" { printModificatorKeyword(yytext); }
"lazy" { printModificatorKeyword(yytext); }
"__gshared" { printModificatorKeyword(yytext); }

"alias" { printTypeDefinitionKeyword(yytext); }
"align" { printTypeDefinitionKeyword(yytext); }

"delegate" { printMembersDeclarationKeyword(yytext); }
"function" { printMembersDeclarationKeyword(yytext); }
"module" { printMembersDeclarationKeyword(yytext); }
"import" { printMembersDeclarationKeyword(yytext); }
"package" { printMembersDeclarationKeyword(yytext); }

"if" { printControlStructureKeyword(yytext); }
"else" { printControlStructureKeyword(yytext); }
"switch" { printControlStructureKeyword(yytext); }
"case" { printControlStructureKeyword(yytext); }
"default" { printControlStructureKeyword(yytext); }

"while" { printControlStructureKeyword(yytext); }
"do" { printControlStructureKeyword(yytext); }
"for" { printControlStructureKeyword(yytext); }
"foreach" { printControlStructureKeyword(yytext); }
"foreach_reverse" { printControlStructureKeyword(yytext); }

"continue" { printControlStructureKeyword(yytext); }
"break" { printControlStructureKeyword(yytext); }
"goto" { printControlStructureKeyword(yytext); }
"return" { printControlStructureKeyword(yytext); }

"try" { printControlStructureKeyword(yytext); }
"catch" { printControlStructureKeyword(yytext); }
"finally" { printControlStructureKeyword(yytext); }
"throw" { printControlStructureKeyword(yytext); }

"asm" { printControlStructureKeyword(yytext); }
"assert" { printControlStructureKeyword(yytext); }
"pragma" { printControlStructureKeyword(yytext); }
"macro" { printControlStructureKeyword(yytext); }
"mixin" { printControlStructureKeyword(yytext); }

"debug" { printControlStructureKeyword(yytext); }
"version" { printControlStructureKeyword(yytext); }
"unittest" { printControlStructureKeyword(yytext); }
"out" { printControlStructureKeyword(yytext); }
"in" { printControlStructureKeyword(yytext); }

"true" { printConstantKeyword(yytext); }
"false" { printConstantKeyword(yytext); }
"null" { printConstantKeyword(yytext); }

"new" { printObjectDefinitionKeyword(yytext); }
"this" { printObjectDefinitionKeyword(yytext); }
"super" { printObjectDefinitionKeyword(yytext); }


"cast" { printOperator(yytext); }
"is" { printOperator(yytext); }
"typeid" { printOperator(yytext); }
"typeof" { printOperator(yytext); }

"auto" { printContextKeyword(yytext); }
"invariant" { printContextKeyword(yytext); }
"with" { printContextKeyword(yytext); }
"__FILE__" { printContextKeyword(yytext); }
"__FILE_FULL_PATH__" { printContextKeyword(yytext); }
"__FUNCTION__" { printContextKeyword(yytext); }
"__LINE__" { printContextKeyword(yytext); }
"__MODULE__" { printContextKeyword(yytext); }
"__PRETTY_FUNCTION__" { printContextKeyword(yytext); }
"__parameters" { printContextKeyword(yytext); }
"__rvalue" { printContextKeyword(yytext); }
"__traits" { printContextKeyword(yytext); }

"..." { printOperator(yytext); }
".." { printOperator(yytext); }
"." { printSyntaxToken(yytext); }

"/=" { printOperator(yytext); }
"/" { printOperator(yytext); }

"&&" { printOperator(yytext); }
"&=" { printOperator(yytext); }
"&" { printOperator(yytext); }

"||" { printOperator(yytext); }
"|=" { printOperator(yytext); }
"|" { printOperator(yytext); }

"--" { printOperator(yytext); }
"-=" { printOperator(yytext); }
"-" { printOperator(yytext); }

"++" { printOperator(yytext); }
"+=" { printOperator(yytext); }
"+" { printOperator(yytext); }

"<<=" { printOperator(yytext); }
"<<" { printOperator(yytext); }
"<=" { printOperator(yytext); }
"<" { printOperator(yytext); }

">>>=" { printOperator(yytext); }
">>=" { printOperator(yytext); }
">>>" { printOperator(yytext); }
">>" { printOperator(yytext); }
">=" { printOperator(yytext); }
">" { printOperator(yytext); }

"!=" { printOperator(yytext); }
"!" { printOperator(yytext); }

"==" { printOperator(yytext); }
"=>" { printOperator(yytext); }
"=" { printOperator(yytext); }

"*=" { printOperator(yytext); }
"*" { printOperator(yytext); }

"%=" { printOperator(yytext); }
"%" { printOperator(yytext); }

"^^=" { printOperator(yytext); }
"^=" { printOperator(yytext); }
"^^" { printOperator(yytext); }
"^" { printOperator(yytext); }

"~=" { printOperator(yytext); }
"~" { printOperator(yytext); }

"(" { printOperator(yytext); }
")" { printOperator(yytext); }
"[" { printOperator(yytext); }
"]" { printOperator(yytext); }
"{" { printOperator(yytext); }
"}" { printOperator(yytext); }

"," { printSyntaxToken(yytext); }
";" { printSyntaxToken(yytext); }
":" { printSyntaxToken(yytext); }

"?" { printOperator(yytext); }
"$" { printOperator(yytext); }
"@" { printOperator(yytext); }

[A-Za-z_][A-Za-z0-9_]* { printIdentifier(yytext); }
0[xX]{hexdigits}(\.{hexdigits})?[pP][+-]?[0-9][0-9_]*{floatsuffix} { printFloatLiteral(yytext); }
0[xX]{hexdigits}{intsuffix}? { printIntegerLiteral(yytext); }
0[bB]{bindigits}{intsuffix}? { printIntegerLiteral(yytext); }
{decdigits}\.{decdigits}{exponent}?{floatsuffix} { printFloatLiteral(yytext); }
{decdigits}\.{floatsuffix}/[^.] { printFloatLiteral(yytext); }
{decdigits}{exponent}{floatsuffix} { printFloatLiteral(yytext); }
{decdigits}{intsuffix}? { printIntegerLiteral(yytext); }

{whitespace}+  { std::cout << "+++Whitespace+++" << std::endl; }
\r {}
"\n" { std::cout<< std::endl << "------------------Newline------------------" << std::endl; }

<*>. { std::cerr << "Unexpected char \'" << yytext[0] << "\'"<< std::endl;}

%%


int main(int argc, char **argv)
{
    if(argc < 2)
    {
        printf("\nNot enough arguments. Please specify filename.\n");
        return -1;
    }
    if((yyin = fopen(argv[1], "r")) == NULL)
    {
        printf("Cannot open file %s.\n", argv[1]);
        return -1;
    }
    yyin = fopen(argv[1], "r");
    yylex();
    fclose(yyin);
    return 0;
}

void add_character_value()
{
    if (YY_START == CHARACTER) {
        if (char_found) {
            string_with_error = true;
            std::cerr << yylineno << ": ERROR - char literal can contain only one symbol" << std::endl;
        }
        else
            char_found = true;
    }
}

long long to_int(const char* text, int base) {
    std::string s = remove_underscore(text);
    return strtoll(s.c_str(), NULL, base);
}

std::string remove_underscore(const char* text) {
    std::string s(text);
    s.erase(std::remove(s.begin(), s.end(), '_'), s.end());
    return s;
}

double to_double(const char* text) {
    std::string s = remove_underscore(text);
    return atof(s.c_str());
}

bool is_valid_unicode(unsigned long cp) {
    return cp <= 0x10FFFF && !(cp >= 0xD800 && cp <= 0xDFFF);
}

void append_utf8(std::string& s, unsigned long cp) {
    if (cp < 0x80) {
        s += (char)cp;
    } else if (cp < 0x800) {
        s += (char)(0xC0 | (cp >> 6));
        s += (char)(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
        s += (char)(0xE0 | (cp >> 12));
        s += (char)(0x80 | ((cp >> 6) & 0x3F));
        s += (char)(0x80 | (cp & 0x3F));
    } else {
        s += (char)(0xF0 | (cp >> 18));
        s += (char)(0x80 | ((cp >> 12) & 0x3F));
        s += (char)(0x80 | ((cp >> 6) & 0x3F));
        s += (char)(0x80 | (cp & 0x3F));
    }
}

bool resolve_html_code(const std::string& name, std::string& out) {
    static const std::unordered_map<std::string, unsigned long> table = {
        {"euro", 0x20AC}, {"amp", '&'}, {"lt", '<'}, {"gt", '>'}, {"quot", '"'},
        {"copy", 0xA9}, {"frac12", 0xBD}, {"alpha", 0x3B1}, {"Alpha", 0x391},
    };
    auto it = table.find(name);
    if (it == table.end()) return false;
    out.clear();
    append_utf8(out, it->second);
    return true;
}

void printTypeDefinitionKeyword(const char* keyword) {
    printf("[TYPE DEFINITION KEYWORD]: %s\n", keyword);
}

void printModificatorKeyword(const char* keyword) {
    printf("[MODIFICATOR DEFINITION KEYWORD]: %s\n", keyword);
}

void printMembersDeclarationKeyword(const char* keyword) {
    printf("[MEMBER DECLARATION KEYWORD]: %s\n", keyword);
}

void printControlStructureKeyword(const char* keyword) {
    printf("[CONTROL STRUCTURE KEYWORD]: %s\n", keyword);
}

void printInheritKeyword(const char* keyword) {
    printf("[INHERIT KEYWORD]: %s\n", keyword);
}

void printObjectDefinitionKeyword(const char* keyword) {
    printf("[OBJECT DEFINITION KEYWORD]: %s\n", keyword);
}

void printContextKeyword(const char* keyword) {
    printf("[CONTEXT KEYWORD]: %s\n", keyword);
}

void printConstantKeyword(const char* keyword) {
    printf("[CONSTANT KEYWORD]: %s\n", keyword);
}

void printOperator(const char* oper) {
    printf("[OPERATOR]: %s\n", oper);
}

void printSyntaxToken(const char* token) {
    printf("[SYNTAX TOKEN]: %s\n", token);
}

void printIdentifier(const char* identifier)
{
    printf("[ID]: %s\n", identifier);
}

void printIntegerLiteral(const char* literal)
{
    printf("[INT LITERAL]: %s\n", literal);
}

void printFloatLiteral(const char* literal)
{
    printf("[FLOAT LITERAL]: %s\n", literal);
}
