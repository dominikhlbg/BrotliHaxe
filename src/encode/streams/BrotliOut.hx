package encode.streams;
import haxe.ds.Vector;
import haxe.io.Bytes;
#if !js
import sys.io.FileOutput;
#end
import DefaultFunctions;

/**
 * ...
 * @author 
 */
class BrotliOut
{
#if !js
	var f_:FileOutput;

	public function new(f:FileOutput) 
	{
		f_ = f;
	}
	public function Write(buf:Vector<Int>, n:Int):Bool {
	var bytes:Bytes = Bytes.alloc(n);
	for (i in 0...n)
	bytes.set(i,buf[i]);
	f_.write(bytes);
  //if (fwrite(buf, n, 1, f_) != 1) {
  //  return false;
  //}
  return true;
}
#end

	
}