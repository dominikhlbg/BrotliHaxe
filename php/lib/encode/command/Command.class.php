<?php

// Generated by Haxe 3.4.0
class encode_command_Command {
	public function __construct() {
		if(!php_Boot::$skip_constructor) {
		$this->dist_extra_ = new _hx_array(array());
		$this->cmd_extra_ = new _hx_array(array());
		$this->dist_prefix_ = new _hx_array(array());
		$this->cmd_prefix_ = new _hx_array(array());
	}}
	public $insert_len_;
	public $copy_len_;
	public $cmd_prefix_;
	public $dist_prefix_;
	public $cmd_extra_;
	public $dist_extra_;
	public function Command0() {}
	public function Command4($insertlen, $copylen, $copylen_code, $distance_code) {
		$this->insert_len_ = $insertlen;
		$this->copy_len_ = $copylen;
		encode_Command_functions::GetDistCode($distance_code, $this->dist_prefix_, $this->dist_extra_);
		encode_Command_functions::GetLengthCode($insertlen, $copylen_code, $this->dist_prefix_[0], $this->cmd_prefix_, $this->cmd_extra_);
	}
	public function Command1($insertlen) {
		$this->insert_len_ = $insertlen;
		$this->copy_len_ = 0;
		$this->dist_prefix_[0] = 16;
		$this->dist_extra_[0] = 0;
		encode_Command_functions::GetLengthCode($insertlen, 4, $this->dist_prefix_[0], $this->cmd_prefix_, $this->cmd_extra_);
	}
	public function DistanceCode() {
		$a = $this->dist_prefix_[0];
		$tmp = null;
		if(false !== $a < 0) {
			$tmp = false;
		} else {
			$tmp = 16 > $a;
		}
		if($tmp) {
			return $this->dist_prefix_[0];
		}
		$nbits = _hx_shift_right($this->dist_extra_[0], 24);
		return ($this->dist_prefix_[0] - 12 - 2 * $nbits << $nbits) + ($this->dist_extra_[0] & 16777215) + 12;
	}
	public function DistanceContext() {
		$c = $this->cmd_prefix_[0] & 7;
		$r = _hx_shift_right($this->cmd_prefix_[0], 6);
		$tmp = null;
		$tmp1 = null;
		$tmp2 = null;
		$tmp3 = null;
		if($r !== 0) {
			$tmp3 = $r === 2;
		} else {
			$tmp3 = true;
		}
		if(!$tmp3) {
			$tmp2 = $r === 4;
		} else {
			$tmp2 = true;
		}
		if(!$tmp2) {
			$tmp1 = $r === 7;
		} else {
			$tmp1 = true;
		}
		if($tmp1) {
			$tmp = $c <= 2;
		} else {
			$tmp = false;
		}
		if($tmp) {
			return $c;
		}
		return 3;
	}
	public function __call($m, $a) {
		if(isset($this->$m) && is_callable($this->$m))
			return call_user_func_array($this->$m, $a);
		else if(isset($this->__dynamics[$m]) && is_callable($this->__dynamics[$m]))
			return call_user_func_array($this->__dynamics[$m], $a);
		else if('toString' == $m)
			return $this->__toString();
		else
			throw new HException('Unable to call <'.$m.'>');
	}
	function __toString() { return 'encode.command.Command'; }
}
