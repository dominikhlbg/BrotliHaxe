package encode.metablock;
import encode.histogram.Histogram;
import haxe.ds.Vector;
import encode.Bit_cost.*;

/**
 * ...
 * @author 
 */
class ContextBlockSplitter
{

	public function new(HistogramTypeInt:Int,alphabet_size:Int,
                       num_contexts:Int,
                       min_block_size:Int,
                       split_threshold:Float,
                       num_symbols:Int,
                       split:BlockSplit,
                       histograms:Array<Histogram>) 
	{
		this.HistogramTypeInt = HistogramTypeInt;
		alphabet_size_ = alphabet_size;
        num_contexts_=num_contexts;
        max_block_types_=Std.int(kMaxBlockTypes / num_contexts);
        min_block_size_=min_block_size;
        split_threshold_=split_threshold;
        num_blocks_=0;
        split_=split;
        histograms_=histograms;
        target_block_size_=min_block_size;
        block_size_=0;
        curr_histogram_ix_=0;
        last_entropy_=FunctionMalloc.mallocFloat(2 * num_contexts);//TODO:
        merge_last_count_=0;
    var max_num_blocks:Int = Std.int(num_symbols / min_block_size) + 1;
    // We have to allocate one more histogram than the maximum number of block
    // types for the current histogram when the meta-block is too big.
    var max_num_types:Int = Std.int(Math.min(max_num_blocks, max_block_types_ + 1));
    split_.lengths= new Array();//Malloc.mallocInt(max_num_blocks);//TODO:
    split_.types =  new Array();//Malloc.mallocInt(max_num_blocks);
	for(i in 0...max_num_types * num_contexts)
    histograms_.push(new Histogram(HistogramTypeInt));
    last_histogram_ix_[0] = last_histogram_ix_[1] = 0;
	}
	
