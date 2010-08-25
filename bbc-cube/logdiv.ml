let tab_size = 1024
let big_value = float_of_int (tab_size - 1)
let bias = tab_size
let log_factor = big_value /. (log big_value)

let logtab =
  let arr = Array.create tab_size 0 in
  for i = 1 to tab_size - 1 do
    let i' = float_of_int i in
    arr.(i) <- int_of_float (((log i') *. log_factor) +. 0.5)
  done;
  arr.(0) <- 0;
  arr

let scale_factor = 32.0

let exptab =
  let arr = Array.create (tab_size * 2) 0 in
  for i = 0 to (tab_size * 2) - 1 do
    let i' = float_of_int (i - bias) in
    arr.(i) <- int_of_float (((scale_factor *. exp (i' /. log_factor))) +. 0.5)
  done;
  arr

(* These do the same calculations as my_exp, my_log but with floating-point
   arguments, for greater accuracy for pre-calculated values.  *)

let float_log x =
  let x' = abs_float x in
  let res = (log x') *. log_factor in
  if x < 0.0 then -.res else res

let float_exp x =
  scale_factor *. exp ((x -. (float_of_int bias)) /. log_factor)

let put_byte buf idx num =
  buf.[idx] <- Char.chr num

let output_datafile fname tab_size bytes_per_sample map =
  let buf = String.make (tab_size * bytes_per_sample) '\000' in
  for i = 0 to (tab_size - 1) do
    map buf i
  done;
  let outf = open_out_bin fname in
  output_string outf buf;
  close_out outf

let output_logtab () =
  output_datafile "logtab" tab_size 2
    (fun buf i ->
      let v = logtab.(i) * 2 in
      put_byte buf (i * 2) (v mod 256);
      put_byte buf (i * 2 + 1) (v / 256))

let output_exptab () =
  let exp_tabsize = tab_size * 2 in
  output_datafile "exptab" exp_tabsize 2
    (fun buf i ->
      let v = exptab.(i) in
      put_byte buf (i * 2) (v mod 256);
      put_byte buf (i * 2 + 1) ((v / 256) mod 256))

let my_log x = logtab.(x)
let my_exp x = if x < 0 then 0 else exptab.(x)

let sgn x = compare x 0.0

let my_mult a b =
  let mult_bias = 148 in
  let a', invert = if a < 0 then (-a, true) else (a, false) in
  let b', invert' = if b < 0 then (-b, not invert) else (b, invert) in
  let res = my_exp (my_log a' + my_log b' + mult_bias) in
  if invert' then float_of_int (-res)
  else float_of_int res

let my_div a b =
  let true_result = (float_of_int a) /. (float_of_int b)
  and biased_loga_logb = my_log a - my_log b + bias in
  ((float_of_int (my_exp biased_loga_logb)) /. 256.0, true_result)

(* Multiply-accumulate, with a & b in log-space and acc in linear space.  *)

let my_mac acc a b =
  let a' = abs a
  and b' = abs b in
  let magnitude = a' + b' in
  let exp_mag = my_exp magnitude in
  acc + exp_mag

let pi = 4.0 *. (atan 1.0)

let log_sintab =
  let logsin_scaley = (float_of_int tab_size) /. log 2.0 in
  let sintab = Array.create 128 0 in
  for i = 0 to 127 do
    let angle = pi *. (float_of_int i) /. 128.0 in
    let entry = (log (sin angle +. 1.0)) *. logsin_scaley in
    let entry' = int_of_float (entry +. 0.5) in
    sintab.(i) <- entry'
  done;
  sintab

(* calculate "n * sin t" using only table lookup, 16-bit integer arithmetic. *)

let my_n_sin n angle =
  let log_sin = log_sintab.(angle land 127)
  and abs_n, inv = if n < 0 then (-n, true) else (n, false) in
  let inv' = if (angle land 128) = 128 then not inv else inv in
  let res = my_exp ((my_log abs_n) + log_sin) in
  let bias = (n + 16) asr 5 in
  let res_minus_bias = res - bias in
  if inv' then -res_minus_bias else res_minus_bias

let my_n_cos n angle = my_n_sin n (angle + 64)

let log_sin n = log ((sin n) +. 2.0)

let my_sin n = exp (log_sin n) -. 2.0

(* Perfectly ordinary sin table.  *)

let sintab =
  let sintab = Array.create 64 0 in
  for i = 0 to 63 do
    let angle = pi *. (float_of_int i) /. 128.0 in
    let entry = 256.0 *. sin angle in
    let entry' = int_of_float (entry +. 0.5) in
    sintab.(i) <- entry'
  done;
  sintab

let output_sintab () =
  output_datafile "sintab" 64 2
    (fun buf i ->
      let v = sintab.(i) in
      put_byte buf i (v mod 256);
      put_byte buf (i + 64) (v / 256))

let my_sin angle =
  let half = angle land 127
  and over_pi = (angle land 128) == 128 in
  let s =
    if half < 64 then sintab.(half)
    else if half = 64 then 256
    else sintab.(128 - half) in
  if over_pi then (-s) else s

let _ =
  output_logtab ();
  output_exptab ();
  output_sintab ();
  prerr_endline "Written tables to disk"
