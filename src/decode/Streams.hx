package decode;
import DefaultFunctions;
import decode.streams.BrotliInput;
import decode.streams.BrotliMemInput;
import decode.streams.BrotliMemOutput;
import decode.streams.BrotliOutput;
import haxe.ds.Vector;
import haxe.io.Bytes;
import streams.*;
#if !js
import sys.io.FileInput;
import sys.io.FileOutput;
#end

/**
 * ...
 * @author 
 */
class Streams
{
//h
//38
/* Reads len bytes into buf, using the in callback. */
	static public function BrotliRead(input:BrotliInput, buf:Vector<UInt>, buf_off:Int, len:Int):Int {
	  return input.cb_(input.data_, buf, buf_off, len);
	}

//53
/* Writes len bytes into buf, using the out callback. */
	static public function BrotliWrite(out:BrotliOutput,
                                     buf:Vector<UInt>, buf_off:Int, len:Int):Int {
	return out.cb_(out.data_, buf, buf_off, len);
	}
static public function BrotliMemInputFunction(data, buf:Vector<UInt>, buf_off:Int, count:Int):Int {//void* 
  var input:BrotliMemInput = data;//*(BrotliMemInput*)
  if (input.pos > input.length) {
    return -1;
  }
  if (input.pos + count > input.length) {
    count = input.length - input.pos;
  }
  DefaultFunctions.memcpyVectorArray(buf, buf_off, input.buffer, 0 + input.pos, count);
  input.pos += count;
  return count;
}

static public function BrotliInitMemInput(buffer:Array<UInt>, length:Int):BrotliInput {
  var input:BrotliInput = new BrotliInput();
  var mem_input:BrotliMemInput = new BrotliMemInput();
  mem_input.buffer = buffer;
  mem_input.length = length;
  mem_input.pos = 0;
  input.cb_ = BrotliMemInputFunction;//&
  input.data_ = mem_input;
  return input;
}

static public function BrotliMemOutputFunction(data, buf:Vector<UInt>, buf_off:Int, count:Int):Int {
  var output:BrotliMemOutput = data;
  //var limit:Int = output.length - output.pos;
  //if (count > limit) {
  //  count = limit;
  //}
  DefaultFunctions.memcpyArrayVector(output.buffer, 0 + output.pos, buf, buf_off, count);
  output.pos += count;
  return count;
}

static public function BrotliInitMemOutput(buffer:Array<UInt>):BrotliOutput {//, length:Int
  var output:BrotliOutput=new BrotliOutput();
  var mem_output:BrotliMemOutput=new BrotliMemOutput();
  mem_output.buffer = buffer;
  //mem_output.length = length;
  mem_output.pos = 0;
  output.cb_ = BrotliMemOutputFunction;//&
  output.data_ = mem_output;
  return output;
}
#if js
#else
static public function BrotliFileInputFunction(data:FileInput, buf:Vector<UInt>, buf_off:Int, count:Int):Int {
	var bytes:Bytes = Bytes.alloc(count);
	var size:Int=data.readBytes(bytes,0,count);
	for (i in 0...size)
	buf[buf_off+i] = bytes.get(i);
  return size;
}

static public function BrotliFileInput(f):BrotliInput {
  var input:BrotliInput=new BrotliInput();
  input.cb_ = BrotliFileInputFunction;
  input.data_ = f;
  return input;
}

static public function BrotliFileOutputFunction(data:FileOutput, buf:Vector<UInt>, buf_off:Int, count:Int):Int {
	var bytes:Bytes = Bytes.alloc(count);
	for (i in 0...count)
	bytes.set(i,buf[i]);
	data.write(bytes);
  return bytes.length;
}

static public function BrotliFileOutput(f):BrotliOutput {
  var out:BrotliOutput=new BrotliOutput();
  out.cb_ = BrotliFileOutputFunction;
  out.data_ = f;
  return out;
}
#end

	public function new() 
	{
		
	}
	
}