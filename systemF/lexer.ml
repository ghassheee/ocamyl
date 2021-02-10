# 1 "lexer.mll"
 
open Support
open Parser


let reservedWords = [
  (* Keywords *)
    ("All",     fun i -> ALL i);
    ("Exists",  fun i -> SOME i);
    ("Top",     fun i -> TOP i);
    ("ref",     fun i -> REF i);
    ("Ref",     fun i -> REFTYPE i);
    ("letrec",  fun i -> LETREC i);
    ("fix",     fun i -> FIX i);
    ("Float",   fun i -> FLOAT i);
    ("*.",      fun i -> TIMESFLOAT i);
    ("String",  fun i -> STRING i);
    ("case",    fun i -> CASE i);
    ("of",      fun i -> OF i);
    ("as",      fun i -> AS i);
    ("unit",    fun i -> UNIT i);
    ("Unit",    fun i -> UNITTYPE i);
    ("where",   fun i -> WHERE i);
    ("in",      fun i -> IN i);
    ("let",     fun i -> LET i);
    ("Bool",    fun i -> BOOL i);
    ("Nat",     fun i -> NAT i);
    ("\\",      fun i -> LAM i);
    ("if",      fun i -> IF i);
    ("then",    fun i -> THEN i);
    ("else",    fun i -> ELSE i);
    ("true",    fun i -> TRUE i);
    ("false",   fun i -> FALSE i);
    ("succ",    fun i -> SUCC i);
    ("pred",    fun i -> PRED i);
    ("iszero",  fun i -> ISZERO i);
  
  (* Symbols *)
    ("_",       fun i -> USCORE i);
    ("'",       fun i -> APOSTROPHE i);
    ("\"",      fun i -> DQUOTE i);
    ("!",       fun i -> BANG i);
    ("#",       fun i -> HASH i);
    ("$",       fun i -> TRIANGLE i);
    ("*",       fun i -> STAR i);
    ("|",       fun i -> VBAR i);
    (".",       fun i -> DOT i);
    (";",       fun i -> SEMI i);
    (",",       fun i -> COMMA i);
    ("/",       fun i -> SLASH i);
    (":",       fun i -> COLON i);
    ("::",      fun i -> COLONCOLON i);
    ("=",       fun i -> EQ i);
    ("==",      fun i -> EQEQ i);
    ("[",       fun i -> LSQUARE i); 
    ("<",       fun i -> LT i);
    ("{",       fun i -> LCUR i); 
    ("(",       fun i -> LPAREN i); 
    ("<-",      fun i -> LEFTARROW i); 
    ("{|",      fun i -> LCURBAR i); 
    ("[|",      fun i -> LSQUAREBAR i); 
    ("}",       fun i -> RCUR i);
    (")",       fun i -> RPAREN i);
    ("]",       fun i -> RSQUARE i);
    (">",       fun i -> GT i);
    ("|}",      fun i -> BARRCUR i);
    ("|>",      fun i -> BARGT i);
    ("|]",      fun i -> BARRSQUARE i);
    ("\n",      fun i -> NEWLINE i); 
    (";;",      fun i -> DSEMI i); 

  (* Special compound symbols: *)
    (":=",      fun i -> COLONEQ i);
    ("->",      fun i -> ARROW i);
    ("=>",      fun i -> DARROW i);
    ("==>",     fun i -> DDARROW i);
]

(* Support functions *)
let fos                     =   float_of_string
let ios                     =   int_of_string 

type tokentbl               =   (string, info->token) Hashtbl.t
let  symbolTable:tokentbl   =   Hashtbl.create 1024
let _                       =   List.iter (fun(str,f)->Hashtbl.add symbolTable str f) reservedWords
let initCapital str         =   let s=Bytes.get str 0 in s>='A'&&s<='Z'  

let createID i str          =   (* info -> string -> token *)
  try   Hashtbl.find symbolTable str i
  with _ -> if initCapital str then UCID {i=i;v=str} else LCID {i=i;v=str}

let startLex                =   ref dummy
let lineno                  =   ref 1
and start                   =   ref 0

