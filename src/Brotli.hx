package;
import encode.Dictionary_hash;
import encode.Static_dict_lut;
import haxe.ds.Vector;
import haxe.io.Bytes;
import decode.Streams.*;
import encode.streams.*;
import Main.*;
import decode.streams.BrotliInput;
import decode.streams.BrotliOutput;
import encode.encode.BrotliParams;
import encode.streams.BrotliIn;
import encode.streams.BrotliOut;
import decode.Decode.*;
import encode.Encode.*;
import encode.static_dict_lut.DictWord;
#if js
import haxe.crypto.Base64;
import js.Browser.createXMLHttpRequest;
import js.Browser;
#else
import sys.FileSystem;
import sys.io.File;
#end

/**
 * ...
 * @author 
 */
@:expose
class Brotli
{
	#if !js
	public static function OpenInputFile(input_path:String) {
	  if (input_path.length == 0) {
	  }
	  var f = File.read(input_path, true);
		//var f = File.getBytes(input_path);
	  return f;
	}
	public static function OpenOutputFile(output_path:String, force:Int) {
	  if (output_path.length == 0) {
	  }
	  return File.write(output_path, true);
	}
	public static function OpenInputBinary(input_path:String) {
		#if !python
		var input = File.read(input_path, true);
		var bytes = input.readAll();
		var content = new Vector<UInt>(bytes.length);
		for (i in 0...bytes.length)
		content[i] = bytes.get(i);
		input.close;
		#else
		var input = File.getBytes(input_path);
		var content = new Vector<UInt>(input.length);
		for (i in 0...input.length)
		content[i] = input.get(i);
		#end
		return content;
	}
	#else
	function OpenInputAjax(input_path:String):Vector<UInt> {
		var response:Vector<UInt>=new Vector<UInt>(0);
		var http = createXMLHttpRequest();
		http.open('get', input_path, false);
		if(http.overrideMimeType!=null)
		http.overrideMimeType('text/plain; charset=x-user-defined');
		else
		http.setRequestHeader('Accept-Charset', 'x-user-defined');
		http.send(null);
		//http.onreadystatechange = function() {
			if (http.readyState == 4) {
				if(untyped __js__('http["responseBody"]')!=null) {
					response = untyped __js__('http["responseBody"]["toArray"]()');
				} else 
				if(http.responseText!=null) {
					var responseText = http.responseText.split('');
					response = new Vector<UInt>(responseText.length);
					for(i in 0...responseText.length)
					response[i] = responseText[i].charCodeAt(0) & 0xff;
				}
			}
		//}
	  return response;
	}
	function Ajax(input_path:String) {
		var http = createXMLHttpRequest();
		http.open('get', input_path, false);
		if(http.overrideMimeType!=null)
		http.overrideMimeType('text/plain; charset=x-user-defined');
		else
		http.setRequestHeader('Accept-Charset', 'x-user-defined');
		http.send(null);
		return http.responseText;
	}
	#end

	public function new(?dictionary_path='dictionary.txt') 
	{
#if !js
		/*var data = File.write('DictionaryWords.txt', true);
		var bytes:Bytes = Bytes.alloc(Static_dict_lut.kStaticDictionaryWords.length*3);
		for (i in 0...Static_dict_lut.kStaticDictionaryWords.length) {
			var len = Static_dict_lut.kStaticDictionaryWords[i].len;
			var transform = Static_dict_lut.kStaticDictionaryWords[i].transform;
			var idx = Static_dict_lut.kStaticDictionaryWords[i].idx;
			bytes.set(i*3,idx&255);
			bytes.set(i*3+1,len<<3|(idx>>8&7));
			bytes.set(i*3+2,transform);
		}
		data.write(bytes);	
		data.close();
		
		var data = File.write('DictionaryBuckets.txt', true);
		var bytes:Bytes = Bytes.alloc(Static_dict_lut.kStaticDictionaryBuckets.length*3);
		for (i in 0...Static_dict_lut.kStaticDictionaryBuckets.length * 3) {
			var kStaticDictionaryBuckets = Static_dict_lut.kStaticDictionaryBuckets[i];
			bytes.set(i*3+2,kStaticDictionaryBuckets>>16&255);
			bytes.set(i*3+1,kStaticDictionaryBuckets>>8&255);
			bytes.set(i*3,kStaticDictionaryBuckets&255);			
		}
		data.write(bytes);	
		data.close();
		var data = File.write('DictionaryHash.txt', true);
		var bytes:Bytes = Bytes.alloc(Dictionary_hash.kStaticDictionaryHash.length*2);
		for (i in 0...Dictionary_hash.kStaticDictionaryHash.length * 2) {
			var kStaticDictionaryHash = Dictionary_hash.kStaticDictionaryHash[i];
			bytes.set(i*2+1,kStaticDictionaryHash>>8&255);
			bytes.set(i*2,kStaticDictionaryHash&255);			
		}
		data.write(bytes);	
		data.close();
		
		var DictionaryHash = OpenInputBinary('DictionaryHash.txt');
		var DictionaryWords = OpenInputBinary('DictionaryWords.txt');
		var DictionaryBuckets = OpenInputBinary('DictionaryBuckets.txt');
		var kStaticDictionaryHash = Dictionary_hash.kStaticDictionaryHash;
		for (i in 0...32768)
			if (kStaticDictionaryHash[i] != (DictionaryHash[i * 2 + 1] << 8 | DictionaryHash[i * 2]))
				trace('error');
		
		var kStaticDictionaryWords = Static_dict_lut.kStaticDictionaryWords;
		for (i in 0...31704) {
			var len = DictionaryWords[i*3+1]>>3;
			var idx = (DictionaryWords[i*3+1]&7)<<8|DictionaryWords[i*3];
			var transform = DictionaryWords[i*3+2];
			if (kStaticDictionaryWords[i].len != len ||
			kStaticDictionaryWords[i].transform != transform ||
			kStaticDictionaryWords[i].idx != idx)
				trace('error');
		}
		var kStaticDictionaryBuckets = Static_dict_lut.kStaticDictionaryBuckets;
		for(i in 0...32768)
			if (kStaticDictionaryBuckets[i] != (DictionaryBuckets[i*3+2]<<16|DictionaryBuckets[i*3+1]<<8|DictionaryBuckets[i*3]))
				trace('error');
		
		return;*/
#end		
		
#if js
		var dictionary = OpenInputAjax(dictionary_path);
		var DictionaryHash = OpenInputAjax('DictionaryHash.txt');
		var DictionaryWords = OpenInputAjax('DictionaryWords.txt');
		var DictionaryBuckets = OpenInputAjax('DictionaryBuckets.txt');
#else
		var dictionary = OpenInputBinary(dictionary_path);
		var DictionaryHash = OpenInputBinary('DictionaryHash.txt');
		var DictionaryWords = OpenInputBinary('DictionaryWords.txt');
		var DictionaryBuckets = OpenInputBinary('DictionaryBuckets.txt');
#end		
		decode.Dictionary.kBrotliDictionary = dictionary;
		encode.Dictionary.kBrotliDictionary = dictionary;
		
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
		//for(i in 0...32768)	
	}
	
