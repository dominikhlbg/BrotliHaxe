package decode.state;
import FunctionMalloc;
import haxe.ds.Vector;
import decode.huffman.HuffmanTreeGroup;
import decode.huffman.HuffmanCode;
import decode.bit_reader.BrotliBitReader;
import FunctionMalloc.malloc;

/**
 * ...
 * @author 
 */
@:enum
abstract BrotliRunningState(Int) {
	var BROTLI_STATE_UNINITED = 0;
	var BROTLI_STATE_BITREADER_WARMUP = 1;
	var BROTLI_STATE_METABLOCK_BEGIN = 10;
	var BROTLI_STATE_METABLOCK_HEADER_1 = 11;
	var BROTLI_STATE_METABLOCK_HEADER_2 = 12;
	var BROTLI_STATE_BLOCK_BEGIN = 13;
	var BROTLI_STATE_BLOCK_INNER = 14;
	var BROTLI_STATE_BLOCK_DISTANCE = 15;
	var BROTLI_STATE_BLOCK_POST = 16;
	var BROTLI_STATE_UNCOMPRESSED = 17;
	var BROTLI_STATE_METADATA = 18;
	var BROTLI_STATE_BLOCK_INNER_WRITE = 19;
	var BROTLI_STATE_METABLOCK_DONE = 20;
	var BROTLI_STATE_BLOCK_POST_WRITE_1 = 21;
	var BROTLI_STATE_BLOCK_POST_WRITE_2 = 22;
	var BROTLI_STATE_BLOCK_POST_CONTINUE = 23;
	var BROTLI_STATE_HUFFMAN_CODE_0 = 30;
	var BROTLI_STATE_HUFFMAN_CODE_1 = 31;
	var BROTLI_STATE_HUFFMAN_CODE_2 = 32;
	var BROTLI_STATE_CONTEXT_MAP_1 = 33;
	var BROTLI_STATE_CONTEXT_MAP_2 = 34;
	var BROTLI_STATE_TREE_GROUP = 35;
	var BROTLI_STATE_SUB_NONE = 50;
	var BROTLI_STATE_SUB_UNCOMPRESSED_SHORT = 51;
	var BROTLI_STATE_SUB_UNCOMPRESSED_FILL = 52;
	var BROTLI_STATE_SUB_UNCOMPRESSED_COPY = 53;
	var BROTLI_STATE_SUB_UNCOMPRESSED_WARMUP = 54;
	var BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_1 = 55;
	var BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_2 = 56;
	var BROTLI_STATE_SUB_UNCOMPRESSED_WRITE_3 = 57;
	var BROTLI_STATE_SUB_HUFFMAN_LENGTH_BEGIN = 60;
	var BROTLI_STATE_SUB_HUFFMAN_LENGTH_SYMBOLS = 61;
	var BROTLI_STATE_SUB_HUFFMAN_DONE = 62;
	var BROTLI_STATE_SUB_TREE_GROUP = 70;
	var BROTLI_STATE_SUB_CONTEXT_MAP_HUFFMAN = 80;
	var BROTLI_STATE_SUB_CONTEXT_MAPS = 81;
	var BROTLI_STATE_DONE = 100;
}

class BrotliState
{
	public var state:BrotliRunningState;
	public var sub_state:Vector<BrotliRunningState>=new Vector<BrotliRunningState>(2);  /* State inside function call */

	public var pos:Int;
	public var input_end:Int;
	public var window_bits:Int;
	public var max_backward_distance:Int;
	public var max_distance:Int;
	public var ringbuffer_size:Int;
	public var ringbuffer_mask:Int;
	public var ringbuffer:Vector<UInt>;//uint8_t*
	public var ringbuffer_off:Int;//
	public var ringbuffer_end:Vector<UInt>;//uint8_t*
	public var ringbuffer_end_off:Int;//
	/* This ring buffer holds a few past copy distances that will be used by */
	/* some special distance codes. */
	public var dist_rb:Vector<Int>=new Vector<Int>(4);
	public var dist_rb_idx:Int;
	/* The previous 2 bytes used for context. */
	public var prev_byte1:UInt;//uint8_t
	public var prev_byte2:UInt;//uint8_t
	public var hgroup:Vector<HuffmanTreeGroup>=malloc(HuffmanTreeGroup,3);
	public var block_type_trees:Vector<HuffmanCode>;//*
	public var block_len_trees:Vector<HuffmanCode>;//*
	public var br:BrotliBitReader=new BrotliBitReader();
	/* This counter is reused for several disjoint loops. */
	public var loop_counter:Int;
	/* This is true if the literal context map histogram type always matches the
	block type. It is then not needed to keep the context (faster decoding). */
	public var trivial_literal_context:Int;

