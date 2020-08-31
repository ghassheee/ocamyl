open Format

let pi  = print_int
let pr  = print_string
let ps  = print_space
let pe  = print_endline
let pn  = print_newline
let pb  = print_break 
let cut = print_cut
let pf  = print_flush 






exception Exit of int

type info               =   FI of string * int * int | UNKNOWN
type 'a withinfo        =   {i: info; v: 'a}

let dummy               =   UNKNOWN
let createInfo f l c    =   FI(f, l, c)
let errf f              =   pf(); open_vbox 0; open_hvbox 0; f(); cut(); 
                            close_box(); pn();raise (Exit 1)
let printInfo           =   function
    | FI(f,l,c)             ->  pr f; pr ":"; pi l; pr "."; pi c; pr ":"
    | UNKNOWN               ->  pr "<Unknown file and line>: "
let errfAt fi f         =   errf ( fun() -> printInfo fi; ps (); f())
let err s               =   errf ( fun() -> pr "Error: "; pr s; pn());;
let error fi s          =   errfAt fi (fun()-> pr s; pn())
let warning s           =   pr "Warning: "; pr s; pn()
let warningAt fi s      =   printInfo fi; pr " Warning: "; pr s; pn()




