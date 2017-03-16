package encode.streams;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class BrotliMemOut
{

	public function new(buf:Array<UInt>) //, len:Int
	{
      buf_ = buf;
      //len_=len;
      pos_=0;	
	}
	
	public function position():Int { return pos_; }
	public var buf_:Array<UInt>;  // start of output buffer
  //var len_:Int;  // length of output
  var pos_:Int;  // current write position within output

public function Reset(buf:Array<UInt>, len:Int) {
  buf_ = buf;
  //len_ = len;
  pos_ = 0;
}

public function Write(buf:Vector<UInt>, n:Int) {
  //if (n + pos_ > len_)
  //  return false;
  var p:Array<UInt> = buf_;
  var p_off:Int = 0 + pos_;
  DefaultFunctions.memcpyArrayVector(p,p_off, buf,0, n);
  pos_ += n;
  return true;
}
}