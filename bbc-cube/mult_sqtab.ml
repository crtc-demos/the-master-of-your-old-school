(* Fast multiply using square table-lookup.
   Prototype version.  *)

let squares =
  let arr = Array.create 256 0 in
  for i=0 to 255 do
    arr.(i) <- i * i
  done;
  arr

let write_tab fname arr =
  let outbuf = String.make 768 '\000' in
  for i = 0 to 255 do
    outbuf.[i] <- Char.chr (arr.(i) land 255);
    outbuf.[i + 256] <- Char.chr ((arr.(i) lsr 8) land 255);
    outbuf.[i + 512] <- Char.chr ((arr.(i) lsr 16) land 255)
  done;
  let ofile = open_out_bin fname in
  output_string ofile outbuf;
  close_out ofile

let mult_part a b =
  let partial = squares.(a) + squares.(b) - squares.(abs (a - b)) in
  partial / 2

let mult a b =
  let alo = a land 255
  and blo = b land 255
  and ahi = (a lsr 8) land 255
  and bhi = (b lsr 8) land 255 in
  let lo_lo = mult_part alo blo
  and lo_hi = (mult_part alo bhi) lsl 8
  and hi_lo = (mult_part ahi blo) lsl 8
  and hi_hi = (mult_part ahi bhi) lsl 16 in
  lo_lo + lo_hi + hi_lo + hi_hi

let partial_2 a b =
  squares.(a) + squares.(b) - squares.(abs (a - b))

let mult_16_8 a b =
  let alo = a land 255
  and ahi = (a lsr 8) land 255 in
  let lo_lo = partial_2 alo b
  and hi_lo = (partial_2 ahi b) lsl 8 in
  (lo_lo + hi_lo) / 2

let _ =
  write_tab "sqtab" squares;
  for a = 0 to 255 do
    for b = 0 to 65535 do
      let myres = mult_16_8 b a
      and realres = a * b in
      if myres != realres then
	Printf.printf "%d * %d = %d (%d)\n" a b myres realres
    done
  done
