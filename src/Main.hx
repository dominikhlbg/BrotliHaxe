package;

import Brotli.*;
import decode.Decode;
import decode.Streams;
import decode.streams.BrotliInput;
import decode.streams.BrotliOutput;
import encode.encode.BrotliParams;
import encode.histogram.Histogram;
import encode.streams.BrotliIn;
import encode.streams.BrotliOut;
import encode.Encode.*;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import haxe.ds.Vector;
#if js
import haxe.crypto.Base64;
import js.Browser.createXMLHttpRequest;
import js.Browser;
#else
import sys.FileSystem;
import sys.io.File;
import encode.Dictionary_hash;
import encode.Static_dict_lut;
import encode.static_dict_lut.DictWord;
#end
import haxe.Http;
import haxe.io.Bytes;
import decode.Decode.*;
import decode.state.BrotliState;
import decode.Streams.*;
import encode.streams.*;
/**
 * ...
 * @author Dominik Homberger
 */
class Main extends decode.Decode
{

#if !js
static function ParseQuality(s:String, quality:Array<Int>) {
	var i = Std.parseInt(s);
  if (i >= 0 && i <= 11) {
    quality[0] = i;
	return true;
  } else
  return false;
}

static function ParseArgv(argc:Int, argv:Array<String>,
                      input_path:Array<String>,
                      output_path:Array<String>,
                      force:Array<Int>,
                      quality:Array<Int>,
                      decompress:Array<Int>) {
  var error = false;
  force[0] = 0;
  input_path[0] = '';
  output_path[0] = '';
  if(argc>0)
  {
    var argv0_len:Int = argv[0].length;
    decompress[0] =
        argv0_len >= 5 && argv[0]== "unbro"?1:0;//[argv0_len - 5] == 0
  } else error = true;
  var k:Int = 0;
  var i:Int = 0;
  if(!error)
  while (i < argc) {
	  k = i++;
    if ("--force"==argv[k] ||
        "-f"==argv[k]) {
      if (force[0] != 0) {
        error = true;
		break;
      }
      force[0] = 1;
      continue;
    } else if ("--decompress"==argv[k] ||
               "--uncompress"==argv[k] ||
               "-d"==argv[k]) {
      decompress[0] = 1;
      continue;
    }
    if (k < argc - 1) {
      if ("--input"==argv[k] ||
          "--in"==argv[k] ||
          "-i"==argv[k]) {
        if (input_path[0] != '') {
          error=true;
 		  break;
       }
        input_path[0] = argv[k + 1];
        ++i;
        continue;
      } else if ("--output"==argv[k] ||
                 "--out"==argv[k] ||
                 "-o"==argv[k]) {
        if (output_path[0] != '') {
          error=true;
		  break;
        }
        output_path[0] = argv[k + 1];
        ++i;
        continue;
      } else if ("--quality"==argv[k] ||
                 "-q"==argv[k]) {
        if (!ParseQuality(argv[k + 1], quality)) {
          error=true;
		  break;
        }
        ++i;
        continue;
      }
    }
    error=true;
	break;
  }
  if (error) {
  Sys.print(
          "Usage: [--force] [--quality n] [--decompress] [--input filename] [--output filename]\n");
		  
  return false;
  }
  return true;
}
#end
	
