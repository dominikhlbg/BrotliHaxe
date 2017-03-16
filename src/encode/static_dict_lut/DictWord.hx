package encode.static_dict_lut;

/**
 * ...
 * @author 
 */
class DictWord
{

	public var len:UInt;
  public var transform:UInt;
  public var idx:UInt;
	public function new(len:UInt,transform:UInt,idx:UInt) 
	{
		this.len = len;
		this.transform = transform;
		this.idx = idx;
	}
	
}