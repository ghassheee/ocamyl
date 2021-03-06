open Format
open Arg 

open Support.Pervasive
open Support.Error
open Syntax
open Print
open Type
open Eval
open Interpreter  


(* ######################
 * ####   COMPILER   ####
 * ###################### *)


let main ()         =   
    parseArgs (); 
    let _,_ = process_file (getFile ()) emptyctx emptystore in ()

let ()              =   set_max_boxes 1000
let ()              =   set_margin 80
let res             =   Printexc.catch (fun()->   
    try                     main(); 0 
    with    | Exit 10   -> flush stdout; main () ; 10 
            | Exit x    -> x ) ()

let ()              = print_flush()
let ()              = exit res 