	/*public function BrotliFromFileToString(filename:String):String {
		var fin = OpenInputFile(filename);
		var fout = new Array<UInt>();
		var input:BrotliInput = BrotliFileInput(fin);
		var output:BrotliOutput = BrotliInitMemOutput(fout);
		BrotliDecompress(input, output);
		var bytes = Bytes.alloc(output.data_.pos);
		for (i in 0...output.data_.pos)
		bytes.set(i, output.data_.buffer[i]);
		return bytes.getString(0, output.data_.pos);
	}

	#if js
	public function BrotliFromUrlToString(Url:String):String {
		var fin = OpenInputAjax(filename);
		var input:BrotliInput = BrotliInitMemInput(fin,fin.length);
		var output:BrotliOutput = BrotliInitMemOutput(fout);
		BrotliDecompress(input, output);	
		var bytes = Bytes.alloc(output.data_.pos);
		for (i in 0...output.data_.pos)
		bytes.set(i, output.data_.buffer[i]);
		return bytes.getString(0, output.data_.pos);
	}
	#end
	public function BrotliToFileFromString(content:String, filename:String, overwrite:Int, q:Int) {
		var fin = new Array<UInt>();
		for (i in 0...content.length)
		fin[i] = content.charCodeAt(i);
		var fout = OpenOutputFile(filename, overwrite);
		var input:BrotliInput = BrotliInitMemInput(fin,fin.length);
		var output:BrotliOutput = BrotliFileOutput(fout);
		BrotliDecompress(input, output);
		var bytes = Bytes.alloc(output.data_.pos);
		for (i in 0...output.data_.pos)
		bytes.set(i, output.data_.buffer[i]);
		return bytes.getString(0, output.data_.pos);
	}*/
	public function decompress(content:Dynamic):Dynamic {
		var fin = new Array<UInt>();
		for (i in 0...content.length)
		fin[i] = content.charCodeAt(i);
		var fout = new Array<UInt>();
		var input:BrotliInput = BrotliInitMemInput(fin,fin.length);
		var output:BrotliOutput = BrotliInitMemOutput(fout);
		BrotliDecompress(input, output);
		var bytes = Bytes.alloc(output.data_.pos);
		for (i in 0...output.data_.pos)
		bytes.set(i, output.data_.buffer[i]);
		return bytes.getString(0, output.data_.pos);
	}
	public function compress(content:Dynamic, quality:Int):Dynamic {
		if (quality < 0 || quality > 11) { trace('Quality 0...11'); return null; }
		var fin = new Array<UInt>();
		for (i in 0...content.length)
		fin[i] = content.charCodeAt(i);
		var fout = new Array<UInt>();
		var params=new BrotliParams();
		params.quality = quality;
		var input=new BrotliMemIn(fin, fin.length);
		var output=new BrotliMemOut(fout);
		if (!BrotliCompress(params, input, output)) {
		}
		var bytes = Bytes.alloc(output.position());
		for (i in 0...output.position())
		bytes.set(i, output.buf_[i]);
		return bytes.getString(0, output.position());
	}
	public function decompressArray(content:Dynamic):Dynamic {
		var fin = content;
		var fout = new Array<UInt>();
		var input:BrotliInput = BrotliInitMemInput(fin,fin.length);
		var output:BrotliOutput = BrotliInitMemOutput(fout);
		BrotliDecompress(input, output);
		return output.data_.buffer.slice(0, output.data_.pos);
	}
	public function compressArray(content:Dynamic, quality:Int):Dynamic {
		if (quality < 0 || quality > 11) { trace('Quality 0...11'); return null; }
		var fin = content;
		var fout = new Array<UInt>();
		var params=new BrotliParams();
		params.quality = quality;
		var input=new BrotliMemIn(fin, fin.length);
		var output=new BrotliMemOut(fout);
		if (!BrotliCompress(params, input, output)) {
		}
		var bytes = Bytes.alloc(output.position());
		for (i in 0...output.position())
		bytes.set(i, output.buf_[i]);
		return output.buf_.slice(0, output.position());
	}
}