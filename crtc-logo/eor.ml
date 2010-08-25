
let exclusive_or buf1 buf2 =
  let oplength = String.length buf1 in
  let outstring = String.create oplength in
  for i = 0 to oplength - 1 do
    outstring.[i] <- Char.chr ((Char.code buf1.[i]) lxor (Char.code buf2.[i]))
  done;
  outstring

let load_into_string filename length =
  let fh = open_in filename in
  let buf = String.create length in
  really_input fh buf 0 length;
  close_in fh;
  buf

let _ =
  let filename1 = Sys.argv.(1)
  and filename2 = Sys.argv.(2) in
  let outfile = Sys.argv.(3) in
  let stats1 = Unix.stat filename1
  and stats2 = Unix.stat filename2 in
  let length1 = stats1.Unix.st_size
  and length2 = stats2.Unix.st_size in
  if length1 != length2 then
    failwith "File lengths not equal";
  let buf1 = load_into_string filename1 length1
  and buf2 = load_into_string filename2 length2 in
  let encoded = exclusive_or buf1 buf2 in
  let ofh = open_out outfile in
  output ofh encoded 0 (String.length encoded);
  close_out ofh
