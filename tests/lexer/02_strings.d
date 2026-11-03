module test;

import std.stdio;
import std.string;

public class Person {
    private string name;
    private int age;

    this(string name, int age) {
        this.name = name;
        this.age = age;
    }

    public void print() {
        if (age >= 18) {
            writeln("adult");
        } else {
            writeln("child");
        }
    }

    public bool isAdult() {
        return age >= 18;
    }
}

int main() {
    int x = 100;
    uint y = 0xFF;
    int z = 0b1010;

    double pi = 3.14159;
    double e = 1.5e+10;

    x += 10;
    x++;
    x--;

    if (x == y && y != z) {
        x = x << 2;
    }

    while (x > 0) {
        x--;
    }

    for (int i = 0; i < 10; i++) {
        writeln(i);
    }

    foreach (value; [1, 2, 3]) {
        writeln(value);
    }

    try {
        throw new Exception();
    } catch (Exception e) {
        writeln(e);
    } finally {
        writeln("done");
    }

    return 0;
}

bool byte ubyte short ushort int uint long ulong
char wchar dchar float double real void

class interface struct union enum

abstract final override private protected public
deprecated extern export static synchronized
const immutable inout shared pure nothrow
ref scope lazy __gshared

alias align

delegate function module import package

if else switch case default
while do for foreach foreach_reverse
continue break goto return

try catch finally throw

asm assert pragma macro mixin
debug version unittest out in

true false null

new this super

cast is typeid typeof

auto invariant with
__FILE__ __FILE_FULL_PATH__ __FUNCTION__
__LINE__ __MODULE__ __PRETTY_FUNCTION__
__parameters __rvalue __traits

a + b - c * d / e % f
a++ b--
a += b -= c *= d /= e %= f

a & b | c && d || e
a &= b |= c

a << b <<= c
a >> b >>= c
a >>> b >>>= c

a < b <= c > d >= e
a == b != c

a = b => c

a ^ b ^= c ^^ d ^^= e
a ~ b ~= c
!a

a.b a..b a...b

(a)
[b]
{c}

a, b;
a : b;
a ? b : c;
a $ b;
a @ b;

123
1_000
123L
123u
123UL

0xFF
0xDEAD_BEEF
0xFFUL

0b1010
0b1010_0101
0b1111UL

3.14
1.5e10
1.5e-10
1.0f

0x1p0
0x1.5p+10f

identifier
my_variable
__test__
Class123

i"Hello, $(name)!"
i"Age: $(age)"
i"$(x)"
i"prefix $(var) suffix"
i"$(a) $(b) $(c)"

i"Result: $(1 + 2)"
i"Sum: $(x + y)"
i"$(10 * 5 - 3)"
i"$(a + b + c)"
i"$(x * y / z)"

i"Length: $(strlen(name))"
i"Upper: $(toUpper(text))"
i"Result: $(foo())"
i"$(bar(x, y))"

i"$(foo(bar(x)))"
i"$(outer(inner(a, b), c))"
i"$(func1(func2(func3())))"
i"$(max(a, min(b, c)))"

i"First: $(arr[0])"
i"Element: $(matrix[i][j])"
i"$(data[index + 1])"
i"$(array[func()])"

i"Name: $(obj.name)"
i"Property: $(obj.prop.subprop)"
i"$(obj.method())"
i"$(obj.arr[0].field)"

i"Outer: $(func(i"Inner: $(value)"))"
i"Level1: $(i"Level2: $(x)")"
i"A $(i"B $(i"C") B") A"

i"Quote: $(x)\" end"
i"Dollar: \$(not_interpolated) but $(this_is)"
i"Backslash: \\$(x)"
i"Tab:\t$(value)"
i"Newline:\n$(text)"

i"$(condition ? trueVal : falseVal)"
i"$(x > 0 ? "positive" : "negative")"
i"$(a && b ? func(x) : func(y))"
i"$(x is null ? "null" : x.toString())"

i"$(str.toLower().trim())"
i"$(obj.method1().method2().method3())"

i"First line: $(x)
Second line: $(y)
Third line: $(z)"

i"Start
Middle: $(func(
    arg1,
    arg2
))
End"

i"$( (x) )"
i"$(f(g(h(x))))"
i"Multiple $(x) in $(y) same $(z) string"
i"Consecutive$(x)$(y)$(z)"

i"$(a + b * c)"
i"$((a + b) * c)"
i"$(~flags)"
i"$(++counter)"
i"$(x << 2)"
i"$(a & b)"
i"$(a || b)"
i"$(a == b)"
i"$(a != b)"

i""
i"$(identifier)"
i"$(_variable)"
i"$(Class123)"

i"$(123)"
i"$(1_000)"
i"$(0xFF)"
i"$(0b1010)"
i"$(3.14)"
i"$(1.5e10)"

i"$(if)"
i"$(while)"
i"$(int)"
i"$(class)"
i"$(true)"
i"$(false)"

i"$(+)"
i"$(-)"
i"$(*)"
i"$(/)"
i"$(=)"
i"$(==)"
i"$(!=)"

i"Привет, $(name)! Через год тебе будет $(text(i"$(age + 1)"))."
i"Dollar: \$(name)"
i"\$(not_interp)"
i"line1\
line2"
i"\x41 \u00e9 \&euro;"
"\x41 \u00e9 \&euro;"
"\&euro;"