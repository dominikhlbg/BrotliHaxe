package decode.prefix;

/**
 * ...
 * @author 
 */
class PrefixCodeRange
{
	public var offset:Int;
	public var nbits:Int;

	public function new(offset:Int,nbits:Int) 
	{
		this.offset = offset;
		this.nbits = nbits;
	}
	
}