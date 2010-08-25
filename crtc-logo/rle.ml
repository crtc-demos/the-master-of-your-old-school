let rle buf maxlength =
  let rec count idx byteval num =
    if idx < maxlength then begin
      if buf.[idx] = byteval && num < 256 then
	count (idx + 1) byteval (num + 1)
      else
	(num, byteval) :: count (idx + 1) buf.[idx] 1
    end else
      [num, byteval] in
  count 1 buf.[0] 1

let encode_output rle =
  let oplength = List.length rle * 2 in
  let outstring = String.create oplength in
  let arr = Array.of_list rle in
  for i = 0 to Array.length arr - 1 do
    let length, byte = arr.(i) in
    let length = if length = 256 then 0 else length in
    outstring.[i * 2] <- Char.chr length;
    outstring.[i * 2 + 1] <- byte
  done;
  outstring

let chop_tail rle =
  let chopped, _ = List.fold_right
    (fun (num, byteval) (acc, saw_nonzero) ->
      if byteval = '\000' && not saw_nonzero then
        acc, saw_nonzero
      else
        (num, byteval) :: acc, true)
    rle
    ([], false) in
  chopped

let _ =
  let filename = Sys.argv.(1) in
  let outfile = Sys.argv.(2) in
  let stats = Unix.stat filename in
  let length = stats.Unix.st_size in
  let fh = open_in filename in
  let buf = String.create length in
  really_input fh buf 0 length;
  close_in fh;
  let encoded = encode_output (rle buf length) in
  let ofh = open_out outfile in
  output ofh encoded 0 (String.length encoded);
  close_out ofh
