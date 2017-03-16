package encode;
import haxe.ds.Vector;
import DefaultFunctions.*;
import encode.Port.*;

/**
 * ...
 * @author 
 */
class RingBuffer
{
  function WriteTail(bytes:Vector<UInt>, n:Int) {
    var masked_pos:Int = pos_ & mask_;
    if (PREDICT_FALSE(masked_pos < tail_size_)) {
      // Just fill the tail buffer with the beginning data.
      var p:Int = (1 << window_bits_) + masked_pos;
      memcpy(buffer_,p, bytes,0, Std.int(Math.min(n, tail_size_ - masked_pos)));
    }
  }
  // Size of the ringbuffer is (1 << window_bits) + tail_size_.
	var window_bits_:Int;
	var mask_:Int;
  var tail_size_:Int;

  // Position to write in the ring buffer.
  var pos_:Int;
  // The actual ring buffer containing the data and the copy of the beginning
  // as a tail.
	var buffer_:Vector<UInt>;//*
	var buffer_off:Int;
	public function new(window_bits:Int, tail_bits:Int) 
	{
		this.window_bits_ = window_bits;
        this.mask_=(1 << window_bits) - 1;
        this.tail_size_=1 << tail_bits;
        this.pos_=0;
    var kSlackForFourByteHashingEverywhere:Int = 3;
    var buflen:Int = (1 << window_bits_) + tail_size_;
    buffer_ = new Vector(buflen + kSlackForFourByteHashingEverywhere);
    for (i in 0...kSlackForFourByteHashingEverywhere) {
      buffer_[buflen + i] = 0;
    }
	}
  // Push bytes into the ring buffer.
public function Write(bytes:Vector<UInt>, n:Int) {
    var masked_pos:Int = pos_ & mask_;
    // The length of the writes is limited so that we do not need to worry
    // about a write
    WriteTail(bytes, n);
    if (PREDICT_TRUE(masked_pos + n <= (1 << window_bits_))) {
      // A single write fits.
      memcpy(buffer_,masked_pos, bytes,0, n);
    } else {
      // Split into two writes.
      // Copy into the end of the buffer, including the tail buffer.
      memcpy(buffer_,masked_pos, bytes,0,
             Std.int(Math.min(n, ((1 << window_bits_) + tail_size_) - masked_pos)));
      // Copy into the begining of the buffer
      memcpy(buffer_,0, bytes,0 + ((1 << window_bits_) - masked_pos),
             n - ((1 << window_bits_) - masked_pos));
    }
    pos_ += n;
  }
  // Logical cursor position in the ring buffer.
  public function position():Int { return this.pos_; }
  // Bit mask for getting the physical position for a logical position.
  public function mask():Int { return this.mask_; }
  public function start() { return this.buffer_; }
	
}