  // Adds the next symbol to the current block type and context. When the
  // current block reaches the target size, decides on merging the block.
  public function AddSymbol(symbol:Int, context:Int) {
    histograms_[curr_histogram_ix_ + context].Add1(symbol);
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
      for (i in 0...num_contexts_) {
        last_entropy_[i] =
            BitsEntropy(histograms_[i].data_,0, alphabet_size_);
        last_entropy_[num_contexts_ + i] = last_entropy_[i];
      }
      ++num_blocks_;
      ++split_.num_types;
      curr_histogram_ix_ += num_contexts_;
      block_size_ = 0;
    } else if (block_size_ > 0) {
      // Try merging the set of histograms for the current block type with the
      // respective set of histograms for the last and second last block types.
      // Decide over the split based on the total reduction of entropy across
      // all contexts.
      var entropy=new Vector<Float>(num_contexts_);
      var combined_histo = new Vector<Histogram>(2 * num_contexts_);
	  for (i in 0...2 * num_contexts_)
	  combined_histo[i] = new Histogram(HistogramTypeInt);
      var combined_entropy=new Vector<Float>(2 * num_contexts_);
      var diff:Array<Float> = [ 0.0, 0.0 ];
      for (i in 0...num_contexts_) {
        var curr_histo_ix:Int = curr_histogram_ix_ + i;
        entropy[i] = BitsEntropy(histograms_[curr_histo_ix].data_,0,
                                 alphabet_size_);
        for (j in 0...2) {
          var jx:Int = j * num_contexts_ + i;
          var last_histogram_ix:Int = last_histogram_ix_[j] + i;
		  //TODO:
          combined_histo[jx].bit_cost_ = histograms_[curr_histo_ix].bit_cost_;
		  for(a in 0...histograms_[curr_histo_ix].data_.length)
          combined_histo[jx].data_[a] = histograms_[curr_histo_ix].data_[a];
          combined_histo[jx].kDataSize = histograms_[curr_histo_ix].kDataSize;
          combined_histo[jx].total_count_ = histograms_[curr_histo_ix].total_count_;
		  
          combined_histo[jx].AddHistogram(histograms_[last_histogram_ix]);
          combined_entropy[jx] = BitsEntropy(
              combined_histo[jx].data_,0, alphabet_size_);
          diff[j] += combined_entropy[jx] - entropy[i] - last_entropy_[jx];
        }
      }

      if (split_.num_types < max_block_types_ &&
          diff[0] > split_threshold_ &&
          diff[1] > split_threshold_) {
        // Create new block.
        split_.lengths[num_blocks_] = block_size_;
        split_.types[num_blocks_] = split_.num_types;
        last_histogram_ix_[1] = last_histogram_ix_[0];
        last_histogram_ix_[0] = split_.num_types * num_contexts_;
        for (i in 0...num_contexts_) {
          last_entropy_[num_contexts_ + i] = last_entropy_[i];
          last_entropy_[i] = entropy[i];
        }
        ++num_blocks_;
        ++split_.num_types;
        curr_histogram_ix_ += num_contexts_;
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
        for (i in 0...num_contexts_) {//TODO:
          /*histograms_[last_histogram_ix_[0] + i] =
              combined_histo[num_contexts_ + i];*/

		  //TODO:
          histograms_[last_histogram_ix_[0] + i].bit_cost_ = combined_histo[num_contexts_ + i].bit_cost_;
		  for(a in 0...combined_histo[num_contexts_ + i].data_.length)
          histograms_[last_histogram_ix_[0] + i].data_[a] = combined_histo[num_contexts_ + i].data_[a];
          histograms_[last_histogram_ix_[0] + i].kDataSize = combined_histo[num_contexts_ + i].kDataSize;
          histograms_[last_histogram_ix_[0] + i].total_count_ = combined_histo[num_contexts_ + i].total_count_;
		  
          last_entropy_[num_contexts_ + i] = last_entropy_[i];
          last_entropy_[i] = combined_entropy[num_contexts_ + i];
          histograms_[curr_histogram_ix_ + i].Clear();
        }
        ++num_blocks_;
        block_size_ = 0;
        merge_last_count_ = 0;
        target_block_size_ = min_block_size_;
      } else {
        // Combine this block with last block.
        split_.lengths[num_blocks_ - 1] += block_size_;
        for (i in 0...num_contexts_) {
          //histograms_[last_histogram_ix_[0] + i] = combined_histo[i];
		  
		  //TODO:
          histograms_[last_histogram_ix_[0] + i].bit_cost_ = combined_histo[i].bit_cost_;
		  for(a in 0...combined_histo[i].data_.length)
          histograms_[last_histogram_ix_[0] + i].data_[a] = combined_histo[i].data_[a];
          histograms_[last_histogram_ix_[0] + i].kDataSize = combined_histo[i].kDataSize;
          histograms_[last_histogram_ix_[0] + i].total_count_ = combined_histo[i].total_count_;
		  
          last_entropy_[i] = combined_entropy[i];
          if (split_.num_types == 1) {
            last_entropy_[num_contexts_ + i] = last_entropy_[i];
          }
          histograms_[curr_histogram_ix_ + i].Clear();
        }
        block_size_ = 0;
        if (++merge_last_count_ > 1) {
          target_block_size_ += min_block_size_;
        }
      }
    }
    if (is_final) {//TODO:
		while (histograms_.length > split_.num_types * num_contexts_) histograms_.pop();
		while (split_.types.length > num_blocks_) split_.types.pop();
		while (split_.lengths.length > num_blocks_) split_.lengths.pop();
      /*histograms_.resize(split_->num_types * num_contexts_);
      split_->types.resize(num_blocks_);
      split_->lengths.resize(num_blocks_);*/
    }
  }

  static var kMaxBlockTypes:Int = 256;

  var HistogramTypeInt:Int;
  // Alphabet size of particular block category.
  var alphabet_size_:Int;
  var num_contexts_:Int;
  var max_block_types_:Int;
  // We collect at least this many symbols for each block.
  var min_block_size_:Int;
  // We merge histograms A and B if
  //   entropy(A+B) < entropy(A) + entropy(B) + split_threshold_,
  // where A is the current histogram and B is the histogram of the last or the
  // second last block type.
  var split_threshold_:Float;

  var num_blocks_:Int;
  var split_:BlockSplit;  // not owned
  var histograms_:Array<Histogram>;  // not owned

  // The number of symbols that we want to collect before deciding on whether
  // or not to merge the block with a previous one or emit a new block.
  var target_block_size_:Int;
  // The number of symbols in the current histogram.
  var block_size_:Int;
  // Offset of the current histogram.
  var curr_histogram_ix_:Int;
  // Offset of the histograms of the previous two block types.
  var last_histogram_ix_=new Vector<Int>(2);
  // Entropy of the previous two block types.
  var last_entropy_:Vector<Float>;
  // The number of times we merged the current block with the last one.
  var merge_last_count_:Int;
}