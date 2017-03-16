package encode;
import DefaultFunctions;
import haxe.ds.Vector;
import encode.Fast_log.*;
import haxe.Int64;

/**
 * ...
 * @author 
 */
class Command_functions
{
public static function GetDistCode(distance_code:Int,// inline
                               code:Array<UInt>, extra:Array<UInt>) {
  if (distance_code < 16) {
    code[0] = distance_code;
    extra[0] = 0;
  } else {
    distance_code -= 12;
    var numextra:Int = Log2FloorNonZero(distance_code) - 1;
    var prefix:Int = distance_code >> numextra;
    code[0] = 12 + 2 * numextra + prefix;
    extra[0] = (numextra << 24) | (distance_code - (prefix << numextra));
  }
}

public static var insbase:Array<Int> =   [ 0, 1, 2, 3, 4, 5, 6, 8, 10, 14, 18, 26, 34, 50, 66,
    98, 130, 194, 322, 578, 1090, 2114, 6210, 22594 ];
	public static var insextra:Array<Int> =  [ 0, 0, 0, 0, 0, 0, 1, 1,  2,  2,  3,  3,  4,  4,  5,
    5,   6,   7,   8,   9,   10,   12,   14,    24 ];
public static var copybase:Array<Int> =  [ 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 14, 18, 22, 30, 38,
    54,  70, 102, 134, 198, 326,   582, 1094,  2118 ];
public static var copyextra:Array<Int> = [ 0, 0, 0, 0, 0, 0, 0, 0,  1,  1,  2,  2,  3,  3,  4,
    4,   5,   5,   6,   7,   8,     9,   10,    24 ];
//48
public static function GetInsertLengthCode(insertlen:Int):Int {// inline
  if (insertlen < 6) {
    return insertlen;
  } else if (insertlen < 130) {
    insertlen -= 2;
    var nbits:Int = Log2FloorNonZero(insertlen) - 1;
    return (nbits << 1) + (insertlen >> nbits) + 2;
  } else if (insertlen < 2114) {
    return Log2FloorNonZero(insertlen - 66) + 10;
  } else if (insertlen < 6210) {
    return 21;
  } else if (insertlen < 22594) {
    return 22;
  } else {
    return 23;
  }
}

//66
public static function GetCopyLengthCode(copylen:Int):Int {// inline
  if (copylen < 10) {
    return copylen - 2;
  } else if (copylen < 134) {
    copylen -= 6;
    var nbits:Int = Log2FloorNonZero(copylen) - 1;
    return (nbits << 1) + (copylen >> nbits) + 4;
  } else if (copylen < 2118) {
    return Log2FloorNonZero(copylen - 70) + 12;
  } else {
    return 23;
  }
}

//80
public static function CombineLengthCodes(// inline
    inscode:Int, copycode:Int, distancecode:Int):Int {
  var bits64:Int = (copycode & 0x7) | ((inscode & 0x7) << 3);
  if (distancecode == 0 && inscode < 8 && copycode < 16) {
    return (copycode < 8) ? bits64 : (bits64 | 64);
  } else {
    // "To convert an insert-and-copy length code to an insert length code and
    // a copy length code, the following table can be used"
    var cells = [ 2, 3, 6, 4, 5, 8, 7, 9, 10 ];
    return (cells[(copycode >> 3) + 3 * (inscode >> 3)] << 6) | bits64;
  }
}

//93
public static function GetLengthCode(insertlen:Int, copylen:Int, distancecode:Int,// inline
                                 code:Array<UInt>, extra:Array<UInt>) {
  var inscode:Int = GetInsertLengthCode(insertlen);
  var copycode:Int = GetCopyLengthCode(copylen);
  var insnumextra:UInt = insextra[inscode];
  var numextra:UInt = insnumextra + copyextra[copycode];
  var insextraval:UInt = insertlen - insbase[inscode];
  var copyextraval:UInt = copylen - copybase[copycode];
  code[0] = CombineLengthCodes(inscode, copycode, distancecode);
  if(numextra<32) {
  extra[0] = (numextra << 16) | 0;
  extra[1] = (copyextraval << insnumextra) | insextraval;
  } else {
	  var value:Int64 = 0;
	  value+=Int64.shl(numextra, 48);
	  value+=Int64.shl(copyextraval, insnumextra);
	  value+=insextraval;
  extra[0] = Int64.toInt(value.high);
  extra[1] = Int64.toInt(value.low);
  }
  
}

	public function new() 
	{
	}
	
}