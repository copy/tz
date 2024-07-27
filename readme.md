# tz

A command line program to show a table of timezones. It always shows your
current timezone, as well as the timezones specied.

Example:

<pre>
$ tz mexico japan
Mexico City | 21 22 23  0  1  2  3  4  5  6  7  8  <b>9</b> 10 11 12 13 14 15 16 17 18 19 20 21
<b>Berlin</b>      |  5  6  7  8  9 10 11 12 13 14 15 16 <b>17</b> 18 19 20 21 22 23  0  1  2  3  4  5
Japan       | 12 13 14 15 16 17 18 19 20 21 22 23  <b>0</b>  1  2  3  4  5  6  7  8  9 10 11 12
</pre>

#### Building

Assumes a working installation of [opam](https://opam.ocaml.org/).

```
opam install dune timedesc
dune build
```
