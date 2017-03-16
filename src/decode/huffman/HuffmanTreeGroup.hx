package decode.huffman;
import haxe.ds.Vector;

/**
 * ...
 * @author 
 */
/* Contains a collection of huffman trees with the same alphabet size. */
class HuffmanTreeGroup
{

	public var alphabet_size:Int;
	public var num_htrees:Int;
	public var codes:Vector<HuffmanCode>;//*
	public var htrees:Array<Vector<HuffmanCode>>;//**
	public var htrees_off:Array<Int>;
	public function new() 
	{
		
	}
	
}