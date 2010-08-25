let plane_y = -60.0
and zoffset = 1000.0

let count_sections cols =
  let rec scan_same as_col num = function
    [] -> num, []
  | (s :: ss) as m ->
      if s = as_col then
        scan_same as_col (succ num) ss
      else num, m in
  let rec build_series truth = function
    [] -> []
  | my_cols ->
      let num, rest = scan_same truth 0 my_cols in
      num :: build_series (not truth) rest in
  build_series (List.hd cols) cols

let _ =
  let phaselens = ref [] in
  for phase = 0 to 31 do
    let phase_offset = (float_of_int phase) *. (256.0 /. 32.0) in
    let colours = ref [] in
    for y = 128 to 255 do
      let j = 128.0 -. (float_of_int y) in
      let wz =
	try
          ((256.0 *. plane_y) /. j) -. zoffset
	with Division_by_zero -> 100000.0 (* infinity!!! *) in
      let modulo = (int_of_float (wz *. 2.0 +. phase_offset)) land 255 in
      colours := (modulo < 128) :: !colours
    done;
    let lines = List.rev (count_sections !colours) in
    phaselens := (List.length lines) :: !phaselens;
    Printf.printf "phase_%d\n" phase;
    List.iter (fun n -> Printf.printf "\t.word 64 * %d\n" n) lines;
    print_newline ()
  done;
  Printf.printf "phase_lens\n";
  List.iter
    (fun num_lines -> Printf.printf "\t.byte %d\n" (num_lines * 2))
    (List.rev !phaselens);
  Printf.printf "\nphase_index\n";
  for phase = 0 to 31 do
    Printf.printf "\t.word phase_%d\n" phase
  done

