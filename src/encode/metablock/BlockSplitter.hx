package encode.metablock;
import haxe.ds.Vector;
import encode.histogram.Histogram;
import encode.Bit_cost.*;

/**
 * ...
 * @author 
 */
class BlockSplitter
{

	public function new(HistogramTypeInt:Int,alphabet_size:Int,
                min_block_size:Int,
                split_threshold:Float,
                num_symbols:Int,
                split:BlockSplit,//*Array<>
                histograms:Array<Histogram>) 
	{
		this.HistogramTypeInt = HistogramTypeInt;
		alphabet_size_ = alphabet_size;
        min_block_size_=min_block_size;
        split_threshold_=split_threshold;
        num_blocks_=0;
        split_=split;
        histograms_=histograms;
        target_block_size_=min_block_size;
        block_size_=0;
        curr_histogram_ix_=0;
        merge_last_count_=0;
    var max_num_blocks:Int = Std.int(num_symbols / min_block_size) + 1;
    // We have to allocate one more histogram than the maximum number of block
    // types for the current histogram when the meta-block is too big.
    var max_num_types:Int = Std.int(Math.min(max_num_blocks, kMaxBlockTypes + 1));
    split_.lengths = new Array();// Malloc.mallocInt(max_num_blocks);//TODO:
    split_.types = new Array();// Malloc.mallocInt(max_num_blocks);
	for(i in 0...max_num_types)
    histograms_.push(new Histogram(HistogramTypeInt));// Malloc.malloc(Histogram, max_num_types);
    last_histogram_ix_[0] = last_histogram_ix_[1] = 0;
	}
	
  // Adds the next symbol to the current histogram. When the current histogram
  // reaches the target size, decides on merging the block.
  public function AddSymbol(symbol:Int) {
    histograms_[curr_histogram_ix_].Add1(symbol);
    ++block_size_;
    if (block_size_ == target_block_size_) {
      FinishBlock(/* is_final = */ false);
    }
  }

