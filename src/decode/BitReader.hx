package decode;
import DefaultFunctions;
import decode.bit_reader.BrotliBitReader;
import decode.streams.BrotliInput;
import decode.Port.*;
import DefaultFunctions.*;
import decode.Streams.*;

/**
 * ...
 * @author ...
 */
class BitReader
{
//h
public static inline var BROTLI_MAX_NUM_BIT_READ =  25;
public static inline var BROTLI_READ_SIZE        =     4096;
public static inline var BROTLI_IBUF_SIZE        =  (2 * BROTLI_READ_SIZE + 128);
//45
public static inline var BROTLI_IBUF_MASK        =     (2 * BROTLI_READ_SIZE - 1);

public static var kBitMask:Array<UInt> = [//[BROTLI_MAX_NUM_BIT_READ]
  0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383, 32767,
  65535, 131071, 262143, 524287, 1048575, 2097151, 4194303, 8388607, 16777215
];
public static function BitMask(n:Int):UInt { return kBitMask[n]; }

/*
 * Reload up to 32 bits byte-by-byte.
 * This function works on both little and big endian.
 */
public static function ShiftBytes32(br:BrotliBitReader) {
  while (br.bit_pos_ >= 8) {
    br.val_ >>>= 8;
    br.val_ |= (br.buf_[br.pos_ & BROTLI_IBUF_MASK])*Std.int(Math.pow(2, 24));
    ++br.pos_;
    br.bit_pos_ -= 8;
    br.bit_end_pos_ -= 8;
  }
}

/* Fills up the input ringbuffer by calling the input callback.

   Does nothing if there are at least 32 bytes present after current position.

   Returns 0 if one of:
    - the input callback returned an error, or
    - there is no more input and the position is past the end of the stream.
    - finish is false and less than BROTLI_READ_SIZE are available - a next call
      when more data is available makes it continue including the partially read
      data

   After encountering the end of the input stream, 32 additional zero bytes are
   copied to the ringbuffer, therefore it is safe to call this function after
   every 32 bytes of input is read.
*/
public static function BrotliReadMoreInput(br:BrotliBitReader):Bool {
  if (PREDICT_TRUE(br.bit_end_pos_ > 256)) {
    return true;
  } else if (PREDICT_FALSE(br.eos_>0)) {
    return br.bit_pos_ <= br.bit_end_pos_;
  } else {
    var dst = br.buf_ptr_;//uint8_t*
    var dst_off = br.buf_ptr_off;//
    var bytes_read:Int = BrotliRead(br.input_, dst,dst_off + br.tmp_bytes_read_,
        (BROTLI_READ_SIZE - br.tmp_bytes_read_));
    if (bytes_read < 0) {
      return false;
    }
    bytes_read += br.tmp_bytes_read_;
    br.tmp_bytes_read_ = 0;
    if (bytes_read < BROTLI_READ_SIZE) {
      if (!(br.finish_>0)) {
        br.tmp_bytes_read_ = bytes_read;
        return false;
      }
      br.eos_ = 1;
      /* Store 32 bytes of zero after the stream end. */
      memset(dst,dst_off + bytes_read, 0, 32);
    }
    if (dst_off == br.buf_off) {
      /* Copy the head of the ringbuffer to the slack region. */
      memcpy(br.buf_,br.buf_off + (BROTLI_READ_SIZE << 1), br.buf_, br.buf_off, 32);
      br.buf_ptr_ = br.buf_;
	  br.buf_ptr_off = br.buf_off + BROTLI_READ_SIZE;
    } else {
      br.buf_ptr_ = br.buf_;
      br.buf_ptr_off = br.buf_off;
    }
    br.bit_end_pos_ += (bytes_read << 3);
    return true;
  }
}

/* Similar to BrotliReadMoreInput, but guarantees num bytes available. The
   maximum value for num is 128 bytes, the slack region size. */
public static function BrotliReadInputAmount(
    br:BrotliBitReader, num:Int):Bool {
  if (PREDICT_TRUE(br.bit_end_pos_ > (num << 3))) {
    return true;
  } else if (PREDICT_FALSE(br.eos_>0)) {
    return br.bit_pos_ <= br.bit_end_pos_;
  } else {
    var dst = br.buf_ptr_;//uint8_t*
    var dst_off = br.buf_ptr_off;//uint8_t*
    var bytes_read:Int = BrotliRead(br.input_, dst,dst_off + br.tmp_bytes_read_,
        (BROTLI_READ_SIZE - br.tmp_bytes_read_));
    if (bytes_read < 0) {
      return false;
    }
    bytes_read += br.tmp_bytes_read_;
    br.tmp_bytes_read_ = 0;
    if (bytes_read < BROTLI_READ_SIZE) {
      if (!(br.finish_>0)) {
        br.tmp_bytes_read_ = bytes_read;
        return false;
      }
      br.eos_ = 1;
      /* Store num bytes of zero after the stream end. */
      memset(dst,dst_off + bytes_read, 0, num);
    }
    if (dst_off == br.buf_off) {
      /* Copy the head of the ringbuffer to the slack region. */
      memcpy(br.buf_,br.buf_off + (BROTLI_READ_SIZE << 1), br.buf_, br.buf_off, num);
      br.buf_ptr_ = br.buf_;
	  br.buf_ptr_off = br.buf_off+ BROTLI_READ_SIZE;
    } else {
      br.buf_ptr_ = br.buf_;
      br.buf_ptr_off = br.buf_off;
    }
    br.bit_end_pos_ += (bytes_read << 3);
    return true;
  }
}

/* Guarantees that there are at least 24 bits in the buffer. */
public static function BrotliFillBitWindow(br:BrotliBitReader) {
  ShiftBytes32(br);
}

public static function BrotliInitBitReader(br:BrotliBitReader,
                          input:BrotliInput, finish:Int) {
  BROTLI_DCHECK(br != null);

  br.finish_ = finish;
  br.tmp_bytes_read_ = 0;

  br.buf_ptr_ = br.buf_;
  br.buf_ptr_off = br.buf_off;
  br.input_ = input;
  br.val_ = 0;
  br.pos_ = 0;
  br.bit_pos_ = 0;
  br.bit_end_pos_ = 0;
  br.eos_ = 0;
}
public static function BrotliWarmupBitReader(br:BrotliBitReader):Bool {
  var i:Int;//size_t

  if (!BrotliReadMoreInput(br)) {
    return false;
  }
  for (i in 0...4) {//sizeof(br->val_)
    br.val_ |= (br.buf_[br.pos_]) << (8 * i);
    ++br.pos_;
  }
  return (br.bit_end_pos_ > 0);
}
//238
/* Reads the specified number of bits from Read Buffer. */
public static function BrotliReadBits(
    br:BrotliBitReader, n_bits:Int):UInt {
  var val:UInt;
  /*
   * The if statement gives 2-4% speed boost on Canterbury data set with
   * asm.js/firefox/x86-64.
   */
  if ((32 - br.bit_pos_) < (n_bits)) {
    BrotliFillBitWindow(br);
  }
  val = (br.val_ >> br.bit_pos_) & BitMask(n_bits);

  br.bit_pos_ += n_bits;
  return val;
}

	public function new() 
	{
		
	}
	
}