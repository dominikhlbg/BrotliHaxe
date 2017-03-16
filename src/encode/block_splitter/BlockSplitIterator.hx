package encode.block_splitter;
import encode.metablock.BlockSplit;

/**
 * ...
 * @author 
 */
class BlockSplitIterator
{

	public function new(split:BlockSplit) 
	{
      split_ = split; idx_ = 0; type_ = 0; length_ = 0;
    if (!(split.lengths.length==0)) {
      length_ = split.lengths[0];
    }		
	}
	
	public function Next() {
    if (length_ == 0) {
      ++idx_;
      type_ = split_.types[idx_];
      length_ = split_.lengths[idx_];
    }
    --length_;
  }

  public var split_:BlockSplit;
  public var idx_:Int;
  public var type_:Int;
  public var length_:Int;
}