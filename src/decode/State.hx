package decode;
import decode.state.BrotliState;

/**
 * ...
 * @author 
 */
class State
{
	static public function BrotliStateInit(s:BrotliState) {
		var i:Int;

		s.state = BROTLI_STATE_UNINITED;
		s.sub_state[0] = BROTLI_STATE_SUB_NONE;
		s.sub_state[1] = BROTLI_STATE_SUB_NONE;

		s.block_type_trees = null;
		s.block_len_trees = null;
		s.ringbuffer = null;

		s.context_map = null;
		s.context_modes = null;
		s.dist_context_map = null;
		s.context_map_slice = null;
		s.context_map_slice_off = 0;
		s.dist_context_map_slice = null;
		s.dist_context_map_slice_off = 0;

		for (i in 0...3) {
			s.hgroup[i].codes = null;
			s.hgroup[i].htrees = null;
		}

		s.code_lengths = null;
		s.context_map_table = null;

		s.custom_dict = null;
		s.custom_dict_size = 0;
	}

	public function new() 
	{
		
	}
	
}