open Support.Error
open Support.Pervasive
open Syntax
open Subtype 




(* ----------- TYPING --------------- *) 

let rec typeof ctx   t      = 
    let p str = pr str;pr": (∣Γ∣=";pi(ctxlen ctx);pr") ";pr_tm ctx t;pn() in 
    match t with
    | TmRef(fi,t)               ->  p"T-REF         "; TyRef(typeof ctx t)
    | TmDeref(fi,t)             ->  p"T-DEREF       "; (match simplifyty ctx (typeof ctx t) with 
        | TyRef(tyT)                    -> tyT
        | _                             -> error fi "argument of ! does not have a Ref Type" )
    | TmAssign(fi,t1,t2)        ->  p"T-ASSIGN      "; (match simplifyty ctx (typeof ctx t1) with
        | TyRef(tyT)                    ->  let tyT2 = typeof ctx t2 in  
                                            if subtype ctx tyT2 tyT && subtype ctx tyT tyT2 
                                                then TyUnit 
                                                else error fi":= cannot assign type"
        | _                             -> error fi "arguments of := does not have matching type" ) 
    | TmFix(fi,t1)              ->  p"T-FIX         "; (match typeof ctx t1 with 
        | TyArr(tyS,tyT)                ->  if subtype ctx tyT tyS 
                                                then tyT 
                                                else error fi"fix can take 'x' whose type: A -> A" 
        | _                             -> error fi"fix can only take x whose type is A -> A"  )
    | TmTag(fi,l,t1,(TyVariant(fTs)as tyT)) ->  
                                    p"T-VARIANT     "; let tyT1 = typeof ctx t1 in
                                    if tyeqv ctx tyT1(List.assoc l fTs)
                                        then tyT 
                                        else error fi "Variant Type Mismatch"
    | TmCase(fi,t1,cases)       ->  p"T-CASE        "; (match simplifyty ctx(typeof ctx t1) with 
        | TyVariant(fTs)                ->  let findTypeInVariant (li,(xi,ti))  =   
                                                try List.assoc li fTs
                                                with Not_found -> error fi ("label "^li^"not found") in 
                                            List.iter (fun c -> findTypeInVariant c;()) cases;
                                            let typeofcase (li,(xi,ti)) = 
                                                let tyTi =  findTypeInVariant (li,(xi,ti)) in 
                                                tyShift(-1)(typeof(addbind ctx xi(BindTmVar(tyTi)))ti) in 
                                            let caseTys  = List.map typeofcase cases in 
                                            let theCaseTy::rest = caseTys in
                                            let checkTypeIsEquiv2theCaseTy tyT =   
                                                if tyeqv ctx tyT theCaseTy then()else error fi "fldsTyErr" in 
                                            List.iter checkTypeIsEquiv2theCaseTy rest; theCaseTy   
            | _                         ->  error fi "Expected variant type")
    | TmFloat(fi,f)             ->  p"T-FLOAT       "; TyFloat
    | TmTimesfloat(fi,t1,t2)    ->  p"T-TIMESFLOAT  "; 
                                    if tyeqv ctx TyFloat(typeof ctx t1) && tyeqv ctx TyFloat(typeof ctx t2) 
                                        then TyFloat 
                                        else error fi"TypeMismatch: (*.) requires Floats"  
    | TmString(fi,_)            ->  p"T-STRING      ";  TyString
    | TmVar(fi,i,_)             ->  p"T-VAR         ";  getTypeFromContext fi ctx i  
    | TmLet(fi,x,t1,t2)         ->  p"T-LET         ";  tyShift(-1)(typeof(addbind ctx x(BindTmVar(typeof ctx t1)))t2)
    | TmAbs(fi,x,tyT1,t2)       ->  p"T-ABS         ";  
                                    let ctx'    = addbind ctx x (BindTmVar(tyT1)) in  
                                    let tyT2    = typeof ctx' t2 in                  
                                    TyArr(tyT1,tyShift(-1)tyT2)                     
    | TmApp(fi,t1,t2)           ->  p"T-APP         ";  
                                    let tyT1 = typeof ctx t1 in        
                                    let tyT2 = typeof ctx t2 in (match simplifyty ctx tyT1 with  
                | TyArr(tyT11,tyT12)    ->  if subtype ctx tyT2 tyT11 then tyT12 else error fi "type mismatch" 
                | _                     ->  error fi "arrow type expected" )
    | TmRecord(fi,flds)         ->  p"T-RCD         ";  TyRecord(List.map (fun(l,t)->(l,typeof ctx t)) flds)
    | TmProj(fi,t,l)            ->  p"T-PROJ        ";  
                                    (match typeof ctx t with 
        | TyRecord(tyflds)              -> (try List.assoc l tyflds with Not_found->error fi("label "^l^" not found")) 
        | _                             ->  error fi "Record Type Expected" ) 
    | TmUnit(fi)                ->  p"T-UNIT        ";  TyUnit
    | TmTrue(fi)                ->  p"T-TRUE        ";  TyBool
    | TmFalse(fi)               ->  p"T-FALSE       ";  TyBool
    | TmZero(fi)                ->  p"T-ZERO        ";  TyNat
    | TmSucc(fi,t)              ->  p"T-SUCC        ";
                                    if tyeqv ctx(typeof ctx t)TyNat then TyNat else error fi "succ expects 𝐍"  
    | TmPred(fi,t)              ->  p"T-PRED        ";
                                    if tyeqv ctx(typeof ctx t)TyNat then TyNat else error fi "succ expects 𝐍"  
    | TmIsZero(fi,t)            ->  p"T-ISZERO      ";
                                    if tyeqv ctx(typeof ctx t)TyNat then TyBool else error fi "iszero expects 𝐍"
    | TmIf(fi,t1,t2,t3)         ->  p"T-IF          ";
                                    if (tyeqv ctx)(typeof ctx t1) TyBool 
                                        then    join ctx (typeof ctx t2) (typeof ctx t3)
                                        else    error fi "if-condition expects a boolean" 
    | TmAscribe(fi,t,tyT)       ->  p"T-ASCRIBE     ";
                                    if (subtype ctx)(typeof ctx t)tyT then tyT else error fi "Type Ascription Mismatch"       



(* CAUTION typeof is used unneededly *)
(* -------------------------------------------------- *) 
(* Bind Print *)    
let prbindty ctx = function
    | BindName                  -> ()
    | BindTmVar(tyT)            -> pr": "; pr_ty ctx tyT 
    | BindTyVar                 -> () 
    | BindTyAbb(tyT)            -> pr"= "; pr_ty ctx tyT
    | BindTmAbb(t,Some(tyT))    -> pr"= "; pr_tm ctx t
    | BindTmAbb(t,None)         -> pr"= "; pr_tm ctx t 

