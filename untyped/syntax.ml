open Format
open Support


(* -------------------------------------------------- *) 
(* Datatypes *)

type ty     =
    | TyArr of ty * ty
    | TyBool
;;

type term =
    (* Lambda *) 
    | TmVar of info * int * int 
    | TmAbs of info * string * term 
    | TmApp of info * term * term 
    (* Arith *) 
    | TmTrue    of info
    | TmFalse   of info
    | TmIf      of info * term * term * term
    | TmZero    of info
    | TmSucc    of info * term
    | TmPred    of info * term
    | TmIsZero  of info * term
;;

type binding = 
    | NameBind
    | VarBind of ty
;;

type context = 
    (string * binding) list 
;;

type command =
    | Eval of info * term
    | Bind of info * string * binding 
;;


(* -------------------------------------------------- *) 
(* Context Management *) 

let emptycontext                = []
let ctxlength       ctx         = List.length ctx
let addbinding      ctx x bind  = (x,bind) :: ctx 
let addname         ctx x       = addbinding ctx x NameBind 
let rec isnamebound ctx x       = match ctx with 
    | []                            -> false
    | (y,_) :: rest                 -> if y=x then true else isnamebound rest x;;
let rec pickfreshname ctx x     = if isnamebound ctx x 
                                    then pickfreshname ctx (x^"'")
                                    else ((x,NameBind)::ctx), x;;
let index2name fi ctx x         = 
    try let (xn,_)                  = List.nth ctx x in xn 
    with Failure _                  -> error fi "variable lookup failure";;
let rec name2index fi ctx x     = match ctx with 
    | []                            -> error fi ("Identifier " ^ x ^ " is unbound")
    | (y,_) :: rest                 -> if y=x then 0 else 1 + (name2index fi rest x) ;;

(* -------------------------------------------------- *) 
(* Shifting *)

let rec walk funOnVar c   = let f = funOnVar in function 
    | TmVar(fi,x,n)             -> funOnVar fi c x n
    | TmAbs(fi,x,t2)            -> TmAbs(fi,x,walk f(c+1)t2)
    | TmApp(fi,t1,t2)           -> TmApp(fi, walk f c t1, walk f c t2) 
    | TmIf(fi,t1,t2,t3)         -> TmIf(fi,walk f c t1, walk f c t2, walk f c t3) 
    | TmSucc(fi,t)              -> TmSucc(fi, walk f c t) 
    | TmPred(fi,t)              -> TmPred(fi, walk f c t) 
    | TmIsZero(fi,t)            -> TmIsZero(fi, walk f c t)
    | x                         -> x

let termShiftOnVar d        = fun fi c x n ->   if x>=c then TmVar(fi,x+d,n+d) else TmVar(fi,x,n+d)
let termShiftAbove d        = walk (termShiftOnVar d)
let termShift d             = termShiftAbove d 0 

(* -------------------------------------------------- *) 
(* Substitution *) 
let termSubstOnVar j s t    = fun fi c x n ->   if x=j+c then termShift c s else TmVar(fi, x, n) 
let termSubst j s t         = walk (termSubstOnVar j s t) 0 t
let termSubstTop s t        = termShift (-1) (termSubst 0 (termShift 1 s) t) 

(* -------------------------------------------------- *) 
(* Extracting file info *)
let tmInfo  = function 
    | TmVar(fi,_,_)         -> fi
    | TmAbs(fi,_,_)         -> fi
    | TmApp(fi,_,_)         -> fi 
    | TmTrue(fi)            -> fi
    | TmFalse(fi)           -> fi
    | TmIf(fi,_,_,_)        -> fi
    | TmZero(fi)            -> fi
    | TmSucc(fi,_)          -> fi
    | TmPred(fi,_)          -> fi
    | TmIsZero(fi,_)        -> fi 

(* -------------------------------------------------- *) 
(* Printing *)
let obox0() = open_hvbox 0
let obox()  = open_hvbox 2
let cbox()  = close_box()
let break() = print_break 0 0

let small   = function
    | TmVar(_,_,_)              -> true
    | _                         -> false 

let rec printtm_Term outer ctx  = function 
    | TmAbs(fi,x,t2)            ->  let (ctx',x') = pickfreshname ctx x in obox();
        pr "λ"; pr x'; pr "."; 
        if (small t2) && not outer then break() else ps();
        printtm_Term outer ctx' t2;
        cbox()
    | TmIf(fi, t1, t2, t3)      ->  obox0();
        pr "if "  ; printtm_Term false ctx t1; ps();
        pr "then "; printtm_Term false ctx t2; ps();
        pr "else "; printtm_Term false ctx t3;
        cbox()
    | t                         -> printtm_AppTerm outer ctx t
and printtm_AppTerm outer ctx   = function 
    | TmApp(fi, t1, t2)         ->  obox0(); printtm_AppTerm false ctx t1; ps(); 
                                    printtm_ATerm false ctx t2; cbox();
    | TmPred(_,t1)              ->  pr "pred ";     printtm_ATerm false ctx t1
    | TmIsZero(_,t1)            ->  pr "iszero ";   printtm_ATerm false ctx t1
    | t                         ->  printtm_ATerm outer ctx t

and printtm_ATerm outer ctx     = function 
    | TmVar(fi,x,n)             -> if ctxlength ctx = n 
        then pr (index2name fi ctx x)
        else pr ("[bad index: " ^ (string_of_int x) ^ "/" ^ (string_of_int n) ^ " in {" 
                ^ (List.fold_left (fun s(x,_)-> s^" "^x) "" ctx) ^ " }]") 
    | TmTrue(_)                 ->  pr "true"
    | TmFalse(_)                ->  pr "false"
    | TmZero(fi)                ->  pr "0"
    | TmSucc(_,t1)              ->  let rec f n = function 
        | TmZero(_)                 -> pr (string_of_int n)
        | TmSucc(_,s)               -> f (n+1) s
    in f 1 t1
    | t                         ->  pr "("; printtm_Term outer ctx t; pr ")"

let printtm t = printtm_Term true t 


