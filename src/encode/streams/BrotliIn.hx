package encode.streams;
import haxe.ds.Vector;
import haxe.io.Bytes;
#if !js
import sys.io.FileInput;
import haxe.io.Eof;
#end
import DefaultFunctions;
/**
 * ...
 * @author 
 */
class BrotliIn
{
#if !js

	var f_:FileInput;//FILE*
  var buffer_:Vector<UInt>;//void*
  var buffer_size_:Int;//size_t

	public function new(f:FileInput, max_read_size:Int) 
	{
      this.f_ = f;
      this.buffer_=FunctionMalloc.mallocUInt(max_read_size);
      this.buffer_size_=max_read_size;
	}
	public function Read( n:Int, bytes_read:Array<UInt>):Vector<UInt> {
  if (buffer_ == null) {
    bytes_read[0] = 0;
    return null;
  }
  if (n > buffer_size_) {
    n = buffer_size_;
  } else if (n == 0) {
    return f_.eof() ? null : buffer_;
  }
  if (f_.eof())
  return null;
	var bytes:Bytes = Bytes.alloc(n);
		try {
	var size:Int=f_.readBytes(bytes,0,n);
	for (i in 0...size)
	buffer_[i] = bytes.get(i);
  bytes_read[0] = size;
		} catch( e : Eof ) {
		}
  if (bytes_read[0] == 0) {
    return null;
  } else {
    return buffer_;
  }
}
	
#end
}