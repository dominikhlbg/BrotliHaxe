package encode.brotli_bit_stream;
import haxe.ds.Vector;
import encode.Brotli_bit_stream.*;
import encode.histogram.Histogram;
import encode.Write_bits.*;

/**
 * ...
 * @author 
 */
class BlockEncoder
{

	public function new(alphabet_size:Int,
               num_block_types:Int,
               block_types:Array<Int>,
               block_lengths:Array<Int>) 
	{
		alphabet_size_ = alphabet_size;
        num_block_types_=num_block_types;
        block_types_=block_types;
        block_lengths_=block_lengths;
        block_ix_=0;
        block_len_=block_lengths.length==0 ? 0 : block_lengths[0];
        entropy_ix_=0;
	}
	
  public function BuildAndStoreBlockSwitchEntropyCodes(storage_ix:Array<Int>, storage:Vector<UInt>) {
    BuildAndStoreBlockSplitCode(
        block_types_, block_lengths_, num_block_types_,
        block_split_code_, storage_ix, storage);
  }

  public function BuildAndStoreEntropyCodes(
      histograms:Array<Histogram>,
      storage_ix:Array<Int>, storage:Vector<UInt>) {
    depths_=FunctionMalloc.mallocUInt(histograms.length * alphabet_size_);
    bits_=FunctionMalloc.mallocUInt(histograms.length * alphabet_size_);
    for (i in 0...histograms.length) {
      var ix:Int = i * alphabet_size_;
      BuildAndStoreHuffmanTree(histograms[i].data_, alphabet_size_,
                               depths_,ix, bits_,ix,
                               storage_ix, storage);
    }
  }

  public function StoreSymbol(symbol:Int, storage_ix:Array<Int>, storage:Vector<UInt>) {
    if (block_len_ == 0) {
      ++block_ix_;
      block_len_ = block_lengths_[block_ix_];
      entropy_ix_ = block_types_[block_ix_] * alphabet_size_;
      StoreBlockSwitch(block_split_code_, block_ix_, storage_ix, storage);
    }
    --block_len_;
    var ix:Int = entropy_ix_ + symbol;
    WriteBits(depths_[ix], bits_[ix], storage_ix, storage);
  }

  public function StoreSymbolWithContext(kContextBits:Int, symbol:Int, context:Int,
                              context_map:Vector<Int>,
                              storage_ix:Array<Int>, storage:Vector<UInt>) {
    if (block_len_ == 0) {
      ++block_ix_;
      block_len_ = block_lengths_[block_ix_];
      entropy_ix_ = block_types_[block_ix_] << kContextBits;
      StoreBlockSwitch(block_split_code_, block_ix_, storage_ix, storage);
    }
    --block_len_;
    var histo_ix:Int = context_map[entropy_ix_ + context];
    var ix:Int = histo_ix * alphabet_size_ + symbol;
    WriteBits(depths_[ix], bits_[ix], storage_ix, storage);
  }

  var alphabet_size_:Int;
  var num_block_types_:Int;
	var block_types_:Array<Int>;
	var block_lengths_:Array<Int>;
  var block_split_code_=new BlockSplitCode();
  var block_ix_:Int;
  var block_len_:Int;
  var entropy_ix_:Int;
	var depths_:Vector<UInt>;
	var bits_:Vector<UInt>;
}