	public var meta_block_remaining_len:Int;
	public var is_metadata:Int;
	public var is_uncompressed:Int;
	public var block_length:Vector<Int>=new Vector<Int>(3);
	public var block_type:Vector<Int>=new Vector<Int>(3);
	public var num_block_types:Vector<Int>=new Vector<Int>(3);
	public var block_type_rb:Vector<Int>=new Vector<Int>(6);
	public var block_type_rb_index:Vector<Int>=new Vector<Int>(3);
	public var distance_postfix_bits:Int;
	public var num_direct_distance_codes:Int;
	public var distance_postfix_mask:Int;
	public var num_distance_codes:Int;
	public var context_map:Vector<UInt>;//uint8_t*
	public var context_map_off:Int;//
	public var context_modes:Vector<UInt>;//uint8_t*
	public var context_modes_off:Int;//
	public var num_literal_htrees:Int;
	public var dist_context_map:Vector<UInt>;//uint8_t*
	public var dist_context_map_off:Int;//
	public var num_dist_htrees:Int;
	public var context_offset:Int;
	public var context_map_slice:Vector<UInt>;//uint8_t*
	public var context_map_slice_off:Int;//
	public var literal_htree_index:UInt;//uint8_t
	public var dist_context_offset:Int;
	public var dist_context_map_slice:Vector<UInt>;//uint8_t*
	public var dist_context_map_slice_off:Int;//
	public var dist_htree_index:UInt;//uint8_t
	public var context_lookup_offset1:Int;
	public var context_lookup_offset2:Int;
	public var context_mode:UInt;//uint8_t
	public var htree_command:Vector<HuffmanCode>;//*
	public var htree_command_off:Int;//*

	public var cmd_code:Int;
	public var range_idx:Int;
	public var insert_code:Int;
	public var copy_code:Int;
	public var insert_length:Int;
	public var copy_length:Int;
	public var distance_code:Int;
	public var distance:Int;
	public var copy_src:Vector<UInt>;//const uint8_t*
	public var copy_src_off:Int;//
	public var copy_dst:Vector<UInt>;//uint8_t*
	public var copy_dst_off:Int;//

	/* For CopyUncompressedBlockToOutput */
	public var nbytes:Int;

	/* For partial write operations */
	public var partially_written:Int;

	/* For HuffmanTreeGroupDecode */
	public var htrees_decoded:Int;

	/* For ReadHuffmanCodeLengths */
	public var symbol:Int;
	public var prev_code_len:UInt;//uint8_t
	public var repeat:Int;
	public var repeat_code_len:UInt;//uint8_t
	public var space:Int;
	public var table:Vector<HuffmanCode>=new Vector<HuffmanCode>(32);
	public var code_length_code_lengths:Vector<UInt>=new Vector<UInt>(18);//uint8_t

	/* For ReadHuffmanCode */
	public var simple_code_or_skip:Int;
	public var code_lengths:Vector<UInt>;//uint8_t*
	public var code_lengths_off:Int;//

	/* For HuffmanTreeGroupDecode */
	public var htree_index:Int;
	public var next:Vector<HuffmanCode>;//*
	public var next_off:Int;//

	/* For DecodeContextMap */
	public var context_index:Int;
	public var max_run_length_prefix:Int;
	public var context_map_table:Vector<HuffmanCode>;//*

	/* For custom dictionaries */
	public var custom_dict:Vector<UInt>;//const uint8_t*
	public var custom_dict_off:Int;//
	public var custom_dict_size:Int;
	public function new() 
	{
		
	}
	
}