(* filename *) 
let filename                =   ref ""
let set_filename f          =   (if not (Filename.is_implicit f)
                                    then filename := f 
                                    else filename := Filename.concat (Sys.getcwd()) f );
                                start := 0; lineno := 1
(* comment nest depth *) 
let depth                   =   ref 0

(* line number *) 
let newline lexbuf          =   incr lineno; start := (Lexing.lexeme_start lexbuf)
let info    lexbuf          =   createInfo (!filename) (!lineno) (Lexing.lexeme_start lexbuf - !start)
let text                    =   Lexing.lexeme

(* string lexbuf *) 
let str_buf                 =   ref (Bytes.create 2048)
let str_end                 =   ref 0
let reset_str ()            =   str_end := 0
let add_char c              =
    let x           =   !str_end in
    let buf         =   !str_buf in
    if x=Bytes.length buf
    then (
        let newbuf   = Bytes.create (x*2) in
        Bytes.blit buf 0 newbuf 0 x;
        Bytes.set newbuf x c;
        str_buf     := newbuf;
        str_end     := x+1
    ) else (
        Bytes.set buf x c;
        str_end       := x+1
    )
let get_str ()                   = Bytes.sub (!str_buf) 0 (!str_end)


let extractLineno yytxt offset  = ios(Bytes.sub yytxt offset(Bytes.length yytxt-offset))
let out_of_char x fi            = if x>255 then error fi"Illegal Char" else Char.chr x 

