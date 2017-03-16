package encode.prefix;

/**
 * ...
 * @author 
 */
class PrefixCodeRange
{

	public function new(offset:Int,nbits:Int) 
	{
		this.offset = offset;
		this.nbits = nbits;
	}
	
	public var offset:Int;
  public var nbits:Int;
}