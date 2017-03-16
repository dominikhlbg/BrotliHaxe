package encode.entropy_encode;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class EntropyCode
{

	public function new(kSize:Int) 
	{
		depth_ = FunctionMalloc.mallocUInt(kSize);
		bits_ = FunctionMalloc.mallocUInt(kSize);
	}
	
  // How many bits for symbol.
	public var depth_:Vector<UInt>;
  // Actual bits used to represent the symbol.
  public var bits_:Vector<UInt>;
  // How many non-zero depth.
	public var count_:Int;
  // First four symbols with non-zero depth.
  public var symbols_:Vector<UInt>=FunctionMalloc.mallocUInt(4);
}