# 136 "lexer.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base = 
   "\000\000\237\255\240\255\242\255\243\255\022\000\068\000\092\000\
    \102\000\007\000\071\000\116\000\091\000\186\000\218\000\095\000\
    \039\001\250\255\001\000\041\000\102\000\157\000\036\000\035\000\
    \044\000\044\000\037\000\255\255\060\000\058\000\254\255\004\000\
    \252\255\245\255\251\255\049\001\059\001\239\255\248\255\100\000\
    \167\000\241\255\005\000\238\255\086\000\254\255\052\000\058\000\
    \055\000\071\000\053\000\059\000\255\255\171\000\251\255\252\255\
    \253\255\254\255\255\255\172\000\251\255\252\255\253\255\136\000\
    \144\000\255\255\254\255\187\000\251\255\252\255\253\255\254\255\
    \255\255\083\001\249\255\093\001\251\255\252\255\253\255\254\255\
    \255\255\103\001\250\255";
  Lexing.lex_backtrk = 
   "\255\255\255\255\255\255\255\255\255\255\012\000\012\000\011\000\
    \011\000\012\000\012\000\011\000\012\000\011\000\009\000\012\000\
    \006\000\255\255\018\000\012\000\012\000\002\000\012\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\008\000\255\255\255\255\010\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\001\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\003\000\
    \003\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\006\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255";
  Lexing.lex_default = 
   "\001\000\000\000\000\000\000\000\000\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\000\000\255\255\255\255\000\000\255\255\
    \000\000\000\000\000\000\255\255\255\255\000\000\000\000\255\255\
    \255\255\000\000\255\255\000\000\045\000\000\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\000\000\054\000\000\000\000\000\
    \000\000\000\000\000\000\061\000\000\000\000\000\000\000\255\255\
    \255\255\000\000\000\000\068\000\000\000\000\000\000\000\000\000\
    \000\000\074\000\000\000\255\255\000\000\000\000\000\000\000\000\
    \000\000\255\255\000\000";
  Lexing.lex_trans = 
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\021\000\017\000\017\000\021\000\018\000\017\000\041\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \021\000\004\000\003\000\022\000\007\000\007\000\007\000\004\000\
    \020\000\004\000\015\000\007\000\004\000\011\000\004\000\005\000\
    \016\000\016\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \016\000\016\000\013\000\006\000\012\000\010\000\004\000\004\000\
    \043\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\019\000\007\000\004\000\004\000\014\000\
    \007\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\009\000\008\000\004\000\007\000\040\000\
    \007\000\007\000\007\000\033\000\039\000\033\000\034\000\007\000\
    \033\000\007\000\007\000\007\000\007\000\038\000\037\000\032\000\
    \023\000\007\000\028\000\007\000\025\000\033\000\007\000\024\000\
    \007\000\007\000\007\000\026\000\027\000\029\000\030\000\007\000\
    \007\000\007\000\033\000\047\000\033\000\033\000\021\000\017\000\
    \048\000\021\000\031\000\049\000\050\000\051\000\007\000\052\000\
    \040\000\041\000\033\000\040\000\042\000\055\000\060\000\066\000\
    \007\000\046\000\065\000\000\000\007\000\021\000\000\000\000\000\
    \000\000\000\000\007\000\033\000\000\000\069\000\007\000\040\000\
    \000\000\000\000\000\000\000\000\000\000\058\000\000\000\000\000\
    \007\000\000\000\000\000\000\000\007\000\000\000\063\000\033\000\
    \007\000\000\000\007\000\064\000\000\000\072\000\007\000\007\000\
    \007\000\000\000\007\000\033\000\007\000\007\000\000\000\007\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \007\000\000\000\007\000\000\000\007\000\000\000\000\000\033\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \002\000\014\000\000\000\000\000\000\000\000\000\000\000\056\000\
    \000\000\000\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\000\000\000\000\007\000\070\000\
    \000\000\000\000\007\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\000\000\007\000\000\000\
    \007\000\014\000\000\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\035\000\255\255\016\000\
    \016\000\016\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \016\000\036\000\036\000\036\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\077\000\000\000\000\000\
    \000\000\000\000\076\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\075\000\075\000\075\000\075\000\075\000\
    \075\000\075\000\075\000\075\000\075\000\081\000\081\000\081\000\
    \081\000\081\000\081\000\081\000\081\000\081\000\081\000\082\000\
    \082\000\082\000\082\000\082\000\082\000\082\000\082\000\082\000\
    \082\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\057\000\062\000\000\000\000\000\078\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\071\000\000\000\000\000\000\000\000\000\
    \000\000\080\000\000\000\000\000\000\000\000\000\000\000\079\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\255\255\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    ";
  Lexing.lex_check = 
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\018\000\000\000\000\000\031\000\042\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \005\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\006\000\
    \007\000\007\000\007\000\009\000\010\000\010\000\019\000\007\000\
    \012\000\007\000\008\000\008\000\008\000\015\000\015\000\020\000\
    \022\000\008\000\023\000\008\000\024\000\012\000\007\000\022\000\
    \011\000\011\000\011\000\025\000\026\000\028\000\029\000\011\000\
    \008\000\011\000\039\000\046\000\008\000\019\000\021\000\021\000\
    \047\000\021\000\021\000\048\000\049\000\050\000\011\000\051\000\
    \040\000\040\000\011\000\040\000\040\000\053\000\059\000\063\000\
    \007\000\044\000\064\000\255\255\007\000\021\000\255\255\255\255\
    \255\255\255\255\008\000\008\000\255\255\067\000\008\000\040\000\
    \255\255\255\255\255\255\255\255\255\255\053\000\255\255\255\255\
    \011\000\255\255\255\255\255\255\011\000\255\255\059\000\012\000\
    \007\000\255\255\007\000\059\000\255\255\067\000\013\000\013\000\
    \013\000\255\255\008\000\008\000\008\000\013\000\255\255\013\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \011\000\255\255\011\000\255\255\013\000\255\255\255\255\013\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\014\000\255\255\255\255\255\255\255\255\255\255\053\000\
    \255\255\255\255\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\255\255\255\255\013\000\067\000\
    \255\255\255\255\013\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\255\255\013\000\255\255\
    \013\000\014\000\255\255\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\014\000\014\000\014\000\
    \014\000\014\000\014\000\014\000\014\000\016\000\044\000\016\000\
    \016\000\016\000\016\000\016\000\016\000\016\000\016\000\016\000\
    \016\000\035\000\035\000\035\000\035\000\035\000\035\000\035\000\
    \035\000\035\000\035\000\036\000\036\000\036\000\036\000\036\000\
    \036\000\036\000\036\000\036\000\036\000\073\000\255\255\255\255\
    \255\255\255\255\073\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\073\000\073\000\073\000\073\000\073\000\
    \073\000\073\000\073\000\073\000\073\000\075\000\075\000\075\000\
    \075\000\075\000\075\000\075\000\075\000\075\000\075\000\081\000\
    \081\000\081\000\081\000\081\000\081\000\081\000\081\000\081\000\
    \081\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\053\000\059\000\255\255\255\255\073\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\067\000\255\255\255\255\255\255\255\255\
    \255\255\073\000\255\255\255\255\255\255\255\255\255\255\073\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\073\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    ";
  Lexing.lex_base_code = 
   "";
  Lexing.lex_backtrk_code = 
   "";
  Lexing.lex_default_code = 
   "";
  Lexing.lex_trans_code = 
   "";
  Lexing.lex_check_code = 
   "";
  Lexing.lex_code = 
   "";
}