	static function main() 
	{
		/*trace(Gc.memUsage());var arr = new Vector<cpp.Int8>(100000000);trace(Gc.memUsage());
		for (i in 0...1) {
		arr[i]=0;
		//if(i%100000==0) {
		trace(i);trace(Gc.memUsage());}
		//}trace(1);
		return;*/
#if js
		//var brotliInput = Ajax('hosts');
#else
  var argv = Sys.args();
  var argc = argv.length;
  var input_path:Array<String> = [''];
  var output_path:Array<String> = [''];
  var force:Array<Int> = [0];
  var quality:Array<Int> = [11];
  var decompress:Array<Int> = [0];
  if(!ParseArgv(argc, argv, input_path, output_path, force,
            quality, decompress))
	return;
	if (!FileSystem.exists(input_path[0])) {
		Sys.print('Input Filename doesn\'t exists');
		return;
	}
	if (FileSystem.exists(output_path[0])&&force[0]==0) {
		Sys.print('Output Filename can\'t overwrite');
		return;
	}
	
	var dictionary = OpenInputBinary('dictionary.txt');
	var clock_start = Date.now().getTime();
	var fin = Brotli.OpenInputFile(input_path[0]);
	var fout = Brotli.OpenOutputFile(output_path[0], force[0]);
	if (decompress[0]>0) {
		decode.Dictionary.kBrotliDictionary = dictionary;
		var clock_start = Date.now().getTime();
		var input:BrotliInput = BrotliFileInput(fin);
		var output:BrotliOutput = BrotliFileOutput(fout);
		if (!(BrotliDecompress(input, output)>0)) {
		Sys.print('Error while decoding');
		return;
		};
	} else {
		encode.Dictionary.kBrotliDictionary = dictionary;
		var DictionaryHash = OpenInputBinary('DictionaryHash.txt');
		var DictionaryWords = OpenInputBinary('DictionaryWords.txt');
		var DictionaryBuckets = OpenInputBinary('DictionaryBuckets.txt');
		var kStaticDictionaryHash = Dictionary_hash.kStaticDictionaryHash;
		var kStaticDictionaryBuckets = Static_dict_lut.kStaticDictionaryBuckets;
		for (i in 0...32768) {
			kStaticDictionaryHash.push(DictionaryHash[i * 2 + 1] << 8 | DictionaryHash[i * 2]);
			kStaticDictionaryBuckets.push(DictionaryBuckets[i*3+2]<<16|DictionaryBuckets[i*3+1]<<8|DictionaryBuckets[i*3]);
		}
		
		var kStaticDictionaryWords = Static_dict_lut.kStaticDictionaryWords;
		for (i in 0...31704) {
			var len = DictionaryWords[i*3+1]>>3;
			var idx = (DictionaryWords[i*3+1]&7)<<8|DictionaryWords[i*3];
			var transform = DictionaryWords[i*3+2];
			kStaticDictionaryWords.push(new DictWord(len,transform,idx));//
		}
		var params=new BrotliParams();
		params.quality = quality[0];
			var clock_start = Date.now().getTime();
		var input = new BrotliIn(fin, 1 << 16);
		var output = new BrotliOut(fout);
		if (!BrotliCompress(params, input, output)) {
		Sys.print('Error while encoding');
		return;
		}
	}
	var clock_end = Date.now().getTime();
	var duration:Float =
	(clock_end - clock_start)/1000;// / CLOCKS_PER_SEC;
	if (duration < 1e-9) {
		duration = 1e-9;
	}
	var uncompressed_bytes:Float = decompress[0] > 0 ? fout.tell() : fin.tell();// FileSystem.stat(decompress[0] > 0 ? output_path[0] : input_path[0]).size;FileSystem.stat(output_path[0]).size
	var uncompressed_bytes_in_MB:Float = uncompressed_bytes / (1024.0 * 1024.0);
	var log = 'Filename:' + output_path[0] + ' '+(decompress[0]>0?'de':'')+'compressed size:' + fout.tell() +' '+(decompress[0]>0?'de':'')+'coding time (ms):' + (clock_end - clock_start) + ' ';
    if (decompress[0]>0) {
      log += ("Brotli decompression speed: ");
    } else {
      log += ("Brotli compression speed: ");
    }		
	log += (Std.int(uncompressed_bytes_in_MB / duration*100)/100+" MB/s");
	Sys.print(log);
	
		//var input = File.read('hosts', true);
		//var brotliInput = input.readAll().getData();
		//var brotliInput:Array<UInt> = new Array();
		//for (i in 0...bytes.length)
		//brotliInput[i] = bytes.get(i);
		//input.close;
#end
		/*var maxidx = 0;
		var maxlen = 0;
		var maxtransform = 0;
		for (i in 0...Static_dict_lut.kStaticDictionaryWords.length) {
		var idx = Static_dict_lut.kStaticDictionaryWords[i].idx;
		var len = Static_dict_lut.kStaticDictionaryWords[i].len;
		var transform = Static_dict_lut.kStaticDictionaryWords[i].transform;
		if (idx > maxidx) maxidx = idx;
		if (len > maxlen) maxlen = len;
		if (transform > maxtransform) maxtransform = transform;
		}*/
		
		//var bro = new Brotli();
		//var output = bro.compress(brotliInput,1);
		//var output2 = bro.decompress(output);
		//trace(output.length);
		//trace(output2.length);
		//bro.compress();
		return;/*
#if js
		var dictionary = OpenInputAjax('dictionary.txt');		
		decode.Dictionary.kBrotliDictionary = dictionary;
		encode.Dictionary.kBrotliDictionary = dictionary;
		
		var repeat:Int = 1;
		var data = Ajax('files.txt');
		var files=data.split('\n');
		for (i in 0...files.length) {
			var filename = files[i];
			var fin = OpenInputAjax(filename);
			var fout = new Vector<UInt>(1024 * 1024*12);
			var clock_start = Date.now().getTime();
			var input:BrotliInput = BrotliInitMemInput(fin,fin.length);
			var output:BrotliOutput = BrotliInitMemOutput(fout,fout.length);
			BrotliDecompress(input, output);
			var clock_end = Date.now().getTime();
			var duration:Float =
			(clock_end - clock_start)/1000;// / CLOCKS_PER_SEC;
			if (duration < 1e-9) {
				duration = 1e-9;
			}
			var uncompressed_bytes:Float = repeat * output.data_.pos;
			var uncompressed_bytes_in_MB:Float = uncompressed_bytes / (1024.0 * 1024.0);
			var log = 'Filename:' + filename + ' decompressed size:' + output.data_.pos+' decoding time (ms):' + (clock_end - clock_start) + ' ';
				log += ("Brotli decompression speed: ");
			log += (Std.int(uncompressed_bytes_in_MB / duration*100)/100+" MB/s");
			//if (output.data_.pos >= 1024 * 1024 * 12) { trace('Error'); continue; }
			//var bytes = Bytes.alloc(output.data_.pos);
			//for (i in 0...output.data_.pos)
			//bytes.set(i, output.data_.buffer[i]);
			trace(log);
			//trace('SHA1:'+Sha1.encode(bytes.getString(0,output.data_.pos)));
			//trace('data:text/plain;base64,'+Base64.encode(bytes));
			trace('');
			trace('---');
		}
#else
		var input = File.read('dictionary.txt', true);
		var bytes = input.readAll();
		var dictionary = new Vector<UInt>(bytes.length);
		for (i in 0...bytes.length)
		dictionary[i] = bytes.get(i);
		input.close;
		trace('testdata/dictionary.txt');
		
		decode.Dictionary.kBrotliDictionary = dictionary;
		encode.Dictionary.kBrotliDictionary = dictionary;
			var force:Int = 0;
			var input_path = 'hosts';
			var output_path = 'hosts.compressed';
			var fin = OpenInputFile(input_path);//FILE*
			var fout = OpenOutputFile(output_path, force);//FILE*
		var quality = 1;
      var params=new BrotliParams();
      params.quality = quality;
      var input=new BrotliIn(fin, 1 << 16);
      var output=new BrotliOut(fout);
      if (!BrotliCompress(params, input, output)) {
        //fprintf(stderr, "compression failed\n");
        //unlink(output_path);
        //exit(1);
      }
			var fin = OpenInputFile('hosts.compressed');//FILE*
			var fout = OpenOutputFile('hosts.uncompressed', 1);//FILE*
			var input:BrotliInput = BrotliFileInput(fin);
			var output:BrotliOutput = BrotliFileOutput(fout);
			BrotliDecompress(input, output);*/
		/*var decompress = true;
		var repeat:Int = 1;
		var dir = 'testdata/';
		var files = FileSystem.readDirectory(FileSystem.fullPath(dir));
		for (i in 0...files.length) {
			var file = dir+files[i];
			if (file.indexOf('.compressed') <= 0) continue;
			var input_path = file;// 'x.compressed.03';
			var output_path = ~/.compressed/g.replace(file, '.uncompressed');// 'x.compressed.03.uncomress';
			if (FileSystem.exists(output_path)) continue;
			
			//var input_path = 'x.compressed';
			//var output_path = 'x.uncomress';
			var force:Int = 0;
			var clock_start = Date.now().getTime();
			var fin = OpenInputFile(input_path);//FILE*
			var fout = OpenOutputFile(output_path, force);//FILE*
			var input:BrotliInput = BrotliFileInput(fin);
			var output:BrotliOutput = BrotliFileOutput(fout);
			BrotliDecompress(input, output);
			var clock_end = Date.now().getTime();
			var duration:Float =
			(clock_end - clock_start)/1000;// / CLOCKS_PER_SEC;
			if (duration < 1e-9) {
				duration = 1e-9;
			}
			var uncompressed_bytes:Int = repeat *
				FileSystem.stat(decompress ? output_path : input_path).size;
			var uncompressed_bytes_in_MB:Float = uncompressed_bytes / (1024.0 * 1024.0);
			var log = 'Filename:' + files[i] + ' decompressed size:' + FileSystem.stat(output_path).size+' decoding time (ms):' + (clock_end - clock_start) + ' ';
			if (decompress) {
				log += ("Brotli decompression speed: ");
			} else {
				log += ("Brotli compression speed: ");
			}
			log += (Std.int(uncompressed_bytes_in_MB / duration*100)/100+" MB/s<br>\n");
			Sys.println(log);
			var logfile = File.append('logfile.log', true);
			logfile.writeString(log);
			logfile.close;
			//break;
		}*/
//#end
	}
	public function new() 
	{
		
	}

}