  // Does either of three things:
  //   (1) emits the current block with a new block type;
  //   (2) emits the current block with the type of the second last block;
  //   (3) merges the current block with the last block.
  public function FinishBlock(is_final:Bool) {
    if (block_size_ < min_block_size_) {
      block_size_ = min_block_size_;
    }
    if (num_blocks_ == 0) {
      // Create first block.
      split_.lengths[0] = block_size_;
      split_.types[0] = 0;
      last_entropy_[0] =
          BitsEntropy(histograms_[0].data_,0, alphabet_size_);
      last_entropy_[1] = last_entropy_[0];
      ++num_blocks_;
      ++split_.num_types;
      ++curr_histogram_ix_;
      block_size_ = 0;
    } else if (block_size_ > 0) {
      var entropy:Float = BitsEntropy(histograms_[curr_histogram_ix_].data_,0,
                                   alphabet_size_);
      var combined_histo:Array<Histogram> = [new Histogram(HistogramTypeInt),new Histogram(HistogramTypeInt)];// [2];
      var combined_entropy=FunctionMalloc.mallocFloat(2);
      var diff=FunctionMalloc.mallocFloat(2);
      for (j in 0...2) {
        var last_histogram_ix:Int = last_histogram_ix_[j];
        //combined_histo[j] = histograms_[curr_histogram_ix_];
		
		  //TODO:
          combined_histo[j].bit_cost_ = histograms_[curr_histogram_ix_].bit_cost_;
		  for(a in 0...histograms_[curr_histogram_ix_].data_.length)
          combined_histo[j].data_[a] = histograms_[curr_histogram_ix_].data_[a];
          combined_histo[j].kDataSize = histograms_[curr_histogram_ix_].kDataSize;
          combined_histo[j].total_count_ = histograms_[curr_histogram_ix_].total_count_;
		  
        combined_histo[j].AddHistogram(histograms_[last_histogram_ix]);
        combined_entropy[j] = BitsEntropy(
            combined_histo[j].data_,0, alphabet_size_);
        diff[j] = combined_entropy[j] - entropy - last_entropy_[j];
      }

      if (split_.num_types < kMaxBlockTypes &&
          diff[0] > split_threshold_ &&
          diff[1] > split_threshold_) {
        // Create new block.
        split_.lengths[num_blocks_] = block_size_;
        split_.types[num_blocks_] = split_.num_types;
        last_histogram_ix_[1] = last_histogram_ix_[0];
        last_histogram_ix_[0] = split_.num_types;
        last_entropy_[1] = last_entropy_[0];
        last_entropy_[0] = entropy;
        ++num_blocks_;
        ++split_.num_types;
        ++curr_histogram_ix_;
        block_size_ = 0;
        merge_last_count_ = 0;
        target_block_size_ = min_block_size_;
      } else if (diff[1] < diff[0] - 20.0) {
        // Combine this block with second last block.
        split_.lengths[num_blocks_] = block_size_;
        split_.types[num_blocks_] = split_.types[num_blocks_ - 2];
		var t = last_histogram_ix_[0];
		last_histogram_ix_[0] = last_histogram_ix_[1];
		last_histogram_ix_[1] = t;
        //histograms_[last_histogram_ix_[0]] = combined_histo[1];
		
		  //TODO:
          histograms_[last_histogram_ix_[0]].bit_cost_ = combined_histo[1].bit_cost_;
		  for(a in 0...combined_histo[1].data_.length)
          histograms_[last_histogram_ix_[0]].data_[a] = combined_histo[1].data_[a];
          histograms_[last_histogram_ix_[0]].kDataSize = combined_histo[1].kDataSize;
          histograms_[last_histogram_ix_[0]].total_count_ = combined_histo[1].total_count_;
		  
        last_entropy_[1] = last_entropy_[0];
        last_entropy_[0] = combined_entropy[1];
        ++num_blocks_;
        block_size_ = 0;
        histograms_[curr_histogram_ix_].Clear();
        merge_last_count_ = 0;
        target_block_size_ = min_block_size_;
      } else {
        // Combine this block with last block.
        split_.lengths[num_blocks_ - 1] += block_size_;
        //histograms_[last_histogram_ix_[0]] = combined_histo[0];
		
		  //TODO:
          histograms_[last_histogram_ix_[0]].bit_cost_ = combined_histo[0].bit_cost_;
		  for(a in 0...combined_histo[0].data_.length)
          histograms_[last_histogram_ix_[0]].data_[a] = combined_histo[0].data_[a];
          histograms_[last_histogram_ix_[0]].kDataSize = combined_histo[0].kDataSize;
          histograms_[last_histogram_ix_[0]].total_count_ = combined_histo[0].total_count_;
		  
        last_entropy_[0] = combined_entropy[0];
        if (split_.num_types == 1) {
          last_entropy_[1] = last_entropy_[0];
        }
        block_size_ = 0;
        histograms_[curr_histogram_ix_].Clear();
        if (++merge_last_count_ > 1) {
          target_block_size_ += min_block_size_;
        }
      }
    }
    if (is_final) {//TODO:
		while (histograms_.length > split_.num_types) histograms_.pop();
		while (split_.types.length > num_blocks_) split_.types.pop();
		while (split_.lengths.length > num_blocks_) split_.lengths.pop();
      /*histograms_.resize(split_.num_types);
      split_.types.resize(num_blocks_);
      split_.lengths.resize(num_blocks_);*/
    }
  }

  static var kMaxBlockTypes:Int = 256;

  var HistogramTypeInt:Int;
  // Alphabet size of particular block category.
  var alphabet_size_:Int;
  // We collect at least this many symbols for each block.
  var min_block_size_:Int;
  // We merge histograms A and B if
  //   entropy(A+B) < entropy(A) + entropy(B) + split_threshold_,
  // where A is the current histogram and B is the histogram of the last or the
  // second last block type.
  var split_threshold_:Float;

  var num_blocks_:Int;
  var split_:BlockSplit;  // not owned
  var histograms_:Array<Histogram>;//std::vector<HistogramType>*  // not owned

  // The number of symbols that we want to collect before deciding on whether
  // or not to merge the block with a previous one or emit a new block.
  var target_block_size_:Int;
  // The number of symbols in the current histogram.
  var block_size_:Int;
  // Offset of the current histogram.
  var curr_histogram_ix_:Int;
  // Offset of the histograms of the previous two block types.
  var last_histogram_ix_:Array<Int>=new Array();// [2];
  // Entropy of the previous two block types.
  var last_entropy_:Array<Float>=new Array();// [2];
  // The number of times we merged the current block with the last one.
  var merge_last_count_:Int;
}