let rec token lexbuf =
    __ocaml_lex_token_rec lexbuf 0
and __ocaml_lex_token_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 149 "lexer.mll"
                            ( show lexbuf                                           )
# 353 "lexer.ml"

  | 1 ->
# 150 "lexer.mll"
                            ( load lexbuf                                           )
# 358 "lexer.ml"

  | 2 ->
# 151 "lexer.mll"
                            ( token lexbuf                                          )
# 363 "lexer.ml"

  | 3 ->
# 152 "lexer.mll"
                            ( UNIT(info lexbuf)                              )
# 368 "lexer.ml"

  | 4 ->
# 153 "lexer.mll"
                            ( NIL(info lexbuf)                               )
# 373 "lexer.ml"

  | 5 ->
# 154 "lexer.mll"
                            ( newline lexbuf; token lexbuf                          )
# 378 "lexer.ml"

  | 6 ->
# 155 "lexer.mll"
                            ( INTV{i=info lexbuf;v=ios(text lexbuf)}         )
# 383 "lexer.ml"

  | 7 ->
# 156 "lexer.mll"
                            ( TIMESFLOAT(info lexbuf)                        )
# 388 "lexer.ml"

  | 8 ->
# 157 "lexer.mll"
                            ( FLOATV{i=info lexbuf;v=fos(text lexbuf)}       )
# 393 "lexer.ml"

  | 9 ->
# 158 "lexer.mll"
                            ( createID (info lexbuf) (text lexbuf)                  )
# 398 "lexer.ml"

  | 10 ->
# 160 "lexer.mll"
                            ( createID (info lexbuf) (text lexbuf)                  )
# 403 "lexer.ml"

  | 11 ->
# 161 "lexer.mll"
                            ( createID (info lexbuf) (text lexbuf)                  )
# 408 "lexer.ml"

  | 12 ->
# 162 "lexer.mll"
                            ( createID (info lexbuf) (text lexbuf)                  )
# 413 "lexer.ml"

  | 13 ->
# 163 "lexer.mll"
                            ( reset_str(); startLex:=info lexbuf; string lexbuf      )
# 418 "lexer.ml"

  | 14 ->
# 164 "lexer.mll"
                            ( DSEMI(info lexbuf)                        )
# 423 "lexer.ml"

  | 15 ->
# 165 "lexer.mll"
                            ( EOF(info lexbuf)                               )
# 428 "lexer.ml"

  | 16 ->
# 166 "lexer.mll"
                            ( error (info lexbuf) "Unmatched end of comment"        )
# 433 "lexer.ml"

  | 17 ->
# 167 "lexer.mll"
                            ( depth:=1;startLex:=info lexbuf;comment lexbuf;token lexbuf )
# 438 "lexer.ml"

  | 18 ->
# 168 "lexer.mll"
                            ( error (info lexbuf) "Illegal character"               )
# 443 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_token_rec lexbuf __ocaml_lex_state

and show lexbuf =
    __ocaml_lex_show_rec lexbuf 44
and __ocaml_lex_show_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 171 "lexer.mll"
                            ( SHOWCONTEXT(info lexbuf)                              )
# 455 "lexer.ml"

  | 1 ->
