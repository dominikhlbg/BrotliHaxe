package encode.hash;

/**
 * ...
 * @author 
 */
class BackwardMatch
{
	public function BackwardMatch0() { distance = 0; length_and_code = 0; }

	public function BackwardMatch2(dist:Int, len:Int){
	distance = dist; length_and_code = (len << 5); }

  public function BackwardMatch3(dist:Int, len:Int, len_code:Int)
      { distance = dist;
	  length_and_code = (len << 5) | (len == len_code ? 0 : len_code); }

public function length():Int {
    return length_and_code >> 5;
  }
  public function length_code():Int {
	  var code:Int = length_and_code & 31;
    return code>0 ? code : length();
  }

  public var distance:Int;
  public var length_and_code:Int;

	public function new() 
	{
		
	}
	
}