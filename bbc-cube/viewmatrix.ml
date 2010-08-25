(* Pre-calculate a fixed-point transformation matrix.  *)

let screen =
  [| 0.25; 0.0; 0.0; 0.0;
     0.0;  0.4; 0.0; 0.0;
     0.0;  0.0; 1.0; 0.0;
     0.0;  0.0; 0.0; 1.0 |]

let camera ~x ~y ~z =
  [| 1.0; 0.0; 0.0; x;
     0.0; 1.0; 0.0; y;
     0.0; 0.0; 1.0; z;
     0.0; 0.0; 0.0; 1.0 |]

let perspective ~n ~f ~l ~r ~t ~b =
  [| 2.0 *. n /. (r -. l); 0.0; (r +. l) /. (r -. l); 0.0;
     0.0; 2.0 *. n /. (t -. b); (t +. b) /. (t -. b);  0.0;
     0.0;  0.0; -.(f +. n) /. (f -. n); -2.0 *. f *. n /. (f -. n);
     0.0; 0.0; -1.0; 0.0 |]

(*                                         i->
   [ a0 a1 a2 a3 ] [ b0 b1 b2 b3 ]     j [ r0 r1 ...
   [ a4 a5 a6 a7 ] [ b4 b5 b6 b7 ]  => | [ r4 ...
   [ a8 a9 aa ab ] [ b8 b9 ba bb ]     v [
   [ ac ad ae af ] [ bc bd be bf ]       [
*)

let mat_mul a b =
  let res = Array.create 16 0.0 in
  for i = 0 to 3 do
    for j = 0 to 3 do
      res.(j * 4 + i) <- 0.0;
      for k = 0 to 3 do
        res.(j * 4 + i) <- res.(j * 4 + i) +. a.(j * 4 + k) *. b.(i + k * 4)
      done
    done
  done;
  res

let map_value x =
  if true then
    256.0 *. x
  else
    Logdiv.float_log x

let _ =
  let s = screen
  and c = camera ~x:0.0 ~y:0.0 ~z:(-80.0)
  and p = perspective ~n:60.0 ~f:200.0 ~l:(-5.0) ~r:5.0 ~t:4.0 ~b:(-4.0) in
  let r' = mat_mul s p in
  let r = mat_mul r' c in
  (* Print the matrix, transposed.  *)
  for i = 0 to 3 do
    print_string "\t.word ";
    for j = 0 to 3 do
      let entry = map_value r.(i + j * 4) in
      print_string (string_of_int (int_of_float entry));
      if j != 3 then
        print_string ", "
    done;
    print_newline ()
  done
  