# 172 "lexer.mll"
                            ( show lexbuf                                           )
# 460 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_show_rec lexbuf __ocaml_lex_state

and load lexbuf =
    __ocaml_lex_load_rec lexbuf 53
and __ocaml_lex_load_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 174 "lexer.mll"
                            ( LOAD{i = !startLex; v=get_str()}                      )
# 472 "lexer.ml"

  | 1 ->
# 175 "lexer.mll"
                            ( error(!startLex)"String not terminated"               )
# 477 "lexer.ml"

  | 2 ->
# 176 "lexer.mll"
                            ( add_char(escaped lexbuf)             ; load lexbuf    )
# 482 "lexer.ml"

  | 3 ->
# 177 "lexer.mll"
                            ( add_char('\n') ; newline lexbuf      ; load lexbuf    )
# 487 "lexer.ml"

  | 4 ->
# 178 "lexer.mll"
                            ( add_char(Lexing.lexeme_char lexbuf 0); load lexbuf    )
# 492 "lexer.ml"

  | 5 ->
# 179 "lexer.mll"
                            ( reset_str();startLex:=info lexbuf    ; load lexbuf    )
# 497 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_load_rec lexbuf __ocaml_lex_state

and comment lexbuf =
    __ocaml_lex_comment_rec lexbuf 59
and __ocaml_lex_comment_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 182 "lexer.mll"
                            ( depth:=succ !depth; comment lexbuf                    )
# 509 "lexer.ml"

  | 1 ->
# 183 "lexer.mll"
                            ( depth:=pred !depth; if !depth>0 then comment lexbuf   )
# 514 "lexer.ml"

  | 2 ->
# 184 "lexer.mll"
                            ( error (!startLex) "Comment not terminated"            )
# 519 "lexer.ml"

  | 3 ->
# 185 "lexer.mll"
                            ( comment lexbuf                                        )
# 524 "lexer.ml"

  | 4 ->
# 186 "lexer.mll"
                            ( newline lexbuf; comment lexbuf                        )
# 529 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_comment_rec lexbuf __ocaml_lex_state

and string lexbuf =
    __ocaml_lex_string_rec lexbuf 67
and __ocaml_lex_string_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 189 "lexer.mll"
                            ( STRINGV{i= !startLex; v=get_str()}                    )
# 541 "lexer.ml"

  | 1 ->
# 190 "lexer.mll"
                            ( error(!startLex)"String not terminated"               )
# 546 "lexer.ml"

  | 2 ->
# 191 "lexer.mll"
                            ( add_char(escaped lexbuf)              ; string lexbuf )
# 551 "lexer.ml"

  | 3 ->
# 192 "lexer.mll"
                            ( add_char('\n') ; newline lexbuf       ; string lexbuf )
# 556 "lexer.ml"

  | 4 ->
# 193 "lexer.mll"
                            ( add_char(Lexing.lexeme_char lexbuf 0) ; string lexbuf )
# 561 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_string_rec lexbuf __ocaml_lex_state

and escaped lexbuf =
    __ocaml_lex_escaped_rec lexbuf 73
and __ocaml_lex_escaped_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 195 "lexer.mll"
                          ( '\n'                                                  )
# 573 "lexer.ml"

  | 1 ->
# 196 "lexer.mll"
                          ( '\t'                                                  )
# 578 "lexer.ml"

  | 2 ->
# 197 "lexer.mll"
                           ( '\\'                                                  )
# 583 "lexer.ml"

  | 3 ->
# 198 "lexer.mll"
                            ( '\034'                                                )
# 588 "lexer.ml"

  | 4 ->
# 199 "lexer.mll"
                           ( '\''                                                  )
# 593 "lexer.ml"

  | 5 ->
# 200 "lexer.mll"
                            ( out_of_char (ios(text lexbuf))(info lexbuf)           )
# 598 "lexer.ml"

  | 6 ->
# 201 "lexer.mll"
                            ( error (info lexbuf) "Illegal character constant"      )
# 603 "lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_escaped_rec lexbuf __ocaml_lex_state

;;
