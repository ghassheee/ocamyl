open Support.Pervasive
open Support.Error
open Syntax
open Subtype
open Type

exception NoRuleApplies

(* --------------------- STORE ---------------------- *)
type store                  = term list 
let emptystore              = []
let addstore store v        = (List.length store, List.append store [v]) 
let lookuploc store l       = List.nth store l
let updatestore store n v   = 
    let rec f s = match s with
        | (0,x::xs)                 -> v::xs
        | (n,x::xs)                 -> v::(f(n-1,xs))
        | _                         -> error dummyinfo "updatestore: BadIndex" in 
    f (n,store) 
let shiftstore i            = List.map (tmShift i) 

(* ---------------- EVAL FLOAT ------------------ *) 
let rec evalF1 ctx store = function
    | TmTimesfloat(fi,TmFloat(_,a),TmFloat(_,b)) -> TmFloat(fi,a*.b),store
    | TmTimesfloat(fi,(TmFloat(_,a)as f),t)      -> let t',s'=eval1 ctx store t in TmTimesfloat(fi,f,t'),s' 
    | TmTimesfloat(fi,t1,t2)                     -> let t1',s'=eval1 ctx store t1 in TmTimesfloat(fi,t1',t2),s'   

(* ----------------- EVALUATION ------------------- *) 

and eval1 ctx store t = let p str = pr str;pr_tm ctx t;pn() in match t with  
    | TmRef(fi,v)when isval ctx v       ->  p"E-REFV        : "; let i,s'=addstore store v in TmLoc(fi,i),s'
    | TmRef(fi,t)                       ->  p"E-REF         : "; let t',s'=eval1 ctx store t in TmRef(fi,t'),s'
    | TmDeref(fi,TmLoc(_,l))            ->  p"E-DEREFLOC    : "; (lookuploc store l,store  )
    | TmDeref(fi,t)                     ->  p"E-DEREF       : "; let t',s'=eval1 ctx store t in TmDeref(fi,t'),s'
    | TmAssign(fi,TmLoc(_,i),v)when isval ctx v 
                                        ->  p"E-ASSIGN      : "; let s'=updatestore store i v in TmUnit(fi),s'
    | TmAssign(fi,t,v)when isval ctx v  ->  p"E-ASSIGN1     : "; let t',s'=eval1 ctx store t in TmAssign(fi,t',v),s'
    | TmAssign(fi,t1,t2)                ->  p"E-ASSIGN2     : "; let t2',s'=eval1 ctx store t2 in TmAssign(fi,t1,t2'),s'
    | TmFix(fi,TmAbs(f,x,tyT1,t2))      ->  p"E-FIXBETA     : "; tmSubstTop t t2,store
    | TmFix(fi,t)                       ->  p"E-FIX         : "; let t',s'=eval1 ctx store t in TmFix(fi,t'),s' 
    | TmTag(fi,l,t,tyT)                 ->  p"E-TAG         : "; let t',s'=eval1 ctx store t in TmTag(fi,l,t',tyT),s'
    | TmVar(fi,n,_)                     ->  p"E-VAR         : "; (match getbind fi ctx n with
        | BindTmAbb(t,_)                    -> t,store
        | _                                 -> raise NoRuleApplies) 
    | TmCase(fi,TmTag(_,l,v,_),cases) when isval ctx v  ->  
                                            p"E-CASETAGV    : ";
                                            (try let (x,t)= List.assoc l cases in  tmSubstTop v t,store
                                            with Not_found -> raise NoRuleApplies)
    | TmCase(fi,t,cases)                ->  p"E-CASE        : "; let t',s'=eval1 ctx store t in TmCase(fi,t',cases),s'
    | TmAscribe(fi,v,_)when isval ctx v ->  p"E-ASCRIBEVAR  : "; v,store
    | TmAscribe(fi,t,tyT)               ->  p"E-ASCRIBE     : "; let t',s'=eval1 ctx store t in TmAscribe(fi,t',tyT),s' 
    | TmLet(fi,x,v1,t2)when isval ctx v1->  p"E-LETV        : "; tmSubstTop v1 t2, store
    | TmLet(fi,x,t1,t2)                 ->  p"E-LET         : "; let t1',s'=eval1 ctx store t1 in TmLet(fi,x,t1',t2),s'
    | TmApp(fi,TmAbs(_,x,_,t),v) 
        when isval ctx v                ->  p"E-APPABS      : "; tmSubstTop v t ,store
    | TmApp(fi,v,t)                                          
        when isval ctx v                ->  p"E-APP1        : "; let t',s'=eval1 ctx store t in TmApp(fi,v,t'),s' 
    | TmApp(fi,t1,t2)                   ->  p"E-APP2        : "; let t1',s'=eval1 ctx store t1 in TmApp(fi,t1',t2),s'
    | TmIf(_,TmTrue(_),t2,t3)           ->  p"E-IFTRUE      : "; t2, store
    | TmIf(_,TmFalse(_),t2,t3)          ->  p"E-IFFLASE     : "; t3, store
    | TmIf(fi,t,t2,t3)                  ->  p"E-IF          : "; let t',s'=eval1 ctx store t in TmIf(fi,t',t2,t3),s'
    | TmSucc(fi,t)                      ->  p"E-SUCC        : "; let t',s'=eval1 ctx store t in TmSucc(fi,t'),s'
    | TmPred(_,TmZero(_))               ->  p"E-PREDZRO     : "; TmZero(dummyinfo),store
    | TmPred(_,TmSucc(_,nv1)) 
        when isnum ctx nv1              ->  p"E-PREDSUC     : "; nv1, store
    | TmPred(fi,t)                      ->  p"E-PRED        : "; let t',s'=eval1 ctx store t in TmPred(fi,t'),s'
    | TmIsZero(_,TmZero(_))             ->  p"E-ISZROZRO    : "; TmTrue(dummyinfo),store
    | TmTimesfloat(fi,_,_)              ->  p"E-TIMESFLOAT  : "; evalF1 ctx store t 
    | TmIsZero(_,TmSucc(_,nv1)) 
        when isnum ctx nv1              ->  p"E-ISZROSUC    : "; TmFalse(dummyinfo),store
    | TmIsZero(fi,t)                    ->  p"E-ISZRO       : "; let t',s'=eval1 ctx store t in TmIsZero(fi,t'),s'
    | TmRecord(fi,flds)                 ->  p"E-RCD         : "; 
        let rec ev_flds ctx store = function
            | []                                -> raise NoRuleApplies 
            | (l,v)::rest when isval ctx v      -> let flds',s'=ev_flds ctx store rest in ((l,v)::flds'),s'
            | (l,t)::rest                       -> let t',s'=eval1 ctx store t in ev_flds ctx s'((l,t')::rest) 
        in let flds',s'=ev_flds ctx store flds in TmRecord(fi,flds'),s'        
    | TmProj(fi,(TmRecord(f,flds)as v),l)                                           
        when isval ctx v                ->  p"E-PROJRCD     : "; 
                                            (try List.assoc l flds,store with Not_found -> raise NoRuleApplies)
    | TmProj(fi,t,l)                    ->  p"E-PROJ        : "; let t',s'=eval1 ctx store t in TmProj(fi,t',l),s'
    | _                                 ->  raise NoRuleApplies

let rec eval ctx store t =
    try let t',store' = eval1 ctx store t in eval ctx store' t' 
    with NoRuleApplies -> t,store


(*------------ Binding ------------*)

let evalbind ctx store      = function
    | BindTmAbb(t,tyT)          ->  let t',store' = eval ctx store t in BindTmAbb(t',tyT),store' 
    | bind                      ->  bind,store

let checkbind fi ctx        = function 
    | BindTmAbb(t,None)         ->  BindTmAbb(t, Some(typeof ctx t))
    | BindTmAbb(t,Some(tyT))    ->  if tyeqv ctx(typeof ctx t)tyT then BindTmAbb(t,Some(tyT))else error fi"TyAbbErr"
    | bind                      ->  bind  

let process_command ctx store = function 
    | Eval(fi,t)                ->
            pn();pr_tm ctx t;pn();
            pe"----------------------------------------------------";
            let tyT = typeof ctx t in
            pe"----------------   TYPE CHECKED !   ----------------";
            let t',store' = eval ctx store t in
            pe"----------------   EVAL FINISHED !  ----------------"; 
            pr_tm ctx t';pb 1 2;pr ": ";pr_ty ctx tyT;pn();pn(); ctx,store'
    | Bind(fi,x,bind)           ->  
            pr x;pr" ";prbindty ctx bind;pn();
            pe"----------------   BINDING...   --------------------";
            let bind' = checkbind fi ctx bind in 
            let bind'',store' = evalbind ctx store bind' in 
            pe"----------------   BIND DONE !  --------------------";
            pn();pn(); addbind ctx x bind'',store'


let rec process_commands ctx store = function 
    | []                        ->  ctx,store 
    | cmd::cmds                 ->  oobox0;
                                    let ctx',store' = process_command ctx store cmd in 
                                    Format.print_flush();
                                    process_commands ctx' store' cmds 



