open Format
open Support
open Syntax

type store  
val emptystore      : store 
val eval            : context -> store -> term -> term * store 
val process_command : context -> store -> command -> context * store 
val process_commands: context -> store -> command list -> context * store 
