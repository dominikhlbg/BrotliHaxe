package encode;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class Port
{
public static inline function BROTLI_UNALIGNED_LOAD32(p:Vector<UInt>,p_off:Int) {
  return p[p_off+3]<<24|p[p_off+2]<<16|p[p_off+1]<<8|p[p_off+0];
}

	public static inline function PREDICT_FALSE(x):Bool { return x; }
	public static inline function PREDICT_TRUE(x):Bool { return x; }

	public function new() 
	{
		
	}
	
}