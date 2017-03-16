# BrotliHaxe

BrotliHaxe is a brotli compression decoder and encoder handported from original C to the Haxe Cross-platform-Toolkit that generate readable pure source code in JavaScript, PHP, Python, Java, C#, ActionScript and other.

# New Features!

  - First release

You can also:
  - decode & encode files from brotli compress to uncompress or uncompress to brotli compress.
  - use this source to build your own application.

Brotli is a generic-purpose lossless compression algorithm that compresses data using a combination of a modern variant of the LZ77 algorithm, Huffman coding and 2nd order context modeling, with a compression ratio comparable to the best currently available general-purpose compression methods. It is similar in speed with deflate but offers more dense compression. [Brotli Github][brotli github]

Haxe is an open source toolkit that allows you to easily build cross-platform tools and applications that target many mainstream platforms. [Haxe Github][haxe github]

BrotliHaxe author Dominik Homberger:
> My hope is that people use Haxe to develop and port code to different platforms. It save worktime. Too, my hope is that Python and PHP source code developer optimise the programming language source so that the speed isn't more slower as JavaScript. 

### Build & Execute
BrotliHaxe requires [Haxe](https://haxe.org/) 3.x when you want compile code. (I already put generated source to this git)

Important! This four files must be in the build dir:
- dictionary.txt
- DictionaryBuckets.txt
- DictionaryHash.txt
- DictionaryWords.txt

If you upload the files to webserver then change to binary else you get error while decoding & encoding.

JavaScript

```sh
$ haxe -cp src -js ./javascript/brotli.js -main Main
```
For using as lib see source code at https://dominikhlbg.github.io/brotlijs/

PHP

```sh
$ haxe -cp src -php ./php/ -main Main
$ php ./php/index.php
```

Python

```sh
$ haxe -cp src -python ./python/brotli.py -main Main
$ python ./python/brotli.py
```
Java

```sh
$ haxe -cp src -java ./java/ -main Main
$ java -jar ./java/Main.jar
```
C#

```sh
$ haxe -cp src -cs ./cs/ -main Main
```
ActionScript

```sh
$ not implemented yet
```

### Implement as Lib
Include the Brotli named file. (Java path: src/haxe/root/ else src/ or filename self)
```
include Brotli[.ext]
```
Build new Brotli()
```
var brotli = new Brotli();
```
You have four option. First both are string version. 
```
var decompressedstring = brotli.decompress(compressedstring);
```
```
var compressedstring = brotli.compress(decompressedstring, quality); //quality [1...11]
```
The last two are byte array. [0...255]
```
var decompressedbytearray = brotli.decompressArray(compressedbytearray);
```
```
var compressedbytearray = brotli.compressArray(decompressedbytearray, quality); //quality [1...11]
```

### Benchmark

Here you can see a small benchmark on an i7 2600k CPU.

Brotli Benchmark -q 1 plrabn12.txt

 Language | compress | decompress 
 ------ | ------ | ------ 
 JavaScript (v8) | 414 | 190 
 PHP 5 | 82114 | 4672 |
 Python | 11339 | 5157 
 Java | 353 | 100 |
 C# | 402 | 80 
 original C(++) | 24 | 13 
 
(ms) lower is better


### Development

This source code base on a nearly two years old brotli version but still works good. I'm update to actually soon.

I'm looking for optimise the different outputs. Maybe you can help? Great! But the source code shouldn't looks different from the original source code because that makes updating difficult.

### Todos

 - update to last brotli version
 - remove main build for library version

License
----

MIT

> See license file and if you like you can add my name.


**That is my first source code that I release under MIT!**

   [brotli github]: <https://github.com/google/brotli/>
   [haxe github]: <https://github.com/HaxeFoundation/haxe/>
