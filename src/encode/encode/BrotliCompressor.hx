package encode.encode;
import encode.hash.Hashers;
import encode.Literal_cost;
import haxe.ds.Vector;
import DefaultFunctions;
import encode.Encode.*;
import DefaultFunctions.*;
import encode.Literal_cost.*;
import encode.Backward_references.*;
import encode.Bit_cost.*;
import encode.Brotli_bit_stream.*;
import encode.metablock.MetaBlockSplit;
import encode.Context.*;
import encode.Metablock.*;
import encode.command.Command;

/**
 * ...
 * @author 
 */
class BrotliCompressor
{
public function GetBrotliStorage(size:Int):Vector<UInt> {
  if (storage_size_ < size) {
    storage_=FunctionMalloc.mallocUInt(size);
    storage_size_ = size;
  }
  return storage_;//[0];
}

  // The maximum input size that can be processed at once.
	public function input_block_size():Int { return 1 << params_.lgblock; }	
	var params_:BrotliParams;
	var max_backward_distance_:Int;
	var hashers_:Hashers;//unique_ptr
	var hash_type_:Int;
	var input_pos_:Int;
	var ringbuffer_:RingBuffer;//unique_ptr
  var literal_cost_:Vector<Float>;//unique_ptr
  var literal_cost_mask_:Int;
  var cmd_buffer_size_:Int;
  var commands_:Array<Command>;//unique_ptr
	var num_commands_:Int;
  var num_literals_:Int;
  var last_insert_len_:Int;
  var last_flush_pos_:Int;
  var last_processed_pos_:Int;
  var dist_cache_:Vector<Int>=new Vector<Int>(4);
  var saved_dist_cache_=new Vector<Int>(4);
  var last_byte_:UInt;
  var last_byte_bits_:UInt;
  var prev_byte_:UInt;
  var prev_byte2_:UInt;
  var storage_size_:Int;
  var storage_:Vector<UInt>;//unique_ptr
  
