package encode.brotli_bit_stream;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
class BlockSplitCode
{

	public function new() 
	{
		
	}
	
  public var type_code:Vector<Int>;
  public var length_prefix:Vector<Int>;
  public var length_nextra:Vector<Int>;
  public var length_extra:Vector<Int>;
  public var type_depths:Vector<UInt>;
  public var type_bits:Vector<UInt>;
  public var length_depths:Vector<UInt>;
  public var length_bits:Vector<UInt>;
}