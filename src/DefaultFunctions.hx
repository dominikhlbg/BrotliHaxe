package;
import haxe.ds.Vector;
/*@:coreType abstract Size_t from UInt { }
@:coreType abstract UInt8_t from UInt { }
@:coreType abstract UInt16_t from UInt { }
@:coreType abstract UInt32_t from UInt { }
@:coreType abstract UInt64_t from UInt { }*/

/**
 * ...
 * @author ...
 */
class DefaultFunctions
{
	@:generic public static function memset<T>(b:Vector<T>, offset:Int, v:T, count) {
		for (i in 0...count)
		b[offset+i] = v;
	}
	@:generic public static function memcpy<T>(dst:Vector<T>, dst_offset:Int, src:Vector<T>, src_offset:Int, count) {
		for (i in 0...count)
		dst[dst_offset+i] = src[src_offset+i];
	}
	public static function memcpyArray(dst:Array<UInt>, dst_offset:Int, src:Array<UInt>, src_offset:Int, count) {
		for (i in 0...count)
		dst[dst_offset+i] = src[src_offset+i];
	}
	public static function memcpyVectorArray(dst:Vector<UInt>, dst_offset:Int, src:Array<UInt>, src_offset:Int, count) {
		for (i in 0...count)
		dst[dst_offset+i] = src[src_offset+i];
	}
	public static function memcpyArrayVector(dst:Array<UInt>, dst_offset:Int, src:Vector<UInt>, src_offset:Int, count) {
		for (i in 0...count)
		dst[dst_offset+i] = src[src_offset+i];
	}


	public function new() 
	{
		
	}
	
}