package encode.streams;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class BrotliMemIn
{

	public function new(buf:Array<UInt>, len:Int) 
	{
      buf_ = buf;
      len_=len;
      pos_=0;		
	}
	
	public function position():UInt { return pos_; }
	var buf_:Array<UInt>;  // start of input buffer
	var len_:Int;  // length of input
	var pos_:Int;  // current read position within input

	public function Reset(buf:Array<UInt>, len:Int) {
      buf_ = buf;
      len_ = len;
      pos_ = 0;
	}

	public function Read(n:Int, output:Array<Int>):Vector<UInt> {
	  if (pos_ == len_) {
		return null;
	  }
	  if (n > len_ - pos_)
		n = len_ - pos_;
	  var p:Vector<UInt> = new Vector<UInt>(n);
	  DefaultFunctions.memcpyVectorArray(p, 0, buf_, 0 + pos_, n);
	  pos_ += n;
	  output[0] = n;
	  return p;
	}
}