	public function new(params:BrotliParams) 
	{
      this.params_ = params;
      this.hashers_=new Hashers();
      this.input_pos_=0;
      this.num_commands_=0;
      this.num_literals_=0;
      this.last_insert_len_=0;
      this.last_flush_pos_=0;
      this.last_processed_pos_=0;
      this.prev_byte_=0;
      this.prev_byte2_=0;
      this.storage_size_ = 0;	
  // Sanitize params.
  params_.quality = Std.int(Math.max(1, params_.quality));
  if (params_.lgwin < kMinWindowBits) {
    params_.lgwin = kMinWindowBits;
  } else if (params_.lgwin > kMaxWindowBits) {
    params_.lgwin = kMaxWindowBits;
  }
  if (params_.lgblock == 0) {
    params_.lgblock = params_.quality < kMinQualityForBlockSplit ? 14 : 16;
    if (params_.quality >= 9 && params_.lgwin > params_.lgblock) {
      params_.lgblock = Std.int(Math.min(21, params_.lgwin));
    }
  } else {
    params_.lgblock = Std.int(Math.min(kMaxInputBlockBits,
                               Math.max(kMinInputBlockBits, params_.lgblock)));
  }

  // Set maximum distance, see section 9.1. of the spec.
  max_backward_distance_ = (1 << params_.lgwin) - 16;

  // Initialize input and literal cost ring buffers.
  // We allocate at least lgwin + 1 bits for the ring buffer so that the newly
  // added block fits there completely and we still get lgwin bits and at least
  // read_block_size_bits + 1 bits because the copy tail length needs to be
  // smaller than ringbuffer size.
  var ringbuffer_bits:Int = Std.int(Math.max(params_.lgwin + 1, params_.lgblock + 1));
  ringbuffer_=new RingBuffer(ringbuffer_bits, params_.lgblock);
  if (params_.quality > 9) {
    literal_cost_mask_ = (1 << params_.lgblock) - 1;
    literal_cost_ = FunctionMalloc.mallocFloat(literal_cost_mask_ + 1);//TODO:resize
  }

  // Allocate command buffer.
  cmd_buffer_size_ = Std.int(Math.max(1 << 18, 1 << params_.lgblock));
  commands_ = new Array();// (Command, cmd_buffer_size_);

  // Initialize last byte with stream header.
  if (params_.lgwin == 16) {
    last_byte_ = 0;
    last_byte_bits_ = 1;
  } else if (params_.lgwin == 17) {
    last_byte_ = 1;
    last_byte_bits_ = 7;
  } else {
    last_byte_ = ((params_.lgwin - 17) << 1) | 1;
    last_byte_bits_ = 4;
  }

  // Initialize distance cache.
  dist_cache_[0] = 4;
  dist_cache_[1] = 11;
  dist_cache_[2] = 15;
  dist_cache_[3] = 16;
  // Save the state of the distance cache in case we need to restore it for
  // emitting an uncompressed block.
  memcpy(saved_dist_cache_,0, dist_cache_,0, dist_cache_.length);

  // Initialize hashers.
  hash_type_ = Std.int(Math.min(9, params_.quality));
  hashers_.Init(hash_type_);
	}
//212
	public function CopyInputToRingBuffer(input_size:Int,
                                          input_buffer:Vector<UInt>) {
  ringbuffer_.Write(input_buffer, input_size);
  input_pos_ += input_size;

  // Erase a few more bytes in the ring buffer to make hashing not
  // depend on uninitialized data. This makes compression deterministic
  // and it prevents uninitialized memory warnings in Valgrind. Even
  // without erasing, the output would be valid (but nondeterministic).
  //
  // Background information: The compressor stores short (at most 8 bytes)
  // substrings of the input already read in a hash table, and detects
  // repetitions by looking up such substrings in the hash table. If it
  // can find a substring, it checks whether the substring is really there
  // in the ring buffer (or it's just a hash collision). Should the hash
  // table become corrupt, this check makes sure that the output is
  // still valid, albeit the compression ratio would be bad.
  //
  // The compressor populates the hash table from the ring buffer as it's
  // reading new bytes from the input. However, at the last few indexes of
  // the ring buffer, there are not enough bytes to build full-length
  // substrings from. Since the hash table always contains full-length
  // substrings, we erase with dummy 0s here to make sure that those
  // substrings will contain 0s at the end instead of uninitialized
  // data.
  //
  // Please note that erasing is not necessary (because the
  // memory region is already initialized since he ring buffer
  // has a `tail' that holds a copy of the beginning,) so we
  // skip erasing if we have already gone around at least once in
  // the ring buffer.
  var pos:Int = ringbuffer_.position();
  // Only clear during the first round of ringbuffer writes. On
  // subsequent rounds data in the ringbuffer would be affected.
  if (pos <= ringbuffer_.mask()) {
    // This is the first time when the ring buffer is being written.
    // We clear 3 bytes just after the bytes that have been copied from
    // the input buffer.
    //
    // The ringbuffer has a "tail" that holds a copy of the beginning,
    // but only once the ring buffer has been fully written once, i.e.,
    // pos <= mask. For the first time, we need to write values
    // in this tail (where index may be larger than mask), so that
    // we have exactly defined behavior and don't read un-initialized
    // memory. Due to performance reasons, hashing reads data using a
    // LOAD32, which can go 3 bytes beyond the bytes written in the
    // ringbuffer.
    memset(ringbuffer_.start(), 0+ pos, 0, 3);
  }
}

public function BrotliSetCustomDictionary(
    size:Int, dict:Vector<UInt>) {
  CopyInputToRingBuffer(size, dict);
  last_flush_pos_ = size;
  last_processed_pos_ = size;
  if (size > 0) prev_byte_ = dict[size - 1];
  if (size > 1) prev_byte2_ = dict[size - 2];

  hashers_.PrependCustomDictionary(hash_type_, size, dict);
}	
public function WriteBrotliData(is_last:Bool,
                                       force_flush:Bool,
                                       out_size:Array<Int>,
                                       output:Array<Vector<UInt>>):Bool {
  var bytes:Int = input_pos_ - last_processed_pos_;
  var data:Vector<UInt> = ringbuffer_.start();
  var mask:Int = ringbuffer_.mask();

  if (bytes > input_block_size()) {
    return false;
  }

  var utf8_mode:Bool =
      params_.quality >= 9 &&
      IsMostlyUTF8(data,last_processed_pos_ & mask, bytes, kMinUTF8Ratio);

  if (literal_cost_!=null) {
    if (utf8_mode) {
      EstimateBitCostsForLiteralsUTF8(last_processed_pos_, bytes, mask,
                                      literal_cost_mask_, data,
                                      literal_cost_);
    } else {
      EstimateBitCostsForLiterals(last_processed_pos_, bytes, mask,
                                  literal_cost_mask_,
                                  data, literal_cost_);
    }
  }

  var last_insert_len = [last_insert_len_];
  var num_commands = [num_commands_];
  var num_literals = [num_literals_];
  
  CreateBackwardReferences(bytes, last_processed_pos_, data, mask,
                           literal_cost_,
                           literal_cost_mask_,
                           max_backward_distance_,
                           params_.quality,
                           hashers_,
                           hash_type_,
                           dist_cache_,
                           last_insert_len,
                           commands_,
						   num_commands[0],
                           num_commands,
                           num_literals);
  last_insert_len_ = last_insert_len[0];
  num_commands_ = num_commands[0];
  num_literals_ = num_literals[0];

  // For quality 1 there is no block splitting, so we buffer at most this much
  // literals and commands.
  var kMaxNumDelayedSymbols:Int = 0x2fff;
  var max_length:Int = Std.int(Math.min(mask + 1, 1 << kMaxInputBlockBits));
  if (!is_last && !force_flush &&
      (params_.quality >= kMinQualityForBlockSplit ||
       (num_literals_ + num_commands_ < kMaxNumDelayedSymbols)) &&
      num_commands_ + (input_block_size() >> 1) < cmd_buffer_size_ &&
      input_pos_ + input_block_size() <= last_flush_pos_ + max_length) {
    // Everything will happen later.
    last_processed_pos_ = input_pos_;
    out_size[0] = 0;
    return true;
  }

  // Create the last insert-only command.
  if (last_insert_len_ > 0) {
	  var command = new Command();
	  command.Command1(last_insert_len_);
    var cmd = command;
    commands_[num_commands_++] = cmd;
    num_literals_ += last_insert_len_;
    last_insert_len_ = 0;
  }

  //var str='num_commands[0]:'+num_commands_+' num_literals[0]:'+num_literals_;
  var ret = WriteMetaBlockInternal(is_last, utf8_mode, out_size, output);
  //trace(str+' out_size[0]:'+out_size[0]);
  return ret;
}

public function WriteMetaBlockInternal(is_last:Bool,
                                       utf8_mode:Bool,
                                       out_size:Array<Int>,
                                       output:Array<Vector<UInt>>):Bool {
  var bytes:Int = input_pos_ - last_flush_pos_;
  var data:Vector<UInt> = ringbuffer_.start();
  var mask:Int = ringbuffer_.mask();
  var max_out_size:Int = 2 * bytes + 500;
  var storage:Vector<UInt> = GetBrotliStorage(max_out_size);
  storage[0] = last_byte_;
  var storage_ix:Array<Int> = [last_byte_bits_];

  var uncompressed:Bool = false;
  if (num_commands_ < (bytes >> 8) + 2) {
    if (num_literals_ > 0.99 * bytes) {
      var literal_histo = FunctionMalloc.mallocInt(256);
      var kSampleRate:Int = 13;
      var kMinEntropy:Float = 7.92;
      var kBitCostThreshold:Float = bytes * kMinEntropy / kSampleRate;
	  var i = last_flush_pos_;
      while (i < input_pos_) {
        literal_histo[data[i & mask]]+=1;
		i += kSampleRate;
      }
      if (BitsEntropy(literal_histo,0, 256) > kBitCostThreshold) {
        uncompressed = true;
      }
    }
  }

  if (bytes == 0) {
    if (!StoreCompressedMetaBlockHeader(is_last, 0, storage_ix, storage)) {//,0
      return false;
    }
    storage_ix[0] = (storage_ix[0] + 7) & ~7;
  } else if (uncompressed) {
    // Restore the distance cache, as its last update by
    // CreateBackwardReferences is now unused.
    memcpy(dist_cache_,0, saved_dist_cache_,0, dist_cache_.length);//sizeof()
    if (!StoreUncompressedMetaBlock(is_last,
                                    data, last_flush_pos_, mask, bytes,
                                    storage_ix,
                                    storage,0)) {
      return false;
    }
  } else {
    var num_direct_distance_codes:Int = 0;
    var distance_postfix_bits:Int = 0;
    if (params_.quality > 9 && params_.mode == MODE_FONT) {
      num_direct_distance_codes = 12;
      distance_postfix_bits = 1;
      RecomputeDistancePrefixes(commands_,
                                num_commands_,
                                num_direct_distance_codes,
                                distance_postfix_bits);
    }
    if (params_.quality < kMinQualityForBlockSplit) {
      if (!StoreMetaBlockTrivial(data, last_flush_pos_, bytes, mask, is_last,
                                 commands_, num_commands_,
                                 storage_ix,
                                 storage,0)) {
        return false;
      }
    } else {
      var mb=new MetaBlockSplit();
      var literal_context_mode:Array<Int> = [utf8_mode ? CONTEXT_UTF8 : CONTEXT_SIGNED];
      if (params_.quality <= 9) {
        var num_literal_contexts:Array<Int> = [1];
        var literal_context_map:Array<Array<Int>> = [[-1]];
        DecideOverLiteralContextModeling(data, last_flush_pos_, bytes, mask,
                                         params_.quality,
                                         literal_context_mode,
                                         num_literal_contexts,
                                         literal_context_map);
        if (literal_context_map[0][0] == -1) {
          BuildMetaBlockGreedy(data, last_flush_pos_, mask,
                               commands_, num_commands_,
                               mb);
        } else {
          BuildMetaBlockGreedyWithContexts(data, last_flush_pos_, mask,
                                           prev_byte_, prev_byte2_,
                                           literal_context_mode[0],
                                           num_literal_contexts[0],
                                           literal_context_map[0],
                                           commands_, num_commands_,
                                           mb);
        }
      } else {
        BuildMetaBlock(data, last_flush_pos_, mask,
                       prev_byte_, prev_byte2_,
                       commands_, num_commands_,
                       literal_context_mode[0],
                       mb);
      }
      if (params_.quality >= kMinQualityForOptimizeHistograms) {
        OptimizeHistograms(num_direct_distance_codes,
                           distance_postfix_bits,
                           mb);
      }
      if (!StoreMetaBlock(data, last_flush_pos_, bytes, mask,
                          prev_byte_, prev_byte2_,
                          is_last,
                          num_direct_distance_codes,
                          distance_postfix_bits,
                          literal_context_mode[0],
                          commands_, num_commands_,
                          mb,
                          storage_ix,
                          storage)) {//,0
        return false;
      }
    }
    if (bytes + 4 < (storage_ix[0] >> 3)) {
      // Restore the distance cache and last byte.
      memcpy(dist_cache_,0, saved_dist_cache_,0, dist_cache_.length);//sizeof()
      storage[0] = last_byte_;
      storage_ix[0] = last_byte_bits_;
      if (!StoreUncompressedMetaBlock(is_last, data, last_flush_pos_, mask,
                                      bytes, storage_ix, storage,0)) {
        return false;
      }
    }
  }
  last_byte_ = storage[storage_ix[0] >> 3];
  last_byte_bits_ = storage_ix[0] & 7;
  last_flush_pos_ = input_pos_;
  last_processed_pos_ = input_pos_;
  prev_byte_ = data[(last_flush_pos_ - 1) & mask];
  prev_byte2_ = data[(last_flush_pos_ - 2) & mask];
  num_commands_ = 0;
  num_literals_ = 0;
  // Save the state of the distance cache in case we need to restore it for
  // emitting an uncompressed block.
  memcpy(saved_dist_cache_,0, dist_cache_,0, dist_cache_.length);//sizeof()
  output[0] = storage;//[0];
  out_size[0] = storage_ix[0] >> 3;
  return true;
}

}